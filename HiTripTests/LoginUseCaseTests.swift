import XCTest
import RxSwift
@testable import HiTrip

// MARK: - LoginUseCaseTests
/// LoginUseCase 검증 — Repository는 StubAuthRepository로 바꿔 끼웁니다
///
/// 1. 입력 검증: 빈 아이디·공백 아이디·빈 비밀번호는 서버에 보내지 않음
/// 2. 로그인: 아이디 앞뒤 공백 제거, 강제 로그인(force) 전달, 서버 에러 그대로 전달
/// 3. 자동 로그인: 세션 확인 결과(역할·약관 필요 여부) 전달
/// 4. 최초 비밀번호 변경: 아이디 공백 제거 후 전달, 실패 전달
/// 5. 로그아웃: Repository 로그아웃이 끝나면 완료

final class LoginUseCaseTests: XCTestCase {

    private var sut: LoginUseCase!
    private var repository: StubAuthRepository!

    override func setUp() {
        super.setUp()
        repository = StubAuthRepository()
        sut = LoginUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - 1. 입력 검증

    func test_빈_아이디면_emptyId_에러이고_서버에_보내지_않는다() {
        let error = awaitFailure(sut.execute(id: "", password: "pw"))

        XCTAssertEqual(error as? LoginError, .emptyId)
        XCTAssertEqual(repository.loginCallCount, 0)
    }

    func test_공백만_있는_아이디는_빈_아이디로_본다() {
        let error = awaitFailure(sut.execute(id: "   ", password: "pw"))

        XCTAssertEqual(error as? LoginError, .emptyId)
        XCTAssertEqual(repository.loginCallCount, 0)
    }

    func test_빈_비밀번호면_emptyPassword_에러이고_서버에_보내지_않는다() {
        let error = awaitFailure(sut.execute(id: "tourist01", password: ""))

        XCTAssertEqual(error as? LoginError, .emptyPassword)
        XCTAssertEqual(repository.loginCallCount, 0)
    }

    // MARK: - 2. 로그인

    func test_로그인_성공시_응답을_그대로_전달한다() {
        repository.loginResult = .success(TestFixtures.loginSuccess)

        let response = awaitSuccess(sut.execute(id: "tourist01", password: "pw"))

        XCTAssertEqual(response?.user.id, "user123")
        XCTAssertEqual(response?.user.userType, .tourist)
        XCTAssertEqual(repository.loginCallCount, 1)
    }

    func test_아이디_앞뒤_공백을_지우고_보낸다() {
        repository.loginResult = .success(TestFixtures.loginSuccess)

        _ = awaitSuccess(sut.execute(id: "  tourist01 ", password: "pw"))

        XCTAssertEqual(repository.loginRequests.first?.id, "tourist01")
    }

    func test_기본_로그인은_force_없이_보낸다() {
        repository.loginResult = .success(TestFixtures.loginSuccess)

        _ = awaitSuccess(sut.execute(id: "tourist01", password: "pw"))

        XCTAssertEqual(repository.loginRequests.first?.force, false)
    }

    func test_강제_로그인_요청은_force를_그대로_전달한다() {
        repository.loginResult = .success(TestFixtures.loginSuccess)

        _ = awaitSuccess(sut.execute(id: "tourist01", password: "pw", force: true))

        XCTAssertEqual(repository.loginRequests.first?.force, true)
    }

    func test_서버_에러는_그대로_전달한다() {
        repository.loginResult = .failure(LoginError.invalidCredentials(remaining: 2))

        let error = awaitFailure(sut.execute(id: "tourist01", password: "wrong"))

        XCTAssertEqual(error as? LoginError, .invalidCredentials(remaining: 2))
        XCTAssertEqual(repository.loginCallCount, 1)
    }

    // MARK: - 3. 자동 로그인 (세션 확인)

    func test_세션_확인_결과를_그대로_전달한다() {
        repository.sessionResult = .success(SessionState(userType: .guide, requiresAgreement: true))

        let state = awaitSuccess(sut.validateSession())

        XCTAssertEqual(state?.userType, .guide)
        XCTAssertEqual(state?.requiresAgreement, true)
        XCTAssertEqual(repository.validateSessionCallCount, 1)
    }

    func test_세션이_만료되면_에러를_전달한다() {
        repository.sessionResult = .failure(StubError.notConfigured)

        let error = awaitFailure(sut.validateSession())

        XCTAssertNotNil(error)
    }

    // MARK: - 4. 최초 비밀번호 변경

    func test_비밀번호_변경시_아이디_공백을_지우고_보낸다() {
        _ = awaitSuccess(sut.changeInitialPassword(username: " tourist01 ", currentPassword: "temp", newPassword: "new-pw"))

        let call = repository.passwordChanges.first
        XCTAssertEqual(call?.username, "tourist01")
        XCTAssertEqual(call?.currentPassword, "temp")
        XCTAssertEqual(call?.newPassword, "new-pw")
    }

    func test_비밀번호_변경_실패_문구를_그대로_전달한다() {
        repository.passwordChangeResult = .failure(PasswordChangeError.rejected("사용할 수 없는 비밀번호예요."))

        let error = awaitFailure(sut.changeInitialPassword(username: "tourist01", currentPassword: "temp", newPassword: "1"))

        XCTAssertEqual(error?.localizedDescription, "사용할 수 없는 비밀번호예요.")
    }

    // MARK: - 5. 로그아웃

    func test_로그아웃은_Repository_로그아웃이_끝나면_완료된다() {
        let done = awaitSuccess(sut.logout())

        XCTAssertNotNil(done)
        XCTAssertEqual(repository.logoutCallCount, 1)
    }
}

// MARK: - Rx 헬퍼
/// Single을 기다려 성공값이나 에러를 꺼냅니다 (Stub은 동기로 끝나 짧은 대기로 충분)

private extension XCTestCase {

    func awaitSuccess<T>(_ single: Single<T>, file: StaticString = #filePath, line: UInt = #line) -> T? {
        var value: T?
        let done = expectation(description: "success")
        let disposable = single.subscribe(
            onSuccess: { value = $0; done.fulfill() },
            onFailure: { XCTFail("성공해야 하는데 실패: \($0)", file: file, line: line); done.fulfill() }
        )
        wait(for: [done], timeout: 1)
        disposable.dispose()
        return value
    }

    func awaitFailure<T>(_ single: Single<T>, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        var error: Error?
        let done = expectation(description: "failure")
        let disposable = single.subscribe(
            onSuccess: { _ in XCTFail("실패해야 하는데 성공", file: file, line: line); done.fulfill() },
            onFailure: { error = $0; done.fulfill() }
        )
        wait(for: [done], timeout: 1)
        disposable.dispose()
        return error
    }
}
