import SwiftUI

// MARK: - HiTripApp
/// 앱 진입점 (@main)
///
/// 구조:
/// - @UIApplicationDelegateAdaptor: UIKit AppDelegate 연결 (Push 등)
/// - @StateObject router: 앱 전체에서 공유할 화면 전환 매니저
/// - .environmentObject(router): 모든 하위 View에서 접근 가능

@main
struct HiTripApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
        }
    }
}
