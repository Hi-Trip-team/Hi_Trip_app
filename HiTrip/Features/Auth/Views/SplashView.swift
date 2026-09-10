import SwiftUI
import RxSwift

// MARK: - SplashView
/// 스플래시 화면
///
/// 1. 로고를 최소 1.5초 보여줍니다.
/// 2. 네트워크가 없으면 「네트워크 연결을 확인해주세요」 + [재시도]
/// 3. 최소 지원 버전 미달이면 「업데이트가 필요합니다」 팝업 (닫기 불가)
/// 4. 자동 로그인이 켜져 있고 세션이 유효하면 역할별 홈(약관 필요 시 약관), 아니면 로그인

struct SplashView: View {

    @EnvironmentObject var router: AppRouter

    @State private var isAnimating = false
    @State private var phase: Phase = .launching
    @State private var attempt = 0
    @State private var disposeBag = DisposeBag()

    private let loginUseCase = AppDIContainer.shared.makeLoginUseCase()
    private static let minimumDisplay: TimeInterval = 1.5

    enum Phase { case launching, offline, updateRequired }

    var body: some View {
        ZStack {
            HiTripColor.splashBackground
                .ignoresSafeArea()

            Text("Hi Trip")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)

            if phase == .offline {
                offlineSection
            }

            if phase == .updateRequired {
                updatePopup
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { isAnimating = true }
        }
        .task(id: attempt) { await start() }
    }

    // MARK: - 흐름

    private func start() async {
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
        route()
    }

    private func waitMinimumDisplay(since start: Date) async {
        let remaining = Self.minimumDisplay - Date().timeIntervalSince(start)
        guard remaining > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
    }

    private func route() {
        let keychain = KeychainManager.shared

        if APIEnvironment.current.useMock {
            keychain.clearAll()
            router.navigateToLogin()
            return
        }

        // 자동 로그인을 끄고 로그인했던 경우 — 이번 실행에서는 세션을 버립니다.
        guard keychain.isLoggedIn, keychain.isAutoLoginEnabled else {
            clearSavedSession()
            router.navigateToLogin()
            return
        }

        loginUseCase.validateSession()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { state in
                    router.proceedAfterLogin(as: state.userType, requiresAgreement: state.requiresAgreement)
                },
                onFailure: { error in
                    switch ErrorHandler.classify(error) {
                    case .noConnection, .timeout, .networkFailure:
                        phase = .offline
                    default:
                        // 만료(여행 종료+3일 경과 후 서버 파기 포함) → 로그인 화면
                        clearSavedSession()
                        router.navigateToLogin()
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    private func clearSavedSession() {
        KeychainManager.shared.clearAll()
        NetworkService.clearSession()
    }

    // MARK: - 네트워크 미연결

    private var offlineSection: some View {
        VStack(spacing: HiTripSpacing.lg) {
            Spacer()
            Text("네트워크 연결을 확인해주세요")
                .font(HiTripFont.bodyLBold)
                .foregroundColor(.white)
            Button {
                phase = .launching
                attempt += 1
            } label: {
                Text("재시도")
                    .font(HiTripFont.bodyBold)
                    .foregroundColor(HiTripColor.primary800)
                    .frame(width: 120, height: 44)
                    .background(Color.white)
                    .cornerRadius(HiTripRadius.card)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 80)
    }

    // MARK: - 강제 업데이트 (닫기 없음)

    private var updatePopup: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: HiTripSpacing.md) {
                Text("업데이트가 필요합니다")
                    .font(HiTripFont.title3)
                    .foregroundColor(HiTripColor.textBlack)
                Text("안정적인 서비스 이용을 위해\n최신 버전으로 업데이트해주세요.")
                    .font(HiTripFont.body)
                    .foregroundColor(HiTripColor.gray500)
                    .multilineTextAlignment(.center)
                Button {
                    if let url = AppLinks.appStore { UIApplication.shared.open(url) }
                } label: {
                    Text("업데이트")
                        .font(HiTripFont.bodyLBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(HiTripColor.primary800)
                        .cornerRadius(HiTripRadius.card)
                }
                .buttonStyle(.plain)
                .padding(.top, HiTripSpacing.sm)
            }
            .padding(HiTripSpacing.xl)
            .background(Color.white)
            .cornerRadius(HiTripRadius.lg)
            .padding(.horizontal, 40)
        }
    }
}
