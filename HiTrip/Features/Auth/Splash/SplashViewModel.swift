import Foundation
import RxSwift

// MARK: - SplashViewModel
/// 스플래시 판단 로직
///
/// 1. 로고를 최소 1.5초 보여줍니다.
/// 2. 네트워크가 없으면 offline
/// 3. 최소 지원 버전 미달이면 updateRequired (닫기 불가)
/// 4. 자동 로그인이 켜져 있고 세션이 유효하면 역할별 홈(약관 필요 시 약관), 아니면 로그인

@MainActor
final class SplashViewModel: ObservableObject {

    enum Phase { case launching, offline, updateRequired }

    enum Route: Equatable {
        case login
        case home(UserType, requiresAgreement: Bool)
    }

    @Published private(set) var phase: Phase = .launching
    /// 결정된 이동 — View가 받아서 라우터에 넘깁니다
    @Published private(set) var route: Route?

    private let loginUseCase: LoginUseCase
    private let disposeBag = DisposeBag()
    private static let minimumDisplay: TimeInterval = 1.5

    init(loginUseCase: LoginUseCase = AppDIContainer.shared.makeLoginUseCase()) {
        self.loginUseCase = loginUseCase
    }

    func start() async {
        let startedAt = Date()

        guard await NetworkReachability.isConnected() else {
            await waitMinimumDisplay(since: startedAt)
            phase = .offline
            return
        }
        if await AppVersionChecker.isUpdateRequired() {
            phase = .updateRequired
            return
        }
        await waitMinimumDisplay(since: startedAt)
        decideRoute()
    }

    func retry() {
        phase = .launching
    }

    // MARK: - Private

    private func waitMinimumDisplay(since start: Date) async {
        let remaining = Self.minimumDisplay - Date().timeIntervalSince(start)
        guard remaining > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
    }

    private func decideRoute() {
        let keychain = KeychainManager.shared

        if APIEnvironment.current.useMock {
            keychain.clearAll()
            route = .login
            return
        }

        // 자동 로그인을 끄고 로그인했던 경우 — 이번 실행에서는 세션을 버립니다.
        guard keychain.isLoggedIn, keychain.isAutoLoginEnabled else {
            clearSavedSession()
            route = .login
            return
        }

        loginUseCase.validateSession()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] state in
                    self?.route = .home(state.userType, requiresAgreement: state.requiresAgreement)
                },
                onFailure: { [weak self] error in
                    guard let self else { return }
                    switch ErrorHandler.classify(error) {
                    case .noConnection, .timeout, .networkFailure:
                        self.phase = .offline
                    default:
                        // 만료(여행 종료+3일 경과 후 서버 파기 포함) → 로그인 화면
                        self.clearSavedSession()
                        self.route = .login
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    private func clearSavedSession() {
        KeychainManager.shared.clearAll()
        NetworkService.clearSession()
    }
}
