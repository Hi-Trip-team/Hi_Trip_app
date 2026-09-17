import Foundation
import RxSwift

// MARK: - LoginViewModel
/// 로그인 화면 상태
///
/// - 버튼: ID·PW가 모두 있어야 활성(파란색). 비어 있어도 탭은 받아 어느 칸이 비었는지 알려줍니다.
/// - 실패 횟수·잠금·동시 로그인은 앱에서 막지 않습니다. 서버 판단(401·429·409)을 문구로만 보여줍니다.
///   기기에 실패 기록을 남기면 테스트 계정을 여러 번 쓸 때 앱이 먼저 막아 버리기 때문입니다.
/// - 아이디·비밀번호를 고치기 시작하면 빨간 표시는 바로 지웁니다.

final class LoginViewModel: ObservableObject {

    // MARK: - 입력

    @Published var id: String = "" {
        didSet { if id != oldValue { clearInputErrors() } }
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
    /// 최초 비밀번호 변경 화면 표시
    @Published var showPasswordChange = false
    @Published private(set) var isChangingPassword = false
    @Published private(set) var passwordChangeError: String?
    @Published private(set) var result: LoginResponse?

    var isFormFilled: Bool { !id.trimmed.isEmpty && !password.isEmpty }
    var isPasswordHighlighted: Bool { passwordError != nil || credentialError != nil }

    /// 버튼 위 빨간 문구
    var bannerMessage: String? { credentialError }

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCase
    private let disposeBag = DisposeBag()

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    // MARK: - 로그인

    func login() {
        guard !isLoading else { return }

        let username = id.trimmed
        idError = username.isEmpty ? LoginError.emptyId.errorDescription : nil
        passwordError = (!username.isEmpty && password.isEmpty) ? LoginError.emptyPassword.errorDescription : nil
        guard idError == nil, passwordError == nil else { return }

        credentialError = nil
        isLoading = true

        loginUseCase.execute(id: username, password: password, force: false)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] response in
                    guard let self else { return }
                    self.isLoading = false
                    KeychainManager.shared.isAutoLoginEnabled = self.isAutoLogin
                    self.result = response
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.handle(error)
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 실패 처리

    /// 서버가 알려준 만큼만 보여줍니다 — 앱이 따로 세거나 잠그지 않습니다
    private func handle(_ error: Error) {
        switch error as? LoginError {
        case .invalidCredentials(let remaining)?:
            let base = "아이디 또는 비밀번호가 일치하지 않습니다."
            credentialError = remaining.map { "\(base) (남은 시도 \($0)회)" } ?? base

        case .locked(let seconds)?:
            let minutes = Int(ceil(Double(seconds) / 60))
            credentialError = minutes > 0
                ? "로그인 시도가 많아 잠시 막혔습니다. \(minutes)분 뒤 다시 시도해주세요."
                : "로그인 시도가 많아 잠시 막혔습니다. 잠시 후 다시 시도해주세요."

        case .passwordChangeRequired?:
            passwordChangeError = nil
            showPasswordChange = true

        default:
            credentialError = error.localizedDescription
        }
    }

    // MARK: - 최초 비밀번호 변경

    /// 새 비밀번호로 바꾼 뒤 그 비밀번호로 바로 다시 로그인합니다
    func changeInitialPassword(to newPassword: String) {
        guard !isChangingPassword else { return }
        isChangingPassword = true
        passwordChangeError = nil

        loginUseCase.changeInitialPassword(username: id, currentPassword: password, newPassword: newPassword)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    guard let self else { return }
                    self.isChangingPassword = false
                    self.showPasswordChange = false
                    self.password = newPassword
                    self.login()
                },
                onFailure: { [weak self] error in
                    self?.isChangingPassword = false
                    self?.passwordChangeError = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    func cancelPasswordChange() {
        showPasswordChange = false
        password = ""
    }

    private func clearInputErrors() {
        idError = nil
        passwordError = nil
        credentialError = nil
    }
}
