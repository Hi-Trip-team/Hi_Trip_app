import SwiftUI

// MARK: - AppRouter
/// 앱 전체 화면 전환 관리
///
/// SwiftUI의 @Published와 RootView의 switch 문을 결합하여
/// 프로그래밍 방식으로 화면을 전환합니다.
///
/// 화면 흐름:
/// splash → (토큰 확인) → login 또는 home
///                         login → signUp → login (가입 완료 후)
///                         login → home (로그인 성공)
///
/// ObservableObject 채택:
/// - @StateObject로 HiTripApp에서 생성
/// - @EnvironmentObject로 모든 하위 View에 전달

final class AppRouter: ObservableObject {

    enum Screen: Equatable {
        case splash
        case login
        case signUp
        case home
    }

    @Published var currentScreen: Screen = .splash

    func navigateToLogin() {
        currentScreen = .login
    }

    func navigateToSignUp() {
        currentScreen = .signUp
    }

    func navigateToHome() {
        currentScreen = .home
    }

    /// 스플래시에서 호출 — Keychain 토큰 유무로 분기
    func handleAutoLogin(isLoggedIn: Bool) {
        currentScreen = isLoggedIn ? .home : .login
    }
}
