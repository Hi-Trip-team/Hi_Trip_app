import Foundation
import RxSwift

// MARK: - AuthRepository
/// AuthRepositoryProtocol의 실제 구현체 (Data 레이어)
///
/// Clean Architecture에서의 위치:
/// ```
/// Domain (Protocol 정의)  ←── 여기서 구현
///                              │
///                         Data 레이어
///                         ├── AuthRepository  ← 이 파일
///                         └── NetworkService, KeychainManager 사용
/// ```
///
/// 역할:
/// - NetworkService로 서버 API 호출
/// - 로그인 성공 시 Keychain에 토큰/유저 정보 자동 저장
/// - UseCase는 이 구현체를 모르고, Protocol만 알고 호출
///
/// 면접 포인트:
/// "Repository 패턴의 장점은 무엇인가요?"
/// → "데이터 소스(네트워크, 로컬DB, 캐시)를 추상화하여
///    UseCase가 구체적인 구현에 의존하지 않게 합니다.
///    나중에 CoreData 캐싱을 추가해도 UseCase 코드는 변경 불필요합니다."

final class AuthRepository: AuthRepositoryProtocol {

    // MARK: - Dependencies

    private let networkService: NetworkService
    private let keychain = KeychainManager.shared

    // MARK: - Init

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    // MARK: - 로그인

    /// 로그인 API 호출 + 토큰 자동 저장
    ///
    /// .do(onSuccess:) 사용 이유:
    /// - .map은 값을 변환할 때, .do는 부수효과(side effect)를 실행할 때 사용
    /// - 토큰 저장은 값 변환이 아닌 부수효과이므로 .do가 적합
    /// - [weak self]로 메모리 누수 방지
    func login(request: LoginRequest) -> Single<LoginResponse> {
        let endpoint = APIEndpoint.login(
            id: request.id,
            password: request.password
        )

        return networkService.request(endpoint, type: LoginResponse.self)
            .do(onSuccess: { [weak self] response in
                // 로그인 성공 시 Keychain에 토큰 + 유저 정보 저장
                self?.keychain.saveToken(response.accessToken)
                self?.keychain.saveRefreshToken(response.refreshToken)
                self?.keychain.saveUserId(response.user.id)
                self?.keychain.saveUserType(response.user.userType.rawValue)
            })
    }

    // MARK: - 토큰 갱신

    /// Refresh Token으로 새 Access Token 발급
    ///
    /// 호출 시점: Access Token 만료 시 (HTTP 401 응답)
    /// 동작: Keychain의 Refresh Token → 서버에 갱신 요청 → 새 토큰 저장
    func refreshToken() -> Single<LoginResponse> {
        guard let token = keychain.getRefreshToken() else {
            return .error(LoginError.invalidCredentials)
        }

        return networkService.request(
            APIEndpoint.refreshToken(token: token),
            type: LoginResponse.self
        )
        .do(onSuccess: { [weak self] response in
            self?.keychain.saveToken(response.accessToken)
            self?.keychain.saveRefreshToken(response.refreshToken)
        })
    }

    // MARK: - 토큰 조회

    /// Keychain에 저장된 Access Token 반환
    /// nil이면 미로그인 상태 → 로그인 화면 표시
    func getSavedToken() -> String? {
        keychain.getToken()
    }

    // MARK: - 로그아웃

    /// Keychain의 모든 인증 데이터 삭제
    func logout() {
        keychain.clearAll()
    }

    // MARK: - 닉네임 중복 확인

    func checkNickname(_ nickname: String) -> Single<NicknameCheckResponse> {
        let endpoint = APIEndpoint.checkNickname(nickname)
        return networkService.request(endpoint, type: NicknameCheckResponse.self)
    }

    // MARK: - 회원가입

    func signUp(request: SignUpRequest) -> Single<SignUpResponse> {
        let endpoint = APIEndpoint.signUp(
            nickname: request.nickname,
            userId: request.userId,
            password: request.password
        )
        return networkService.request(endpoint, type: SignUpResponse.self)
    }
}
