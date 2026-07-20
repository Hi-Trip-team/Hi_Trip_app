import SwiftUI
import SwiftData

// MARK: - HiTripApp
/// 앱 진입점 (@main)
///
/// 구조:
/// - @UIApplicationDelegateAdaptor: UIKit AppDelegate 연결 (Push 등)
/// - @StateObject router: 앱 전체에서 공유할 화면 전환 매니저
/// - .modelContainer: SwiftData (PersonalTodo 로컬 저장)

@main
struct HiTripApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
        }
        .modelContainer(for: PersonalTodo.self)
    }
}
