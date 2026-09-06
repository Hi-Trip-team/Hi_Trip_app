import Foundation
import Network

// MARK: - NetworkMonitor
/// 연결 상태 감시 — 오프라인 전송 대기 큐를 다시 굴리는 신호로 씁니다.

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
                if connected && wasOffline { self.onReconnect?() }
            }
        }
        monitor.start(queue: queue)
    }
}
