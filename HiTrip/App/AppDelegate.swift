import UIKit

// MARK: - AppDelegate
/// UIKit 생명주기 관리
///
/// SwiftUI 앱에서 AppDelegate가 필요한 이유:
/// - 푸시 알림 토큰 등록 (Phase 6)
/// - 딥링크 처리
/// - 서드파티 SDK 초기화 (KakaoMaps 등)
///
/// @UIApplicationDelegateAdaptor로 HiTripApp에서 연결

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // TODO: Phase 4 — KakaoMaps SDK 초기화
        // TODO: Phase 6 — Push 알림 권한 요청
        return true
    }

    // MARK: - Push Token (Phase 6에서 구현)

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken
            .map { String(format: "%02.2hhx", $0) }
            .joined()
        print("[Push] Token: \(token)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[Push] Failed: \(error.localizedDescription)")
    }
}
