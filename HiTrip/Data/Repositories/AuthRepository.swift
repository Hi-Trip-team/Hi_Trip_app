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
/// API 연동 현황:
/// - login: POST /api/auth/login/ → AuthLoginResponse (token/key 기반)
/// - register: POST /api/auth/register/ → ProfileDTO
/// - profile: GET /api/auth/profile/ → ProfileDTO
/// - logout: POST /api/auth/logout/
/// - refreshToken: 서버 미지원 → 기존 토큰 재사용 fallback
/// - checkNickname: 서버 미지원 → 항상 사용 가능 반환

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
    /// 실제 API: POST /api/auth/login/
    /// 응답: AuthLoginResponse { token, key, sessionid }
    /// → 기존 LoginResponse로 변환하여 UseCase/ViewModel 코드 변경 최소화
    func login(request: LoginRequest) -> Single<LoginResponse> {
        let endpoint = APIEndpoint.login(
            username: request.id,
            password: request.password
        )

        return networkService.request(endpoint, type: AuthLoginResponse.self)
            .map { [weak self] authResponse in
                guard let self else { throw HiTripError.invalidResponse }

                // 1) 토큰 저장 (토큰 기반 인증인 경우)
                let token = authResponse.token ?? authResponse.key ?? "session-auth"
                self.keychain.saveToken(token)

                // 2) ✅ 서버 UserDetail 정보를 Keychain에 저장
                let displayName = authResponse.displayName
                let displayEmail = authResponse.displayEmail

                self.keychain.saveUserName(displayName)
                self.keychain.saveUserEmail(displayEmail)

                if let userId = authResponse.id {
                    self.keychain.saveUserId(String(userId))
                }
                if let role = authResponse.role {
                    self.keychain.saveUserType(role)
                }

                print("✅ [Auth] 유저 정보 저장: name=\(displayName), email=\(displayEmail), role=\(authResponse.role ?? "none")")

                // 3) 기존 LoginResponse 형태로 변환 (UseCase/ViewModel 호환)
                let userType: UserType = (authResponse.role == "super_admin" || authResponse.role == "coordinator") ? .guide : .tourist

                let userInfo = UserInfo(
                    id: authResponse.id.map(String.init) ?? "0",
                    name: displayName,
                    userType: userType,
                    phone: authResponse.phone,
                    country: nil
                )
                return LoginResponse(
                    accessToken: token,
                    refreshToken: token,
                    user: userInfo
                )
            }
    }

    // MARK: - 토큰 갱신

    /// Refresh Token 갱신
    /// 현재 서버에 refresh 엔드포인트가 없으므로,
    /// 기존 토큰이 있으면 그대로 반환 (세션 기반 인증)
    func refreshToken() -> Single<LoginResponse> {
        guard let token = keychain.getToken() else {
            return .error(HiTripError.unauthorized(
                ServerErrorDetail(message: "저장된 인증 정보가 없습니다.", fieldErrors: [:], rawBody: nil, statusCode: 401)
            ))
        }

        // 서버에 refresh API가 없으므로 기존 토큰으로 프로필 조회하여 유효성 확인
        return networkService.request(APIEndpoint.profile(), type: ProfileDTO.self)
            .map { profileDTO in
                let user = profileDTO.toUser()
                return LoginResponse(
                    accessToken: token,
                    refreshToken: token,
                    user: UserInfo(
                        id: user.id.uuidString,
                        name: user.nickname,
                        userType: .tourist,
                        phone: nil,
                        country: nil
                    )
                )
            }
    }

    // MARK: - 토큰 조회

    /// Keychain에 저장된 Access Token 반환
    /// nil이면 미로그인 상태 → 로그인 화면 표시
    func getSavedToken() -> String? {
        keychain.getToken()
    }

    // MARK: - 로그아웃

    /// 서버 로그아웃 호출 + Keychain 데이터 삭제
    func logout() {
        // 서버에 로그아웃 알림 (실패해도 로컬은 삭제)
        _ = networkService.request(APIEndpoint.logout(), type: TravelerLogoutResponseDTO.self)
            .subscribe()
        keychain.clearAll()
    }

    // MARK: - 닉네임 중복 확인

    /// 현재 서버에 닉네임 중복 확인 API가 없음
    /// → 항상 사용 가능으로 반환 (서버 추가 시 연동 예정)
    func checkNickname(_ nickname: String) -> Single<NicknameCheckResponse> {
        return .just(NicknameCheckResponse(isAvailable: true, message: nil))
    }

    // MARK: - 회원가입

    /// 회원가입 API: POST /api/auth/register/
    /// 서버 응답(ProfileDTO)을 기존 SignUpResponse로 변환
    func signUp(request: SignUpRequest) -> Single<SignUpResponse> {
        let endpoint = APIEndpoint.register(
            username: request.userId,
            password: request.password,
            email: "\(request.userId)@hitrip.app"  // 이메일 필수 → userId 기반 자동 생성
        )

        print("📤 [Auth] 회원가입 요청: username=\(request.userId), email=\(request.userId)@hitrip.app")

        return networkService.request(endpoint, type: ProfileDTO.self)
            .do(onSuccess: { dto in
                print("✅ [Auth] 회원가입 성공: \(dto)")
            }, onError: { error in
                print("❌ [Auth] 회원가입 실패: \(error)")
            })
            .map { [weak self] profileDTO in
                let user = profileDTO.toUser()

                // ✅ 회원가입 후에도 유저 정보를 Keychain에 저장
                self?.keychain.saveUserName(user.nickname)
                self?.keychain.saveUserEmail(user.email)
                if let id = profileDTO.id {
                    self?.keychain.saveUserId(String(id))
                }

                return SignUpResponse(
                    message: "회원가입이 완료되었습니다.",
                    user: UserInfo(
                        id: profileDTO.id.map(String.init) ?? user.id.uuidString,
                        name: user.nickname,
                        userType: .tourist,
                        phone: profileDTO.phone,
                        country: nil
                    )
                )
            }
    }
}
