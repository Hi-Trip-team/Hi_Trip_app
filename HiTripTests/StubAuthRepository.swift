import Foundation
import RxSwift
@testable import HiTrip

// MARK: - StubAuthRepository
/// 테스트용 가짜 Repository — 네트워크 없이 LoginUseCase의 로직만 검증합니다
///
/// - 테스트마다 돌려줄 결과(`loginResult` 등)를 정해 둡니다
/// - 받은 요청을 기록해 "UseCase가 무엇을 넘겼는지"를 확인합니다
///
/// 앱 타깃에도 화면 미리보기용 `MockAuthRepository`가 있어 이름을 구분합니다.
///
/// 사용 예:
/// ```
/// let stub = StubAuthRepository()
/// stub.loginResult = .success(TestFixtures.loginSuccess)
/// let useCase = LoginUseCase(repository: stub)
/// ```

final class StubAuthRepository: AuthRepositoryProtocol {

    // MARK: - 돌려줄 결과

    var loginResult: Result<LoginResponse, Error> = .failure(StubError.notConfigured)
    var sessionResult: Result<SessionState, Error> = .failure(StubError.notConfigured)
    var passwordChangeResult: Result<Void, Error> = .success(())

    // MARK: - 받은 요청 기록

    private(set) var loginRequests: [LoginRequest] = []
    private(set) var passwordChanges: [(username: String, currentPassword: String, newPassword: String)] = []
    private(set) var validateSessionCallCount = 0
    private(set) var logoutCallCount = 0

    var loginCallCount: Int { loginRequests.count }

    // MARK: - AuthRepositoryProtocol

    func login(request: LoginRequest) -> Single<LoginResponse> {
        loginRequests.append(request)
        return Self.single(loginResult)
    }

    func validateSession() -> Single<SessionState> {
        validateSessionCallCount += 1
        return Self.single(sessionResult)
    }

    func changeInitialPassword(username: String, currentPassword: String, newPassword: String) -> Single<Void> {
        passwordChanges.append((username, currentPassword, newPassword))
        return Self.single(passwordChangeResult)
    }

    func logout() -> Single<Void> {
        logoutCallCount += 1
        return .just(())
    }

    private static func single<T>(_ result: Result<T, Error>) -> Single<T> {
        switch result {
        case .success(let value): return .just(value)
        case .failure(let error): return .error(error)
        }
    }
}

// MARK: - StubError

enum StubError: Error {
    /// 결과를 정하지 않은 채 호출됨
    case notConfigured
}

// MARK: - TestFixtures
/// 여러 테스트가 함께 쓰는 더미 데이터

enum TestFixtures {

    static let sampleUser = UserInfo(
        id: "user123",
        name: "테스트유저",
        userType: .tourist,
        phone: "010-0000-0000",
        country: "KR"
    )

    static let loginSuccess = LoginResponse(
        accessToken: "fake-access-token",
        refreshToken: "fake-access-token",
        user: sampleUser,
        requiresAgreement: false
    )
}
