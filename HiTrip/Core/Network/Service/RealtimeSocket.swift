import Foundation
import RxSwift

// MARK: - RealtimeSocket
/// 서버 WebSocket 연결 — 채팅·공지 실시간 수신
///
/// - 채팅: /ws/v1/chat/{room_id}/   (관광객·안내사)
/// - 공지: /ws/v1/notices/          (관광객 전용 — 안내사 세션은 403)
///
/// 인증은 REST와 같습니다. 관광객은 `?token=` 쿼리, 안내사는 세션 쿠키가 붙습니다.
/// 구독하는 동안 연결을 유지하고, 끊기면 1초 → 2초 → … 최대 30초 간격으로 다시 붙습니다.
/// 인증 실패(4xxx 종료 코드)면 다시 붙지 않습니다.
///
/// 서버는 모르는 action 문자열을 받으면 연결을 닫습니다(UNKNOWN_ACTION).
/// 그래서 연결 유지는 JSON이 아니라 WebSocket 프로토콜 ping으로 합니다.

enum RealtimeSocket {

    /// 구독하면 연결하고, 해제하면 닫습니다. 이벤트는 백그라운드 큐에서 옵니다.
    static func events(path: String) -> Observable<[String: Any]> {
        Observable.create { observer in
            let connection = Connection(path: path) { observer.onNext($0) }
            connection.start()
            return Disposables.create { connection.stop() }
        }
    }

    /// REST 기본 주소에서 스킴만 바꿉니다 (http → ws, https → wss)
    static func url(for path: String) -> URL? {
        var base = APIEnvironment.current.baseURL
        if base.hasPrefix("https://") {
            base = "wss://" + base.dropFirst("https://".count)
        } else if base.hasPrefix("http://") {
            base = "ws://" + base.dropFirst("http://".count)
        }
        var components = URLComponents(string: base + path)
        if let token = KeychainManager.shared.getToken() {
            components?.queryItems = [URLQueryItem(name: "token", value: token)]
        }
        return components?.url
    }
}

// MARK: - Connection

private final class Connection {

    private let path: String
    private let onEvent: ([String: Any]) -> Void
    private let queue = DispatchQueue(label: "com.hitrip.realtime")
    private let session = URLSession(configuration: .default)

    private var task: URLSessionWebSocketTask?
    private var pingTimer: DispatchSourceTimer?
    private var retryDelay: TimeInterval = 1
    private var isStopped = false

    private static let pingInterval: TimeInterval = 25
    private static let maxRetryDelay: TimeInterval = 30

    init(path: String, onEvent: @escaping ([String: Any]) -> Void) {
        self.path = path
        self.onEvent = onEvent
    }

    func start() {
        queue.async { self.connect() }
    }

    func stop() {
        queue.async {
            self.isStopped = true
            self.pingTimer?.cancel()
            self.pingTimer = nil
            self.task?.cancel(with: .goingAway, reason: nil)
            self.task = nil
            self.session.invalidateAndCancel()
        }
    }

    // MARK: - 연결

    private func connect() {
        guard !isStopped, let url = RealtimeSocket.url(for: path) else { return }

        var request = URLRequest(url: url)
        let base = APIEnvironment.current.baseURL
        request.setValue(base, forHTTPHeaderField: "Origin")
        // 안내사 세션 쿠키 — REST 로그인 때 공유 쿠키 저장소에 들어간 값을 그대로 씁니다
        if let httpURL = URL(string: base),
           let cookies = HTTPCookieStorage.shared.cookies(for: httpURL), !cookies.isEmpty {
            HTTPCookie.requestHeaderFields(with: cookies).forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }
        }

        let task = session.webSocketTask(with: request)
        self.task = task
        task.resume()
        receive(on: task)
        startPing(on: task)
    }

    private func receive(on task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }
            self.queue.async {
                guard task === self.task, !self.isStopped else { return }
                switch result {
                case .success(let message):
                    self.retryDelay = 1
                    if let json = Self.json(from: message) { self.onEvent(json) }
                    self.receive(on: task)
                case .failure:
                    self.reconnect(after: task)
                }
            }
        }
    }

    private func reconnect(after task: URLSessionWebSocketTask) {
        pingTimer?.cancel()
        pingTimer = nil
        self.task = nil

        // 4000번대 종료 코드 = 서버가 인증·권한으로 거절 — 다시 붙어도 같습니다
        if (4000..<5000).contains(task.closeCode.rawValue) { return }

        let delay = retryDelay
        retryDelay = min(retryDelay * 2, Self.maxRetryDelay)
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in self?.connect() }
    }

    private func startPing(on task: URLSessionWebSocketTask) {
        pingTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.pingInterval, repeating: Self.pingInterval)
        timer.setEventHandler { [weak task] in
            // 실패하면 receive 쪽이 끊김을 받아 재연결합니다
            task?.sendPing { _ in }
        }
        timer.resume()
        pingTimer = timer
    }

    private static func json(from message: URLSessionWebSocketTask.Message) -> [String: Any]? {
        let data: Data
        switch message {
        case .string(let text): data = Data(text.utf8)
        case .data(let raw):    data = raw
        @unknown default:       return nil
        }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
