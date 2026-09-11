import SwiftUI

// MARK: - RootView
/// 앱 최상위 View — AppRouter 상태에 따라 화면 분기
///
/// - router.currentScreen 값을 관찰하여 해당 화면 렌더링
/// - 스플래시를 뺀 모든 화면 상단에 오프라인 배너(OfflineBanner)
/// - 화면 전환 시 0.3초 easeInOut 애니메이션

struct RootView: View {

    @EnvironmentObject var router: AppRouter
    @ObservedObject private var network = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 0) {
            if router.currentScreen != .splash {
                OfflineBanner()
            }

            Group {
                switch router.currentScreen {
                case .splash:
                    SplashView()
                case .login:
                    LoginView()
                case .agreement:
                    AgreementView(userType: router.userType)
                case .home:
                    HomeView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.currentScreen)
        .animation(.easeInOut(duration: 0.25), value: network.isConnected)
    }
}
