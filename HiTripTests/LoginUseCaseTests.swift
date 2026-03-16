import XCTest
import RxSwift
@testable import HiTrip

// MARK: - LoginUseCaseTests
/// LoginUseCase의 비즈니스 로직 검증
///
/// 테스트 대상:
/// 1. 빈 ID 입력 시 emptyId 에러
/// 2. 공백만 있는 ID 입력 시 emptyId 에러
/// 3. 빈 비밀번호 입력 시 emptyPassword 에러
/// 4. 유효한 입력 시 로그인 성공
/// 5. 서버 에러 시 에러 전달
/// 6. 자동 로그인 확인 (토큰 유/무)
///
/// 면접 포인트:
/// "테스트 코드를 왜 작성하셨나요?"
/// → "UseCase의 입력 검증 로직이 올바르게 동작하는지 자동으로 검증합니다.
///    기능 추가나 리팩토링 후에도 기존 로직이 깨지지 않았음을 보장할 수 있습니다."

final class LoginUseCaseTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 (System Under Test)
    private var sut: LoginUseCase!
    /// 가짜 Repository
    private var mockRepository: MockAuthRepository!
    /// RxSwift 구독 해제용
    private var disposeBag: DisposeBag!

    // MARK: - Setup / Teardown

    /// 각 테스트 메서드 실행 전에 호출
    /// - 매번 새로운 Mock + UseCase를 생성 → 테스트 간 상태 격리
    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        sut = LoginUseCase(repository: mockRepository)
        disposeBag = DisposeBag()
    }

    /// 각 테스트 메서드 실행 후에 호출
    /// - 메모리 해제로 테스트 간 간섭 방지
    override func tearDown() {
        sut = nil
        mockRepository = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - 입력 검증 테스트

    /// 빈 ID → emptyId 에러
    func test_빈_아이디_입력시_emptyId_에러() {
        // given: Mock 설정 불필요 (검증 단계에서 걸러짐)
        let expectation = expectation(description: "emptyId 에러 발생")

        // when: 빈 ID로 로그인 시도
        sut.execute(id: "", password: "990101")
            .subscribe(
                onSuccess: { _ in
                    XCTFail("성공하면 안 됨")
                },
                onFailure: { error in
                    // then: emptyId 에러인지 확인
                    XCTAssertTrue(error is LoginError)
                    XCTAssertEqual(error as? LoginError, .emptyId)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)

        // Repository가 호출되지 않았는지 확인 (검증 단계에서 이미 차단)
        XCTAssertEqual(mockRepository.loginCallCount, 0)
    }

    /// 공백만 있는 ID → emptyId 에러 (.trimmed 동작 확인)
    func test_공백만_있는_아이디_입력시_emptyId_에러() {
        let expectation = expectation(description: "공백 ID 에러")

        sut.execute(id: "   ", password: "990101")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? LoginError, .emptyId)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.loginCallCount, 0)
    }

    /// 빈 비밀번호 → emptyPassword 에러
    func test_빈_비밀번호_입력시_emptyPassword_에러() {
        let expectation = expectation(description: "emptyPassword 에러")

        sut.execute(id: "홍길동", password: "")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? LoginError, .emptyPassword)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.loginCallCount, 0)
    }

    // MARK: - 로그인 성공 테스트

    /// 유효한 입력 → 로그인 성공 → UserInfo 반환
    func test_유효한_입력시_로그인_성공() {
        // given: Mock에 성공 응답 설정
        mockRepository.loginResult = .success(TestFixtures.loginSuccess)

        let expectation = expectation(description: "로그인 성공")

        // when
        sut.execute(id: "홍길동", password: "990101")
            .subscribe(
                onSuccess: { userInfo in
                    // then: UserInfo가 올바르게 반환되는지 확인
                    XCTAssertEqual(userInfo.id, "user123")
                    XCTAssertEqual(userInfo.name, "테스트유저")
                    XCTAssertEqual(userInfo.userType, .tourist)
                    expectation.fulfill()
                },
                onFailure: { error in
                    XCTFail("실패하면 안 됨: \(error)")
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)

        // Repository가 정확히 1번 호출되었는지 확인
        XCTAssertEqual(mockRepository.loginCallCount, 1)
    }

    // MARK: - 서버 에러 테스트

    /// 서버 에러 시 에러가 그대로 전달되는지 확인
    func test_서버_에러시_에러_전달() {
        // given: Mock에 실패 응답 설정
        mockRepository.loginResult = .failure(LoginError.invalidCredentials)

        let expectation = expectation(description: "서버 에러")

        // when
        sut.execute(id: "홍길동", password: "000000")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    // then
                    XCTAssertEqual(error as? LoginError, .invalidCredentials)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.loginCallCount, 1)
    }

    // MARK: - 자동 로그인 테스트

    /// 토큰이 있으면 자동 로그인 가능
    func test_토큰_있으면_자동로그인_true() {
        mockRepository.savedToken = "some-token"
        XCTAssertTrue(sut.checkAutoLogin())
    }

    /// 토큰이 없으면 자동 로그인 불가
    func test_토큰_없으면_자동로그인_false() {
        mockRepository.savedToken = nil
        XCTAssertFalse(sut.checkAutoLogin())
    }
}
