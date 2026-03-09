import Foundation
import RxSwift

// MARK: - LoginUseCase
/// 로그인 비즈니스 로직 담당
///
/// Clean Architecture에서의 역할:
/// - ViewModel과 Repository 사이에서 비즈니스 규칙을 실행
/// - 입력값 검증(빈 값 체크) → Repository에 API 호출 위임
///
/// 의존성:
/// - AuthRepositoryProtocol (Protocol)에만 의존
/// - 실제 구현체(AuthRepository)를 모름 → 테스트 시 Mock 주입 가능
///
/// 면접 포인트:
/// "UseCase를 왜 따로 만드셨나요? ViewModel에서 바로 Repository를 호출하면 안 되나요?"
/// → "비즈니스 로직을 ViewModel에서 분리하면:
///    1) ViewModel은 UI 바인딩에만 집중
///    2) UseCase 단위로 독립적인 테스트 가능
///    3) 같은 UseCase를 여러 ViewModel에서 재사용 가능"

final class LoginUseCase {

    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 로그인 실행

    /// 로그인 실행: 입력 검증 → API 호출 → UserInfo 반환
    ///
    /// 동작 흐름:
    /// 1. ID 빈 값 검증 (.trimmed로 공백만 있는 경우도 체크)
    /// 2. Password 빈 값 검증
    /// 3. Repository.login() 호출
    /// 4. LoginResponse에서 .user만 추출하여 반환
    ///
    /// - Parameters:
    ///   - id: 사용자 입력 ID (성함)
    ///   - password: 사용자 입력 비밀번호 (생년월일)
    /// - Returns: 로그인 성공 시 UserInfo
    func execute(id: String, password: String) -> Single<UserInfo> {
        // 입력 검증 — 빈 값이면 즉시 에러 반환 (네트워크 호출 불필요)
        guard !id.trimmed.isEmpty else {
            return .error(LoginError.emptyId)
        }
        guard !password.trimmed.isEmpty else {
            return .error(LoginError.emptyPassword)
        }

        // Repository에 API 호출 위임
        return repository.login(request: LoginRequest(id: id, password: password))
            .map { $0.user }  // LoginResponse → UserInfo 추출
    }

    // MARK: - 자동 로그인 확인

    /// Keychain에 토큰이 있으면 자동 로그인 가능
    func checkAutoLogin() -> Bool {
        repository.getSavedToken() != nil
    }

    // MARK: - 로그아웃

    /// Keychain 토큰 삭제
    func logout() {
        repository.logout()
    }
}

// MARK: - LoginError
/// 로그인 관련 에러 정의
/// LocalizedError 채택 → .localizedDescription으로 한글 메시지 바로 사용 가능
enum LoginError: LocalizedError {
    /// ID(성함) 미입력
    case emptyId
    /// 비밀번호(생년월일) 미입력
    case emptyPassword
    /// 서버에서 인증 실패 (401)
    case invalidCredentials
    /// 서버 에러 (기타)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyId:
            return "이름을 입력해주세요."
        case .emptyPassword:
            return "생년월일을 입력해주세요."
        case .invalidCredentials:
            return "이름 또는 생년월일이 올바르지 않습니다."
        case .serverError(let msg):
            return msg
        }
    }
}
