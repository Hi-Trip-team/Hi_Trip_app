import Foundation

// MARK: - TripTodo
/// 여행 할일 (체크리스트) 모델
///
/// 피그마 화면2의 체크리스트 항목
/// 섹션별로 그룹핑: "오늘 일정 준비", "여행 준비 & 관리"

struct TripTodo: Identifiable, Codable, Equatable {

    let id: UUID
    var title: String
    var isCompleted: Bool
    var section: Section
    var date: Date          // 이 할일이 속한 날짜 (날짜별 필터링용)
    let tripId: UUID        // 소속 여행
    let createdAt: Date

    /// 체크리스트 섹션 구분
    enum Section: String, Codable, CaseIterable {
        case todayPrep = "오늘 일정 준비"
        case travelPrep = "여행 준비 & 관리"
    }

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        section: Section = .todayPrep,
        date: Date = Date(),
        tripId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.section = section
        self.date = date
        self.tripId = tripId
        self.createdAt = createdAt
    }
}
