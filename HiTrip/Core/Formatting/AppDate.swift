import Foundation

// MARK: - AppDate
/// 날짜·시간 변환 모음
///
/// 서버 형식
/// - 날짜: "yyyy-MM-dd"
/// - 시각: "HH:mm:ss" (일정 시작·종료)
/// - 일시: ISO8601 (소수초가 있을 수도 없을 수도 있음)
///
/// DateFormatter는 만들 때 비용이 커서 패턴별로 한 번만 만들어 재사용합니다.
/// 화면(메인 스레드)에서만 호출합니다.

enum AppDate {

    // MARK: - 파싱

    /// "yyyy-MM-dd" → Date
    static func day(_ string: String?) -> Date? {
        guard let string else { return nil }
        return formatter("yyyy-MM-dd", locale: posix).date(from: string)
    }

    /// ISO8601 → Date (소수초 유무 모두 허용)
    static func iso(_ string: String?) -> Date? {
        guard let string else { return nil }
        return isoFractional.date(from: string) ?? isoPlain.date(from: string)
    }

    // MARK: - 서버 시각 "HH:mm:ss"

    /// "09:30:00" → "09:30"
    static func hhmm(_ time: String) -> String {
        time.split(separator: ":").prefix(2).joined(separator: ":")
    }

    /// "09:30:00" → 570 (자정부터 분)
    static func minutes(_ time: String) -> Int? {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    /// 지금 시각 — 자정부터 분
    static var minutesNow: Int {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (now.hour ?? 0) * 60 + (now.minute ?? 0)
    }

    // MARK: - Date → 문자열

    /// 한국어 표기 — 예: "yyyy.MM.dd", "MM.dd HH:mm"
    static func string(_ date: Date, _ pattern: String) -> String {
        formatter(pattern, locale: korean).string(from: date)
    }

    /// ISO8601 문자열을 바로 표기로 — 해석하지 못하면 ""
    static func string(iso raw: String?, _ pattern: String) -> String {
        Self.iso(raw).map { string($0, pattern) } ?? ""
    }

    /// 서버로 보낼 "HH:mm"
    static func hhmm(_ date: Date) -> String {
        formatter("HH:mm", locale: posix).string(from: date)
    }

    // MARK: - 오늘 날짜의 특정 시각 (시간 선택기 기본값)

    static func today(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    /// "18:30" → 오늘 18:30. 해석하지 못하면 fallbackHour 정각
    static func today(hhmm text: String, fallbackHour: Int = 0) -> Date {
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return today(hour: fallbackHour) }
        return today(hour: parts[0], minute: parts[1])
    }

    // MARK: - 채팅

    /// 채팅 목록 시각 — 오늘 "HH:mm" · 어제 "어제" · 일주일 안 "E HH:mm"(선택) · 그 이전 "M.d"
    static func chatListTime(_ date: Date, showsWeekday: Bool) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return string(date, "HH:mm") }
        if cal.isDateInYesterday(date) { return "어제" }
        if showsWeekday, let days = cal.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            return string(date, "E HH:mm")
        }
        return string(date, "M.d")
    }

    /// 채팅방 날짜 구분선 — "오늘" · "어제" · 올해 "M월 d일 EEEE" · 그 이전 "yyyy년 M월 d일"
    static func chatDaySeparator(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "오늘" }
        if cal.isDateInYesterday(date) { return "어제" }
        let sameYear = cal.isDate(date, equalTo: Date(), toGranularity: .year)
        return string(date, sameYear ? "M월 d일 EEEE" : "yyyy년 M월 d일")
    }

    // MARK: - 캐시

    private static let posix = Locale(identifier: "en_US_POSIX")
    private static let korean = Locale(identifier: "ko_KR")
    private static var cache: [String: DateFormatter] = [:]

    private static func formatter(_ pattern: String, locale: Locale) -> DateFormatter {
        let key = "\(locale.identifier)|\(pattern)"
        if let cached = cache[key] { return cached }
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = pattern
        cache[key] = f
        return f
    }

    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain = ISO8601DateFormatter()
}
