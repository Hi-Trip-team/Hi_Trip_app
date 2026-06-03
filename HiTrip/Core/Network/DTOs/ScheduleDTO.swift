import Foundation

// MARK: - ScheduleDTO
/// 백엔드 GET /api/trips/:trip_pk/schedules/ 응답 모델
///
/// 여행사가 등록한 공식 일정을 나타냄.
/// 앱 내부에서는 TripOfficialSchedule 또는 Schedule로 변환하여 사용.

struct ScheduleDTO: Decodable, Identifiable {
    let id: Int
    let trip: Int?
    let place: Int?                 // place ID (FK)
    let dayNumber: Int?             // 일차 (1, 2, 3...)
    let startTime: String?          // "07:00:00"
    let endTime: String?            // "09:00:00"
    let durationMinutes: Int?       // 120
    let transport: String?          // "자가용", "도보", "전용버스"
    let mainContent: String?        // "탑승 수속 및 출국"
    let meetingPoint: String?       // "T1 3층 출발홀"
    let budget: Int?
    let order: Int?
    let placeName: String?          // "인천국제공항 T1"
    let durationDisplay: String?    // "2시간"
    let createdAt: String?
    let updatedAt: String?

    // 하위 호환용 (기존 코드에서 title/day/notes 참조)
    var title: String { placeName ?? mainContent ?? "일정" }
    var day: Int? { dayNumber }
    var notes: String? { mainContent }
    var timeBlock: String? {
        guard let startTime, let hour = Int(startTime.prefix(2)) else { return nil }
        if hour < 12 { return "morning" }
        if hour < 18 { return "afternoon" }
        return "evening"
    }
}

// MARK: - ScheduleDTO → TripOfficialSchedule 변환

extension ScheduleDTO {

    /// DTO → 앱 내부 TripOfficialSchedule 변환
    func toOfficialSchedule(for date: Date = Date()) -> TripOfficialSchedule {
        let start = parseTime(startTime, on: date)
        let end = parseTime(endTime, on: date)

        // 이동수단 → emoji 매핑
        let emoji: String
        switch transport {
        case "도보":     emoji = "🚶"
        case "전용버스":  emoji = "🚌"
        case "자가용":   emoji = "🚗"
        case "공항버스":  emoji = "✈️"
        case "택시":     emoji = "🚕"
        default:
            // timeBlock fallback
            switch timeBlock {
            case "morning":   emoji = "🌅"
            case "afternoon": emoji = "☀️"
            case "evening":   emoji = "🌙"
            default:          emoji = "📍"
            }
        }

        // 제목: 장소명 + 메인 콘텐츠
        let displayTitle: String
        if let placeName, let content = mainContent {
            displayTitle = "\(placeName) — \(content)"
        } else {
            displayTitle = placeName ?? mainContent ?? title
        }

        return TripOfficialSchedule(
            emoji: emoji,
            title: displayTitle,
            startTime: start,
            endTime: end,
            date: date
        )
    }

    /// DTO → 앱 내부 Schedule 변환
    func toSchedule() -> Schedule {
        Schedule(
            title: placeName ?? mainContent ?? title,
            description: mainContent ?? "",
            date: Date(),
            location: meetingPoint ?? ""
        )
    }

    // MARK: - Private

    /// 시간 문자열을 특정 날짜에 결합
    private func parseTime(_ timeString: String?, on date: Date) -> Date {
        guard let timeString else { return date }
        let calendar = Calendar.current

        // "HH:mm:ss" 형태 시도
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        if parts.count >= 2 {
            return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date) ?? date
        }

        // ISO 형태 시도
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let parsed = iso.date(from: timeString) {
            return parsed
        }

        return date
    }
}

// MARK: - ScheduleCreateRequest
/// POST /api/trips/:trip_pk/schedules/ 요청 바디

struct ScheduleCreateRequest: Encodable {
    let title: String
    let day: Int
    let timeBlock: String           // "morning", "afternoon", "evening"
    let startTime: String           // "HH:mm:ss"
    let endTime: String
    let place: Int?
    let notes: String?
    let order: Int?
}
