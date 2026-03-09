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
/// Clean Architecture에서의 위치:
/// ```
/// Domain (Protocol 정의)  ←  Data (구현체)
///        ↑
///   UseCase가 사용
/// ```
///
/// 면접 포인트:
/// "왜 Protocol을 따로 만드셨나요?"
/// → "DIP를 적용하여 Domain이 Data에 의존하지 않도록 역전시켰습니다.
///    테스트 시 Mock 교체로 네트워크 없이 비즈니스 로직만 검증 가능합니다."

protocol AuthRepositoryProtocol {

    /// 로그인 API 호출
    /// - Parameter request: ID + Password
    /// - Returns: 토큰 + 유저 정보가 담긴 LoginResponse
    func login(request: LoginRequest) -> Single<LoginResponse>

    /// Refresh Token으로 Access Token 갱신
    func refreshToken() -> Single<LoginResponse>

    /// Keychain에 저장된 토큰 조회 (자동 로그인 확인용)
    func getSavedToken() -> String?

    /// 로그아웃 — Keychain의 모든 토큰 삭제
    func logout()

    /// 닉네임 중복 확인 API
    func checkNickname(_ nickname: String) -> Single<NicknameCheckResponse>

    /// 회원가입 API 호출
    func signUp(request: SignUpRequest) -> Single<SignUpResponse>
}
