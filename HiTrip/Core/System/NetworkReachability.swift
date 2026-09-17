import Foundation
import Network

// MARK: - NetworkReachability
/// 기기의 네트워크 연결 여부를 한 번 확인합니다 (스플래시용)

enum NetworkReachability {

    static func isConnected() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: DispatchQueue(label: "com.hitrip.reachability"))
        }
    }
}
