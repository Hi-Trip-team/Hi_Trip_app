import XCTest
@testable import HiTrip

// MARK: - TripClockTests
/// 여행 시각 판정 — 기기 시간대와 상관없이 여행지 시간대로 계산되는지
///
/// 2026-09-15 ~ 09-19 (5일) 경주 여행 기준

final class TripClockTests: XCTestCase {

    private func clock(now iso: String, timeZone: String? = "Asia/Seoul") -> TripClock {
        let now = ISO8601DateFormatter().date(from: iso)!
        return TripClock(startDate: "2026-09-15", endDate: "2026-09-19", timeZoneID: timeZone, now: now)!
    }

    // MARK: - 새벽 버그 재현

    /// 한국 09-16 04:02 = UTC 09-15 19:02 — 서버(UTC)는 1일차를 줬지만 여행지 기준 2일차
    func test_한국_새벽에도_한국_날짜로_2일차() {
        let c = clock(now: "2026-09-15T19:02:00Z")

        XCTAssertEqual(c.todayDayNumber, 2)
        XCTAssertEqual(c.minutesNow, 4 * 60 + 2)
        XCTAssertEqual(c.phase, .during)
        XCTAssertEqual(c.remainingDays, 3)
    }

    func test_시간대가_없으면_한국_시간대로() {
        let c = clock(now: "2026-09-15T19:02:00Z", timeZone: nil)

        XCTAssertEqual(c.timeZone.identifier, "Asia/Seoul")
        XCTAssertEqual(c.todayDayNumber, 2)
    }

    func test_알수없는_시간대면_한국_시간대로() {
        XCTAssertEqual(clock(now: "2026-09-15T19:02:00Z", timeZone: "Mars/Base").timeZone.identifier, "Asia/Seoul")
    }

    /// 해외 여행 — 베트남(UTC+7)이면 같은 순간이 09-16 02:02
    func test_해외_여행은_그_나라_시간대로() {
        let c = clock(now: "2026-09-15T19:02:00Z", timeZone: "Asia/Ho_Chi_Minh")

        XCTAssertEqual(c.todayDayNumber, 2)
        XCTAssertEqual(c.minutesNow, 2 * 60 + 2)
    }

    // MARK: - 여행 단계

    func test_출발_전() {
        let c = clock(now: "2026-09-14T12:00:00+09:00")

        XCTAssertEqual(c.phase, .before)
        XCTAssertNil(c.todayDayNumber)
        XCTAssertEqual(c.daysUntilStart, 1)
        XCTAssertEqual(c.progress, 0)
    }

    func test_마지막_날() {
        let c = clock(now: "2026-09-19T23:59:00+09:00")

        XCTAssertEqual(c.todayDayNumber, 5)
        XCTAssertEqual(c.remainingDays, 0)
    }

    func test_종료_후() {
        let c = clock(now: "2026-09-20T00:01:00+09:00")

        XCTAssertEqual(c.phase, .finished)
        XCTAssertNil(c.todayDayNumber)
        XCTAssertEqual(c.progress, 1)
        XCTAssertEqual(c.remainingDays, -1)
    }

    // MARK: - 진행률

    /// 5일 중 정확히 이틀 지남 → 40%
    func test_진행률은_전체_기간_대비_지금_시각() {
        XCTAssertEqual(clock(now: "2026-09-17T00:00:00+09:00").progress, 0.4, accuracy: 0.0001)
    }

    // MARK: - 다음 일정 판정

    func test_지금_이후_일정_판정() {
        let c = clock(now: "2026-09-16T10:00:00+09:00")   // 2일차 10:00

        XCTAssertFalse(c.isAfterNow(dayNumber: 2, startTime: "09:00:00"))
        XCTAssertTrue(c.isAfterNow(dayNumber: 2, startTime: "14:00:00"))
        XCTAssertTrue(c.isAfterNow(dayNumber: 3, startTime: "09:00:00"))
        XCTAssertFalse(c.isAfterNow(dayNumber: 1, startTime: "20:00:00"))
    }

    // MARK: - 잘못된 입력

    func test_날짜를_해석할_수_없으면_nil() {
        XCTAssertNil(TripClock(startDate: "2026/09/15", endDate: "2026-09-19"))
        XCTAssertNil(TripClock(startDate: "2026-09-19", endDate: "2026-09-15"))
    }
}
