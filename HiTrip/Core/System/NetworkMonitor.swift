import Foundation
import Network

// MARK: - NetworkMonitor
/// 연결 상태 감시
///
/// - isConnected: 오프라인 배너 표시
/// - 재연결 시 .hiTripNetworkReconnected 알림 — 실패 화면 자동 재시도, 채팅 전송 대기 큐 재전송

final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true

    /// 끊겼다가 다시 붙었을 때만 부릅니다
    var onReconnect: (() -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "hitrip.network.monitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            DispatchQueue.main.async {
                let wasOffline = !self.isConnected
                self.isConnected = connected
                if connected && wasOffline {
                    self.onReconnect?()
                    NotificationCenter.default.post(name: .hiTripNetworkReconnected, object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }
}

extension Notification.Name {
    /// 인터넷이 끊겼다가 다시 연결됨
    static let hiTripNetworkReconnected = Notification.Name("hiTripNetworkReconnected")
}
