import XCTest
import RxSwift
@testable import HiTrip

// MARK: - SignUpUseCaseTests
/// SignUpUseCase의 비즈니스 로직 검증
///
/// 테스트 대상:
/// 1. 닉네임 중복 확인 — 빈 값, 2자 미만, 사용 가능, 중복
/// 2. 회원가입 실행 — 각 필드별 검증 에러, 비밀번호 불일치, 성공

final class SignUpUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: SignUpUseCase!
    private var mockRepository: MockAuthRepository!
    private var disposeBag: DisposeBag!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        sut = SignUpUseCase(repository: mockRepository)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - 닉네임 중복 확인 테스트

    /// 빈 닉네임 → emptyNickname 에러
    func test_빈_닉네임_checkNickname_에러() {
        let expectation = expectation(description: "빈 닉네임 에러")

        sut.checkNickname("")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .emptyNickname)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        // 검증 단계에서 걸러졌으므로 Repository 호출 없음
        XCTAssertEqual(mockRepository.checkNicknameCallCount, 0)
    }

    /// 1자 닉네임 → nicknameTooShort 에러
    func test_1자_닉네임_checkNickname_에러() {
        let expectation = expectation(description: "닉네임 너무 짧음")

        sut.checkNickname("가")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .nicknameTooShort)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.checkNicknameCallCount, 0)
    }

    /// 유효한 닉네임 + 사용 가능 → isAvailable true
    func test_유효한_닉네임_사용가능() {
        mockRepository.nicknameResult = .success(TestFixtures.nicknameAvailable)

        let expectation = expectation(description: "닉네임 사용 가능")

        sut.checkNickname("여행자")
            .subscribe(
                onSuccess: { response in
                    XCTAssertTrue(response.isAvailable)
                    expectation.fulfill()
                },
                onFailure: { error in
                    XCTFail("실패하면 안 됨: \(error)")
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.checkNicknameCallCount, 1)
    }

    /// 유효한 닉네임 + 중복 → isAvailable false
    func test_유효한_닉네임_중복() {
        mockRepository.nicknameResult = .success(TestFixtures.nicknameDuplicate)

        let expectation = expectation(description: "닉네임 중복")

        sut.checkNickname("여행자")
            .subscribe(
                onSuccess: { response in
                    XCTAssertFalse(response.isAvailable)
                    expectation.fulfill()
                },
                onFailure: { _ in XCTFail("실패하면 안 됨") }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - 회원가입 실행 테스트

    /// 빈 닉네임으로 가입 시도 → emptyNickname 에러
    func test_빈_닉네임으로_가입시_에러() {
        let expectation = expectation(description: "빈 닉네임 가입 에러")

        sut.execute(nickname: "", userId: "user1", password: "123456", passwordConfirm: "123456")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .emptyNickname)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.signUpCallCount, 0)
    }

    /// 빈 아이디로 가입 시도 → emptyUserId 에러
    func test_빈_아이디로_가입시_에러() {
        let expectation = expectation(description: "빈 아이디 가입 에러")

        sut.execute(nickname: "여행자", userId: "", password: "123456", passwordConfirm: "123456")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .emptyUserId)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.signUpCallCount, 0)
    }

    /// 3자 아이디 → userIdTooShort 에러
    func test_짧은_아이디로_가입시_에러() {
        let expectation = expectation(description: "짧은 아이디 에러")

        sut.execute(nickname: "여행자", userId: "abc", password: "123456", passwordConfirm: "123456")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .userIdTooShort)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.signUpCallCount, 0)
    }

    /// 빈 비밀번호 → emptyPassword 에러
    func test_빈_비밀번호로_가입시_에러() {
        let expectation = expectation(description: "빈 비밀번호 에러")

        sut.execute(nickname: "여행자", userId: "user1", password: "", passwordConfirm: "")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .emptyPassword)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.signUpCallCount, 0)
    }

    /// 5자 비밀번호 → passwordTooShort 에러
    func test_짧은_비밀번호로_가입시_에러() {
        let expectation = expectation(description: "짧은 비밀번호 에러")

        sut.execute(nickname: "여행자", userId: "user1", password: "12345", passwordConfirm: "12345")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .passwordTooShort)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.signUpCallCount, 0)
    }

    /// 비밀번호 불일치 → passwordMismatch 에러
    func test_비밀번호_불일치시_에러() {
        let expectation = expectation(description: "비밀번호 불일치")

        sut.execute(nickname: "여행자", userId: "user1", password: "123456", passwordConfirm: "654321")
            .subscribe(
                onSuccess: { _ in XCTFail("성공하면 안 됨") },
                onFailure: { error in
                    XCTAssertEqual(error as? SignUpError, .passwordMismatch)
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.signUpCallCount, 0)
    }

    /// 모든 입력 유효 → 회원가입 성공
    func test_유효한_입력시_가입_성공() {
        mockRepository.signUpResult = .success(TestFixtures.signUpSuccess)

        let expectation = expectation(description: "가입 성공")

        sut.execute(nickname: "여행자", userId: "user1", password: "123456", passwordConfirm: "123456")
            .subscribe(
                onSuccess: { response in
                    XCTAssertEqual(response.message, "가입이 완료되었습니다.")
                    XCTAssertEqual(response.user.name, "테스트유저")
                    expectation.fulfill()
                },
                onFailure: { error in
                    XCTFail("실패하면 안 됨: \(error)")
                }
            )
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 1.0)
        // 모든 검증 통과 후 Repository가 1번 호출됨
        XCTAssertEqual(mockRepository.signUpCallCount, 1)
    }
}
