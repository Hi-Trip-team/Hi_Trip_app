import Foundation
import RxSwift

// MARK: - LoginViewModel
/// 로그인 화면 상태
///
/// - 버튼: ID·PW가 모두 있어야 활성(파란색). 비어 있어도 탭은 받아 어느 칸이 비었는지 알려줍니다.
/// - 불일치: PW 칸 빨간 테두리 + 버튼 위 "(n/5)". 5회째에 잠금 문구 + 버튼 비활성.
/// - 잠금은 서버(429)가 기준이고, 남은 시간은 1초마다 줄여 보여줍니다.
/// - 아이디·비밀번호를 고치기 시작하면 빨간 표시는 바로 지웁니다(잠금 문구는 유지).

final class LoginViewModel: ObservableObject {

    // MARK: - 입력

    @Published var id: String = "" {
        didSet {
            guard id != oldValue else { return }
            clearInputErrors()
            refreshLockState()
        }
    }
    @Published var password: String = "" {
        didSet { if password != oldValue { clearInputErrors() } }
    }
    /// 자동 로그인 — 기본 체크
    @Published var isAutoLogin: Bool = true

    // MARK: - 출력

    @Published private(set) var isLoading = false
    @Published private(set) var idError: String?
    @Published private(set) var passwordError: String?
    /// 불일치 등 버튼 위에 뜨는 문구
    @Published private(set) var credentialError: String?
    /// 잠금 남은 초 (nil이면 잠금 아님)
    @Published private(set) var lockRemaining: Int?
    @Published var showConcurrentAlert = false
    @Published private(set) var result: LoginResponse?

    var isFormFilled: Bool { !id.trimmed.isEmpty && !password.isEmpty }
    var isLocked: Bool { lockRemaining != nil }
    var isPasswordHighlighted: Bool { passwordError != nil || credentialError != nil }

    /// 버튼 위 빨간 문구 — 잠금이 우선
    var bannerMessage: String? {
        if let remaining = lockRemaining {
            let minutes = max(1, lockTotalSeconds / 60)
            let clock = String(format: "%02d:%02d", remaining / 60, remaining % 60)
            return "\(LoginAttemptStore.maxAttempts)회 실패로 \(minutes)분간 잠금되었습니다 (남은 시간 \(clock))"
        }
        return credentialError
    }

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCase
    private let disposeBag = DisposeBag()
    private var lockTimer: Timer?
    private var lockTotalSeconds = LoginAttemptStore.defaultLockSeconds

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    deinit { lockTimer?.invalidate() }

    // MARK: - 로그인

    /// - Parameter force: 동시 로그인 안내에서 [확인]을 눌러 기존 기기를 끊고 들어갈 때
    func login(force: Bool = false) {
        guard !isLoading, !isLocked else { return }

        let username = id.trimmed
        idError = username.isEmpty ? LoginError.emptyId.errorDescription : nil
        passwordError = (!username.isEmpty && password.isEmpty) ? LoginError.emptyPassword.errorDescription : nil
        guard idError == nil, passwordError == nil else { return }

        credentialError = nil
        isLoading = true

        loginUseCase.execute(id: username, password: password, force: force)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] response in
                    guard let self else { return }
                    self.isLoading = false
                    LoginAttemptStore.reset(for: username)
                    KeychainManager.shared.isAutoLoginEnabled = self.isAutoLogin
                    self.result = response
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.handle(error, username: username)
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 실패 처리

    private func handle(_ error: Error, username: String) {
        let max = LoginAttemptStore.maxAttempts

        switch error as? LoginError {
        case .invalidCredentials(let remaining)?:
            let count: Int
            if let remaining {
                count = max - remaining
                LoginAttemptStore.setFailures(count, for: username)
            } else {
                count = LoginAttemptStore.recordFailure(for: username)
            }
            if count >= max {
                startLock(for: username, seconds: LoginAttemptStore.defaultLockSeconds)
            } else {
                credentialError = "아이디 또는 비밀번호가 일치하지 않습니다. (\(count)/\(max))"
            }

        case .locked(let seconds)?:
            startLock(for: username, seconds: seconds)

        case .concurrentSession?:
            showConcurrentAlert = true

        default:
            credentialError = error.localizedDescription
        }
    }

    private func clearInputErrors() {
        idError = nil
        passwordError = nil
        credentialError = nil
    }

    // MARK: - 잠금 타이머

    private func startLock(for username: String, seconds: Int) {
        LoginAttemptStore.lock(username, seconds: seconds)
        lockTotalSeconds = seconds
        credentialError = nil
        refreshLockState()
    }

    /// 입력한 아이디가 잠겨 있으면 타이머를 돌리고, 아니면 멈춥니다.
    private func refreshLockState() {
        let username = id.trimmed
        guard !username.isEmpty, let until = LoginAttemptStore.lockedUntil(for: username) else {
            stopLockTimer()
            return
        }
        updateRemaining(until: until, username: username)
        guard lockTimer == nil else { return }
        lockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.updateRemaining(until: until, username: username)
        }
    }

    private func updateRemaining(until: Date, username: String) {
        let remaining = Int(ceil(until.timeIntervalSinceNow))
        if remaining <= 0 {
            // 잠금 해제 → 실패 횟수도 초기화
            LoginAttemptStore.reset(for: username)
            stopLockTimer()
        } else {
            lockRemaining = remaining
        }
    }

    private func stopLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
        lockRemaining = nil
    }
}
