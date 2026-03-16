import Foundation
import RxSwift
@testable import HiTrip

// MARK: - MockAuthRepository
/// 테스트용 가짜 Repository
///
/// 역할:
/// - 네트워크 요청 없이 UseCase의 비즈니스 로직만 독립 테스트
/// - 테스트 케이스마다 성공/실패 응답을 자유롭게 설정 가능
///
/// 사용 예시:
/// ```
/// let mock = MockAuthRepository()
/// mock.loginResult = .success(fakeResponse)  // 성공 케이스
/// mock.loginResult = .failure(someError)     // 실패 케이스
/// let useCase = LoginUseCase(repository: mock)
/// ```
///
/// 면접 포인트:
/// "테스트에서 Mock 객체를 왜 사용하셨나요?"
/// → "UseCase는 비즈니스 로직만 담당하므로, 네트워크나 DB 같은
///    외부 의존성을 Mock으로 교체하면 로직만 순수하게 검증할 수 있습니다.
///    Protocol 기반 설계(DIP) 덕분에 프로덕션 코드 수정 없이
///    Mock을 주입할 수 있었습니다."

final class MockAuthRepository: AuthRepositoryProtocol {

    // MARK: - 테스트 제어용 프로퍼티

    /// login() 호출 시 반환할 결과 (테스트마다 설정)
    var loginResult: Result<LoginResponse, Error> = .failure(MockError.notConfigured)

    /// checkNickname() 호출 시 반환할 결과
    var nicknameResult: Result<NicknameCheckResponse, Error> = .failure(MockError.notConfigured)

    /// signUp() 호출 시 반환할 결과
    var signUpResult: Result<SignUpResponse, Error> = .failure(MockError.notConfigured)

    /// getSavedToken() 호출 시 반환할 토큰 값 (nil이면 로그인 안 된 상태)
    var savedToken: String? = nil

    /// 각 메서드가 몇 번 호출되었는지 추적
    /// - 테스트에서 "이 메서드가 실제로 호출되었는가?" 검증용
    var loginCallCount = 0
    var checkNicknameCallCount = 0
    var signUpCallCount = 0
    var logoutCallCount = 0

    // MARK: - AuthRepositoryProtocol 구현

    func login(request: LoginRequest) -> Single<LoginResponse> {
        loginCallCount += 1
        switch loginResult {
        case .success(let response):
            return .just(response)
        case .failure(let error):
            return .error(error)
        }
    }

    func refreshToken() -> Single<LoginResponse> {
        // 이번 Phase에서는 테스트하지 않음
        return .error(MockError.notConfigured)
    }

    func getSavedToken() -> String? {
        return savedToken
    }

    func logout() {
        logoutCallCount += 1
        savedToken = nil
    }

    func checkNickname(_ nickname: String) -> Single<NicknameCheckResponse> {
        checkNicknameCallCount += 1
        switch nicknameResult {
        case .success(let response):
            return .just(response)
        case .failure(let error):
            return .error(error)
        }
    }

    func signUp(request: SignUpRequest) -> Single<SignUpResponse> {
        signUpCallCount += 1
        switch signUpResult {
        case .success(let response):
            return .just(response)
        case .failure(let error):
            return .error(error)
        }
    }
}

// MARK: - MockError
/// Mock 전용 에러
enum MockError: Error {
    /// 테스트 설정을 안 한 상태에서 호출됨
    case notConfigured
}

// MARK: - Test Fixtures (테스트용 더미 데이터)
/// 테스트에서 반복 사용하는 가짜 데이터를 한 곳에 모아 관리
enum TestFixtures {

    /// 더미 UserInfo
    static let sampleUser = UserInfo(
        id: "user123",
        name: "테스트유저",
        userType: .tourist,
        phone: "010-1234-5678",
        country: "KR"
    )

    /// 더미 LoginResponse (login 성공)
    static let loginSuccess = LoginResponse(
        accessToken: "fake-access-token",
        refreshToken: "fake-refresh-token",
        user: sampleUser
    )

    /// 더미 NicknameCheckResponse (닉네임 사용 가능)
    static let nicknameAvailable = NicknameCheckResponse(
        isAvailable: true,
        message: "사용 가능한 닉네임입니다."
    )

    /// 더미 NicknameCheckResponse (닉네임 중복)
    static let nicknameDuplicate = NicknameCheckResponse(
        isAvailable: false,
        message: "이미 사용 중인 닉네임입니다."
    )

    /// 더미 SignUpResponse (가입 성공)
    static let signUpSuccess = SignUpResponse(
        message: "가입이 완료되었습니다.",
        user: sampleUser
    )
}
