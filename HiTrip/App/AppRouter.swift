import SwiftUI
import RxSwift
import CoreLocation

// MARK: - AppRouter
/// 앱 전체 화면 전환 관리
///
/// 화면 흐름:
/// splash ─(유효한 자동로그인 세션)→ (약관 필요 시 agreement) → home
///        └(없음)→ login ─(성공)→ (약관 필요 시 agreement) → home
///
/// 회원가입은 없습니다. 계정은 SaaS에서만 발급합니다.

final class AppRouter: ObservableObject {

    enum Screen: Equatable {
        case splash
        case login
        case agreement        // 약관/권한 동의
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
            guard self.currentScreen == .home || self.currentScreen == .agreement else { return }
            KeychainManager.shared.clearAll()
            NetworkService.clearSession()
            self.currentScreen = .login
        }
    }

    deinit {
        if let expiryObserver { NotificationCenter.default.removeObserver(expiryObserver) }
    }

    func navigateToLogin() {
        currentScreen = .login
    }

    /// 로그인/자동로그인 성공 후 분기
    ///
    /// 관광객은 **계정 기준**입니다. 서버가 `requires_agreement=true`를 주면 동의 화면을 보여줍니다.
    /// 기기 기준으로 판단하면 같은 기기에서 다른 계정으로 로그인했을 때 동의를 건너뛰어,
    /// 그 계정의 동의 이력이 서버에 남지 않습니다.
    ///
    /// 안내사는 아직 동의 상태를 내려주지 않아 기기 기록으로 판단합니다.
    func proceedAfterLogin(as type: UserType, requiresAgreement serverRequiresAgreement: Bool) {
        userType = type

        if type == .tourist {
            if serverRequiresAgreement {
                currentScreen = .agreement
            } else {
                navigateToHomeAs(type)
            }
            return
        }

        guard AgreementRecordStore.hasAgreedOnDevice else {
            currentScreen = .agreement
            return
        }
        navigateToHomeAs(type)
    }

    func navigateToHomeAs(_ type: UserType) {
        userType = type
        currentScreen = .home
    }
}
