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
    /// 약관·권한 화면은 이 기기에서 처음일 때만 보여줍니다.
    /// 기기는 이미 동의했는데 관광객 서버 기록만 비어 있으면(다른 계정·새 여행)
    /// 화면 없이 기기에 기록된 동의 내용으로 서버에 저장합니다.
    func proceedAfterLogin(as type: UserType, requiresAgreement serverRequiresAgreement: Bool) {
        userType = type
        guard AgreementRecordStore.hasAgreedOnDevice else {
            currentScreen = .agreement
            return
        }
        if type == .tourist, serverRequiresAgreement {
            syncTouristAgreement()
        }
        navigateToHomeAs(type)
    }

    private let disposeBag = DisposeBag()

    private func syncTouristAgreement() {
        let status = CLLocationManager().authorizationStatus
        let locationGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        AppDIContainer.shared.makeTravelerRepository()
            .updateAgreements(
                termsAccepted: true,
                locationAccepted: locationGranted,
                notificationAccepted: AgreementRecordStore.optionalAccepted
            )
            .subscribe(onFailure: { print("⚠️ [Agreement] 서버 동의 동기화 실패: \($0.localizedDescription)") })
            .disposed(by: disposeBag)
    }

    func navigateToHomeAs(_ type: UserType) {
        userType = type
        // 관광객 홈 데이터는 로그인 직후 한 번 미리 받아둡니다 (역할 확인은 TripDataStore가 함)
        TripDataStore.shared.reload()
        currentScreen = .home
    }
}
