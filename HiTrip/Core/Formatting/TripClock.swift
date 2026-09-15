import Foundation

// MARK: - TripClock
/// 여행 시각 판정 — **여행지 시간대 + 기기 시계**로 계산합니다
///
/// 서버는 사실(여행 기간·일정 날짜와 시각)만 주고, 시간에 따라 바뀌는 판정은 여기서 합니다.
/// - 오늘이 몇 일차인지 · 여행 전/중/후 · 진행률 · 지금 시각(분)
///
/// 서버의 today_day_number는 UTC 날짜로 계산돼 한국 0시~9시에는 하루 전 일차가 옵니다.
/// 응답 순간의 값으로 고정되기도 해서, 시각 판정은 화면을 그릴 때 이 유틸로 계산합니다.
/// (다른 사람에게 영향을 주는 판정 — 이탈 알림·안전 상태·겹침 경고 — 는 계속 서버 값을 씁니다)
///
/// 시간대: 서버 여행 정보의 `timezone`(IANA, 예: "Asia/Seoul")을 쓰고, 없으면 한국 시간대입니다.
/// 해외 여행도 서버가 시간대를 주면 코드 수정 없이 맞습니다.

struct TripClock {

    /// 서버가 시간대를 주지 않을 때 — 현재 상품은 모두 국내
    static let defaultTimeZone = TimeZone(identifier: "Asia/Seoul")!

    enum Phase: Equatable {
        case before, during, finished
    }

    let timeZone: TimeZone
    /// 기준 시각 — 테스트에서 원하는 시각을 넣을 수 있습니다
    let now: Date

    private let calendar: Calendar
    /// 시작일 0시 (여행지 기준)
    private let startDay: Date
    /// 종료일 0시 (여행지 기준)
    private let lastDay: Date

    /// - Parameters:
    ///   - startDate/endDate: "yyyy-MM-dd" (서버 여행 기간)
    ///   - timeZoneID: 서버 여행 시간대 — 없거나 알 수 없는 값이면 한국 시간대
    init?(startDate: String, endDate: String, timeZoneID: String? = nil, now: Date = Date()) {
        let zone = timeZoneID.flatMap(TimeZone.init(identifier:)) ?? Self.defaultTimeZone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone

        guard let start = Self.day(startDate, in: calendar),
              let last = Self.day(endDate, in: calendar),
              start <= last else { return nil }

        self.timeZone = zone
        self.now = now
        self.calendar = calendar
        self.startDay = start
        self.lastDay = last
    }

    // MARK: - 날짜

    /// 오늘 0시 (여행지 기준)
    private var today: Date { calendar.startOfDay(for: now) }

    /// 여행 전체 일수
    var totalDays: Int { days(from: startDay, to: lastDay) + 1 }

    /// 오늘이 몇 일차인지 — 여행 기간 밖이면 nil
    var todayDayNumber: Int? {
        let day = days(from: startDay, to: today) + 1
        return (1...totalDays).contains(day) ? day : nil
    }

    var phase: Phase {
        if today < startDay { return .before }
        if today > lastDay { return .finished }
        return .during
    }

    /// 출발까지 남은 일수 — 여행이 시작됐으면 0
    var daysUntilStart: Int { max(days(from: today, to: startDay), 0) }

    /// 여행 종료까지 남은 일수 — 마지막 날 0, 끝났으면 음수
    var remainingDays: Int { days(from: today, to: lastDay) }

    /// 여행 기간(시작일 0시 ~ 종료일 24시) 중 지금 시각의 비율 — 시작 전 0, 종료 후 1
    var progress: Double {
        guard let end = calendar.date(byAdding: .day, value: 1, to: lastDay) else { return 0 }
        let total = end.timeIntervalSince(startDay)
        guard total > 0 else { return 0 }
        return min(max(now.timeIntervalSince(startDay) / total, 0), 1)
    }

    // MARK: - 시각

    /// 지금 시각 — 여행지 기준 자정부터 분 (일정 "HH:mm:ss"와 비교)
    var minutesNow: Int {
        let parts = calendar.dateComponents([.hour, .minute], from: now)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// 일정 순서 비교용 "지금" 위치 — 시작 전은 0일차, 종료 후는 마지막 다음 날
    var nowDayNumber: Int {
        switch phase {
        case .before:   return 0
        case .during:   return todayDayNumber ?? 0
        case .finished: return totalDays + 1
        }
    }

    /// (일차, 시작 시각)이 지금보다 뒤인지 — 다음 일정 고르기
    func isAfterNow(dayNumber: Int, startTime: String) -> Bool {
        if dayNumber != nowDayNumber { return dayNumber > nowDayNumber }
        return (AppDate.minutes(startTime) ?? 0) > minutesNow
    }

    // MARK: - Private

    private func days(from a: Date, to b: Date) -> Int {
        calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// "yyyy-MM-dd" → 그 날짜 0시 (주어진 달력의 시간대)
    private static func day(_ ymd: String, in calendar: Calendar) -> Date? {
        let parts = ymd.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
