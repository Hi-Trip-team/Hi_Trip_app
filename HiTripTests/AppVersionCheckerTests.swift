import XCTest
@testable import HiTrip

// MARK: - AppVersionCheckerTests
/// 강제 업데이트 판정의 버전 비교
///
/// 앱 버전 "1.0"과 서버 최소 버전 "1.0.0"처럼 자리 수가 다른 값이 들어와도
/// 최신 사용자에게 업데이트 팝업이 뜨면 안 됩니다.

final class AppVersionCheckerTests: XCTestCase {

    func test_자리_수가_달라도_같은_버전이면_업데이트_아님() {
        XCTAssertFalse(AppVersionChecker.isVersion("1.0", lowerThan: "1.0.0"))
        XCTAssertFalse(AppVersionChecker.isVersion("1.0.0", lowerThan: "1.0"))
        XCTAssertFalse(AppVersionChecker.isVersion("1", lowerThan: "1.0.0"))
    }

    func test_낮은_버전은_업데이트_필요() {
        XCTAssertTrue(AppVersionChecker.isVersion("1.0.0", lowerThan: "1.0.1"))
        XCTAssertTrue(AppVersionChecker.isVersion("1.9.0", lowerThan: "1.10.0"))
        XCTAssertTrue(AppVersionChecker.isVersion("1.0", lowerThan: "2.0"))
    }

    func test_높은_버전은_업데이트_아님() {
        XCTAssertFalse(AppVersionChecker.isVersion("1.10.0", lowerThan: "1.9.0"))
        XCTAssertFalse(AppVersionChecker.isVersion("2.0.0", lowerThan: "1.99.99"))
        XCTAssertFalse(AppVersionChecker.isVersion("1.0.1", lowerThan: "1.0.0"))
    }
}
