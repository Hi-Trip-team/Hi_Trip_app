import Foundation

// MARK: - TripPackage
/// 여행사가 등록하는 여행 패키지 (홈 대시보드 데이터 원본)
///
/// 구조: 여행사 직원 → 그룹(여행객 그룹) 생성 → 일정/공지/장소 등록
///       → 그룹에 속한 모든 여행객이 앱에서 수신
///
/// 역할 분담:
/// - 여행사가 등록하는 것: 공지사항, 공식 일정, 추천 장소, 번역, 미션
/// - 여행객 개인이 관리하는 것: 할 일(TripTodo), 개인 메모
/// - 여행사 등록은 웹 SaaS에서 처리 → 앱은 수신/조회만 함
///
/// 하나의 TripPackage가 홈 화면의 모든 섹션 데이터를 제공:
/// - 여행 기본 정보 (이름, 기간, 목적지)
/// - 참여자 정보
/// - 공지사항 (대표 공지 → 홈 노출, 전체 → 리스트 화면)
/// - 오늘의 미션
/// - 오늘의 일정 (여행사가 등록한 공식 타임라인)
/// - 추천 장소
/// - 번역 모음

struct TripPackage: Identifiable, Codable, Equatable {

    let id: UUID
    var name: String               // "제주 힐링여행"
    var startDate: Date            // 여행 시작일
    var endDate: Date              // 여행 종료일
    var destination: String        // "제주"

    // 참여자
    var totalParticipants: Int     // 정원
    var currentParticipants: Int   // 현재 참여 인원

    // 날씨 (서버에서 갱신하거나 여행사가 세팅)
    var weatherDescription: String // "맑음 22°C"

    // 공지사항 목록
    var notices: [TripNotice]

    // 미션 목록
    var missions: [TripMission]

    // 공식 일정 (여행사가 등록한 타임라인)
    var officialSchedules: [TripOfficialSchedule]

    // 추천 장소
    var nearbySpots: [TripNearbySpot]

    // 번역 모음
    var translations: [TripTranslation]

    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        destination: String,
        totalParticipants: Int = 20,
        currentParticipants: Int = 0,
        weatherDescription: String = "",
        notices: [TripNotice] = [],
        missions: [TripMission] = [],
        officialSchedules: [TripOfficialSchedule] = [],
        nearbySpots: [TripNearbySpot] = [],
        translations: [TripTranslation] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.destination = destination
        self.totalParticipants = totalParticipants
        self.currentParticipants = currentParticipants
        self.weatherDescription = weatherDescription
        self.notices = notices
        self.missions = missions
        self.officialSchedules = officialSchedules
        self.nearbySpots = nearbySpots
        self.translations = translations
        self.createdAt = createdAt
    }

    // MARK: - Computed

    /// 현재 여행 일차 (1-based)
    func currentDay(from today: Date = Date()) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let now = cal.startOfDay(for: today)
        let diff = cal.dateComponents([.day], from: start, to: now).day ?? 0
        return max(1, diff + 1)
    }

    /// 총 여행 일수
    var totalDays: Int {
        let cal = Calendar.current
        let diff = cal.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, diff + 1)
    }

    /// 남은 일수
    func daysRemaining(from today: Date = Date()) -> Int {
        let cal = Calendar.current
        let now = cal.startOfDay(for: today)
        let end = cal.startOfDay(for: endDate)
        let diff = cal.dateComponents([.day], from: now, to: end).day ?? 0
        return max(0, diff)
    }

    /// 진행률 (0.0 ~ 1.0)
    func progressRate(from today: Date = Date()) -> Double {
        guard totalDays > 0 else { return 0 }
        let day = currentDay(from: today)
        return min(1.0, Double(day) / Double(totalDays))
    }
}

// MARK: - TripNotice
/// 여행사 공지사항
///
/// 여행사가 그룹(여행객 그룹)에 등록하는 공지.
/// isRepresentative = true인 공지만 홈 메인에 노출되고,
/// 공지 리스트 화면에서는 전체 목록을 볼 수 있다.

struct TripNotice: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String          // "집합 안내"
    var content: String        // "오전 9시 로비 집합 — 우산 꼭 챙겨주세요!"
    var date: Date             // 공지 등록 날짜
    var isImportant: Bool      // 중요 표시
    var isRepresentative: Bool // true면 홈 메인에 대표 공지로 노출

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String,
        date: Date,
        isImportant: Bool = false,
        isRepresentative: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.isImportant = isImportant
        self.isRepresentative = isRepresentative
    }
}

// MARK: - TripMission
/// 오늘의 미션 (여행사가 날짜별로 등록)

struct TripMission: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String        // "제주 명소 3곳 방문하기"
    var date: Date             // 미션 날짜
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        content: String,
        date: Date,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.content = content
        self.date = date
        self.isCompleted = isCompleted
    }
}

// MARK: - TripOfficialSchedule
/// 여행사 공식 일정 (홈 화면 "오늘의 일정" 섹션)
///
/// TripEvent(개인 일정)과 구분 — 이건 여행사가 등록한 공식 타임라인

struct TripOfficialSchedule: Identifiable, Codable, Equatable {
    let id: UUID
    var emoji: String          // "🏠", "🌅"
    var title: String          // "숙소로 이동"
    var startTime: Date        // 시작 시간
    var endTime: Date          // 종료 시간
    var date: Date             // 해당 날짜

    init(
        id: UUID = UUID(),
        emoji: String,
        title: String,
        startTime: Date,
        endTime: Date,
        date: Date
    ) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.date = date
    }

    /// 표시용 시간 문자열 "15:00 – 16:00"
    var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }
}

// MARK: - TripNearbySpot
/// 추천 장소 (여행사가 등록)

struct TripNearbySpot: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String           // "협재 해수욕장"
    var distance: String       // "도보 8분"
    var category: String       // "beach", "leaf", "mountain", "water"
    var imageURL: String?      // 이미지 URL (nil이면 placeholder)

    init(
        id: UUID = UUID(),
        name: String,
        distance: String,
        category: String,
        imageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.distance = distance
        self.category = category
        self.imageURL = imageURL
    }
}

// MARK: - TripTranslation
/// 여행 필수 번역 문장

struct TripTranslation: Identifiable, Codable, Equatable {
    let id: UUID
    var original: String       // "화장실 어디예요?"
    var translated: String     // "Where is the restroom?"
    var category: String       // "기본", "식당", "교통" 등

    init(
        id: UUID = UUID(),
        original: String,
        translated: String,
        category: String = "기본"
    ) {
        self.id = id
        self.original = original
        self.translated = translated
        self.category = category
    }
}
