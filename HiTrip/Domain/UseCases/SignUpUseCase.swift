import Foundation
import RxSwift

// MARK: - SignUpUseCase
/// 회원가입 비즈니스 로직 담당
///
/// 담당 기능:
/// 1. 닉네임 중복 확인 (API 호출)
/// 2. 회원가입 실행 (입력 검증 → API 호출)
///
/// LoginUseCase와 동일한 설계 패턴:
/// - AuthRepositoryProtocol에만 의존 (DIP)
/// - 입력 검증은 UseCase에서, API 호출은 Repository에서
/// - 검증 실패 시 네트워크 호출 없이 즉시 에러 반환

final class SignUpUseCase {

    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 닉네임 중복 확인

    /// 닉네임 유효성 검증 후 서버에 중복 확인 요청
    ///
    /// 검증 순서:
    /// 1. 빈 값 체크
    /// 2. 최소 길이(2자) 체크
    /// 3. 서버 API 호출 (Repository 위임)
    func checkNickname(_ nickname: String) -> Single<NicknameCheckResponse> {
        guard !nickname.trimmed.isEmpty else {
            return .error(SignUpError.emptyNickname)
        }
        guard nickname.trimmed.count >= 2 else {
            return .error(SignUpError.nicknameTooShort)
        }

        return repository.checkNickname(nickname.trimmed)
    }

    // MARK: - 회원가입 실행

    /// 전체 입력값 검증 후 회원가입 API 호출
    ///
    /// 검증 순서 (서버 호출 전에 클라이언트에서 먼저 걸러냄):
    /// 1. 닉네임 빈 값
    /// 2. 아이디 빈 값 → 최소 4자
    /// 3. 비밀번호 빈 값 → 최소 6자
    /// 4. 비밀번호 확인 일치 여부
    /// 5. 모두 통과하면 Repository.signUp() 호출
    func execute(
        nickname: String,
        userId: String,
        password: String,
        passwordConfirm: String
    ) -> Single<SignUpResponse> {

        // 1) 닉네임 검증
        guard !nickname.trimmed.isEmpty else {
            return .error(SignUpError.emptyNickname)
        }

        // 2) 아이디 검증
        guard !userId.trimmed.isEmpty else {
            return .error(SignUpError.emptyUserId)
        }
        guard userId.trimmed.count >= 4 else {
            return .error(SignUpError.userIdTooShort)
        }

        // 3) 비밀번호 검증
        guard !password.isEmpty else {
            return .error(SignUpError.emptyPassword)
        }
        guard password.count >= 6 else {
            return .error(SignUpError.passwordTooShort)
        }

        // 4) 비밀번호 확인
        guard password == passwordConfirm else {
            return .error(SignUpError.passwordMismatch)
        }

        // 5) API 호출
        let request = SignUpRequest(
            nickname: nickname.trimmed,
            userId: userId.trimmed,
            password: password
        )
        return repository.signUp(request: request)
    }
}

// MARK: - SignUpError
/// 회원가입 관련 에러 정의
enum SignUpError: LocalizedError, Equatable {
    case emptyNickname
    case nicknameTooShort      // 2자 미만
    case nicknameDuplicate     // 서버에서 중복 판정
    case emptyUserId
    case userIdTooShort        // 4자 미만
    case emptyPassword
    case passwordTooShort      // 6자 미만
    case passwordMismatch      // 비밀번호 ≠ 확인
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyNickname:     return "닉네임을 입력해주세요."
        case .nicknameTooShort:  return "닉네임은 2자 이상이어야 합니다."
        case .nicknameDuplicate: return "이미 사용 중인 닉네임입니다."
        case .emptyUserId:       return "아이디를 입력해주세요."
        case .userIdTooShort:    return "아이디는 4자 이상이어야 합니다."
        case .emptyPassword:     return "비밀번호를 입력해주세요."
        case .passwordTooShort:  return "비밀번호는 6자 이상이어야 합니다."
        case .passwordMismatch:  return "비밀번호가 일치하지 않습니다."
        case .serverError(let msg): return msg
        }
    }
}
