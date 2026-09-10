import Foundation
import RxSwift

// MARK: - AuthRepository
/// AuthRepositoryProtocol의 실제 구현체 (Data 레이어)
///
/// 로그인 화면은 하나지만 서버 로그인 API는 역할별로 둘입니다.
/// - 관광객: POST /api/v1/tourist/auth/login/  → Bearer 토큰 (expires_at 포함)
/// - 안내사: POST /api/v1/staff/auth/login/    → 세션 쿠키 + CSRF
///
/// 앱이 아이디 모양으로 역할을 추측하지 않도록, 관광객 API를 먼저 부르고
/// "계정 없음/불일치(401)"일 때만 안내사 API로 다시 확인합니다.
/// 어느 API가 성공했는지(=서버가 인정한 계정 종류)로 홈을 나눕니다.

final class AuthRepository: AuthRepositoryProtocol {

    // MARK: - Dependencies

    private let networkService: NetworkService
    private let keychain = KeychainManager.shared

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    // MARK: - 로그인

    func login(request: LoginRequest) -> Single<LoginResponse> {
        touristLogin(request)
            .catch { [weak self] error in
                guard let self else { throw error }
                if case .unauthorized = ErrorHandler.classify(error) {
                    return self.staffLogin(request)
                }
                throw error
            }
            .catch { throw Self.loginError(from: $0) }
    }

    // MARK: 관광객

    private func touristLogin(_ request: LoginRequest) -> Single<LoginResponse> {
        let endpoint = APIEndpoint.travelerLogin(
            username: request.id,
            password: request.password,
            tripId: request.tripId,
            force: request.force
        )
        return networkService.request(endpoint, type: TravelerAuthResponseDTO.self)
            .catch { [weak self] error in
                // 여행이 여러 개인 계정은 409 + trips 목록이 옵니다 → 진행 중인 여행으로 다시 로그인
                guard let self,
                      request.tripId == nil,
                      case .conflict(let detail) = ErrorHandler.classify(error),
                      let tripId = Self.currentTripId(fromConflictBody: detail.rawBody) else { throw error }
                var retry = request
                retry.tripId = tripId
                return self.networkService.request(
                    .travelerLogin(username: retry.id, password: retry.password, tripId: tripId, force: retry.force),
                    type: TravelerAuthResponseDTO.self
                )
            }
            .map { [weak self] dto in
                guard let self else { throw HiTripError.invalidResponse }
                let traveler = dto.traveler
                self.keychain.saveToken(dto.token)
                if let expiresAt = dto.expiresAt { self.keychain.saveTokenExpiry(expiresAt) }
                self.keychain.saveUserId(String(traveler.id))
                self.keychain.saveUserType(UserType.tourist.rawValue)
                self.keychain.saveUserName(traveler.fullNameKr)
                self.keychain.saveUserEmail(traveler.email)

                return LoginResponse(
                    accessToken: dto.token,
                    refreshToken: dto.token,
                    user: UserInfo(
                        id: String(traveler.id),
                        name: traveler.fullNameKr,
                        userType: .tourist,
                        phone: traveler.phone,
                        country: traveler.country
                    ),
                    requiresAgreement: dto.requiresAgreement
                )
            }
    }

    /// 409 본문의 trips 중 오늘 진행 중 → 가장 가까운 예정 → 가장 최근 순으로 고릅니다.
    private static func currentTripId(fromConflictBody body: String?) -> Int? {
        guard let data = body?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let trips = json["trips"] as? [[String: Any]], !trips.isEmpty else { return nil }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let today = Calendar.current.startOfDay(for: Date())

        let parsed: [(id: Int, start: Date, end: Date)] = trips.compactMap {
            guard let id = $0["id"] as? Int,
                  let s = ($0["start_date"] as? String).flatMap(df.date(from:)),
                  let e = ($0["end_date"] as? String).flatMap(df.date(from:)) else { return nil }
            return (id, s, e)
        }
        if let ongoing = parsed.first(where: { $0.start <= today && today <= $0.end }) { return ongoing.id }
        if let upcoming = parsed.filter({ $0.start > today }).min(by: { $0.start < $1.start }) { return upcoming.id }
        return parsed.max(by: { $0.end < $1.end })?.id
    }

    // MARK: 안내사

    private func staffLogin(_ request: LoginRequest) -> Single<LoginResponse> {
        // 세션 쿠키 + CSRF 방식이라 토큰을 먼저 받아야 합니다. 건너뛰면 403.
        networkService.request(.staffCSRF(), type: CSRFTokenDTO.self)
            .do(onSuccess: { NetworkService.csrfToken = $0.csrfToken })
            .catch { _ in .just(CSRFTokenDTO(csrfToken: "")) }
            .flatMap { [weak self] _ -> Single<AuthLoginResponse> in
                guard let self else { return .error(HiTripError.invalidResponse) }
                return self.networkService.request(
                    .login(username: request.id, password: request.password, force: request.force),
                    type: AuthLoginResponse.self
                )
            }
            .map { [weak self] (dto: AuthLoginResponse) -> LoginResponse in
                guard let self else { throw HiTripError.invalidResponse }
                // 서버 역할값: admin | manager | tourist (UserRoleEnum)
                let role = (dto.role ?? "").lowercased()
                let userType: UserType = role == "tourist" ? .tourist : .guide
                let userId = dto.id.map(String.init) ?? "0"

                // 세션 인증이라 실제 토큰은 쿠키에 있습니다. 로그인 여부 표시용 값만 저장합니다.
                self.keychain.saveToken(Self.staffSessionMarker)
                self.keychain.saveUserId(userId)
                self.keychain.saveUserType(userType.rawValue)
                self.keychain.saveUserName(dto.displayName)
                self.keychain.saveUserEmail(dto.displayEmail)

                return LoginResponse(
                    accessToken: Self.staffSessionMarker,
                    refreshToken: Self.staffSessionMarker,
                    user: UserInfo(id: userId, name: dto.displayName, userType: userType, phone: dto.phone, country: nil),
                    // 약관·권한은 기기 첫 접근 때만 — 기기 기록으로 판단합니다.
                    requiresAgreement: !AgreementRecordStore.hasAgreedOnDevice
                )
            }
    }

    static let staffSessionMarker = "session-auth"

    // MARK: - 에러 변환

    /// 동시 로그인 감지 코드 — ⚠️ 서버 스펙 미정. 확정되면 이 목록만 맞춥니다.
    private static let concurrentSessionCodes: Set<String> = ["CONCURRENT_LOGIN", "SESSION_EXISTS", "ALREADY_LOGGED_IN"]

    private static func loginError(from error: Error) -> Error {
        if error is LoginError { return error }
        switch ErrorHandler.classify(error) {
        case .unauthorized(let detail):
            return LoginError.invalidCredentials(remaining: detail.numbers["remaining_attempts"])
        case .rateLimited(let detail):
            let seconds = detail.retryAfter
                ?? detail.numbers["retry_after"]
                ?? detail.numbers["lock_seconds"]
                ?? LoginAttemptStore.defaultLockSeconds
            return LoginError.locked(seconds: seconds)
        case .conflict(let detail) where concurrentSessionCodes.contains(detail.code ?? ""):
            return LoginError.concurrentSession
        case .noConnection, .timeout, .networkFailure:
            return LoginError.network
        case let other:
            return LoginError.serverError(other.localizedDescription)
        }
    }

    // MARK: - 자동 로그인 확인

    /// 역할별로 "로그인해야만 성공하는" 가벼운 API를 불러 세션을 확인합니다.
    /// - 관광객: GET /api/v1/tourist/agreements/ — 약관 동의 필요 여부도 함께 받습니다
    /// - 안내사: GET /api/v1/staff/auth/me/
    func validateSession() -> Single<SessionState> {
        let type = UserType(rawValue: keychain.getUserType() ?? "") ?? .tourist

        if type == .tourist {
            if let expiry = keychain.getTokenExpiry(), expiry <= Date() {
                return .error(HiTripError.unauthorized(ServerErrorDetail(
                    message: "로그인 유효기간이 지났습니다.", fieldErrors: [:], rawBody: nil, statusCode: 401
                )))
            }
            return networkService.request(.travelerAgreements(), type: TravelerAgreementDTO.self)
                .map { SessionState(userType: .tourist, requiresAgreement: $0.requiresAgreement) }
        }

        return networkService.request(.staffMe(), type: StaffProfileDTO.self)
            .map { _ in
                SessionState(
                    userType: .guide,
                    requiresAgreement: !AgreementRecordStore.hasAgreedOnDevice
                )
            }
    }

    func getSavedToken() -> String? {
        keychain.getToken()
    }

    // MARK: - 로그아웃

    /// 서버 로그아웃 호출 + 로컬 인증 정보 삭제 (서버 실패와 무관하게 로컬은 지웁니다)
    func logout() {
        let isTourist = keychain.getUserType() == UserType.tourist.rawValue
        let endpoint: APIEndpoint = isTourist ? .travelerLogout() : .staffLogout()
        _ = networkService.request(endpoint, type: EmptyResponse.self).subscribe()
        keychain.clearAll()
        NetworkService.clearSession()
    }
}
