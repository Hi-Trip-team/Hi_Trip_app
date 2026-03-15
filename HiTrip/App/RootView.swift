import SwiftUI

// MARK: - RootView
/// 앱 최상위 View — AppRouter 상태에 따라 화면 분기
///
/// 역할:
/// - router.currentScreen 값을 관찰하여 해당 화면 렌더링
/// - 화면 전환 시 0.3초 easeInOut 애니메이션 적용
///
/// DI 흐름:
/// - LoginView: AppDIContainer에서 LoginViewModel 생성하여 주입
/// - SignUpFlowView: AppDIContainer에서 SignUpViewModel 생성하여 주입
/// - HomeView, SplashView: 별도 주입 불필요 (EnvironmentObject로 router 사용)

struct RootView: View {

    @EnvironmentObject var router: AppRouter

    var body: some View {
        Group {
            switch router.currentScreen {
            case .splash:
                SplashView()

            case .login:
                LoginView(
                    viewModel: AppDIContainer.shared.makeLoginViewModel()
                )

            case .signUp:
                SignUpFlowView(
                    viewModel: AppDIContainer.shared.makeSignUpViewModel()
                )

            case .home:
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.currentScreen)
    }
}
