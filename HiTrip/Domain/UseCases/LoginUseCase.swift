import Foundation
import RxSwift

// MARK: - LoginUseCase
/// 로그인 비즈니스 로직 담당
///
/// Clean Architecture에서의 역할:
/// - ViewModel과 Repository 사이에서 비즈니스 규칙을 실행
/// - 입력값 검증(빈 값 체크) → Repository에 API 호출 위임
///
/// 아이디 길이·형식은 앱에서 판단하지 않습니다.
/// 계정은 SaaS에서 발급되므로 규칙이 바뀌어도 서버 응답만 따릅니다.

final class LoginUseCase {

    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 로그인 실행

    func execute(id: String, password: String, force: Bool = false) -> Single<LoginResponse> {
        guard !id.trimmed.isEmpty else { return .error(LoginError.emptyId) }
        guard !password.isEmpty else { return .error(LoginError.emptyPassword) }
        return repository.login(request: LoginRequest(id: id.trimmed, password: password, force: force))
    }

    // MARK: - 자동 로그인

    func validateSession() -> Single<SessionState> {
        repository.validateSession()
    }

    // MARK: - 최초 비밀번호 변경

    func changeInitialPassword(username: String, currentPassword: String, newPassword: String) -> Single<Void> {
        repository.changeInitialPassword(username: username.trimmed, currentPassword: currentPassword, newPassword: newPassword)
    }

    // MARK: - 로그아웃

    func logout() {
        repository.logout()
    }
}

// MARK: - LoginError
/// 로그인 화면이 구분해서 보여줘야 하는 실패 유형
enum LoginError: LocalizedError, Equatable {
    /// 아이디 미입력
    case emptyId
    /// 비밀번호 미입력
    case emptyPassword
    /// 아이디·비밀번호 불일치 — 서버가 남은 횟수를 주면 함께 전달
    case invalidCredentials(remaining: Int?)
    /// 연속 실패로 잠김 — 남은 초
    case locked(seconds: Int)
    /// 같은 아이디로 접속 중인 기기가 있음
    case concurrentSession
    /// 발급받은 임시 비밀번호 — 새 비밀번호로 바꿔야 로그인됩니다
    case passwordChangeRequired
    /// 네트워크 연결 없음 / 서버 응답 없음
    case network
    /// 기타 서버 에러
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyId:            return "아이디를 입력해주세요."
        case .emptyPassword:      return "비밀번호를 입력해주세요."
        case .invalidCredentials: return "아이디 또는 비밀번호가 일치하지 않습니다."
        case .locked:             return "로그인이 일시적으로 잠겼습니다."
        case .concurrentSession:  return "동일한 아이디로 접속중인 기기가 있습니다."
        case .passwordChangeRequired: return "처음 로그인하셨어요. 비밀번호를 변경해주세요."
        case .network:            return "네트워크 연결을 확인해주세요."
        case .serverError(let m): return m
        }
    }
}

// MARK: - PasswordChangeError
/// 최초 비밀번호 변경 실패 — 화면에 그대로 보여줄 문구를 담습니다
enum PasswordChangeError: LocalizedError {
    case rejected(String)

    var errorDescription: String? {
        switch self {
        case .rejected(let message): return message
        }
    }
}
