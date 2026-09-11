import Foundation
import RxSwift

// MARK: - AuthRepositoryProtocol
/// Auth 관련 데이터 접근 인터페이스 (Domain 레이어)
///
/// 설계 의도 — 의존성 역전 원칙(DIP) 적용:
/// - Domain 레이어는 이 Protocol만 알고, 실제 구현체(AuthRepository)는 모름
/// - 프로덕션: AuthRepository (URLSession + Keychain)
/// - 테스트: MockAuthRepository (가짜 응답 반환)
///
/// 회원가입은 없습니다. 계정은 SaaS(여행사 관리자)에서만 발급·변경합니다.

protocol AuthRepositoryProtocol {

    /// 로그인 — 역할(관광객/안내사)은 서버 응답으로 정해집니다
    func login(request: LoginRequest) -> Single<LoginResponse>

    /// 저장된 세션이 아직 유효한지 서버에 확인 (스플래시 자동 로그인)
    func validateSession() -> Single<SessionState>

    /// Keychain에 저장된 토큰 조회 (자동 로그인 확인용)
    func getSavedToken() -> String?

    /// 관광객 최초 비밀번호 변경 — 발급받은 임시 비밀번호로 처음 로그인하면 서버가 요구합니다
    func changeInitialPassword(username: String, currentPassword: String, newPassword: String) -> Single<Void>

    /// 로그아웃 — 서버 세션 종료 + 로컬 인증 정보 삭제
    func logout()
}
