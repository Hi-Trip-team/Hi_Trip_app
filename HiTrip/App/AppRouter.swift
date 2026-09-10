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
        case inviteLogin      // 초대코드 로그인 플로우
        case agreement        // 약관 동의 (requiresAgreement == true)
        case home
    }

    @Published var currentScreen: Screen = .splash
    @Published var userType: UserType = .guide

    private var expiryObserver: NSObjectProtocol?

    init() {
        // 세션·토큰이 끊기면 로그인 화면으로 되돌립니다.
        // 이 처리가 없으면 홈에서 403만 반복하고 다시 로그인할 방법이 없습니다.
        expiryObserver = NotificationCenter.default.addObserver(
            forName: .hiTripTokenExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            guard self.currentScreen == .home else { return }
            KeychainManager.shared.clearAll()
            self.currentScreen = .login
        }
    }

    deinit {
        if let expiryObserver { NotificationCenter.default.removeObserver(expiryObserver) }
    }

    func navigateToLogin() {
        currentScreen = .login
    }

    func navigateToSignUp() {
        currentScreen = .signUp
    }

    func navigateToInviteLogin() {
        currentScreen = .inviteLogin
    }

    func navigateToAgreement() {
        currentScreen = .agreement
    }

    func navigateToHome() {
        currentScreen = .home
    }

    func navigateToHomeAs(_ type: UserType) {
        userType = type
        currentScreen = .home
    }

    /// 스플래시에서 호출 — Keychain 토큰 유무로 분기
    func handleAutoLogin(isLoggedIn: Bool) {
        currentScreen = isLoggedIn ? .home : .login
    }
}
