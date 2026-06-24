import Foundation

// MARK: - TripTodo
/// 여행 할일 (체크리스트) 모델
///
/// 서버 체크리스트(TravelerChecklistItemDTO)에서 변환되거나
/// 로컬에서 추가한 항목으로 채워짐.
/// serverId가 있으면 PATCH /api/traveler/checklists/{id}/ 로 동기화.

struct TripTodo: Identifiable, Codable, Equatable {

    let id: UUID
    var serverId: Int?      // 서버 체크리스트 ID — PATCH 호출 시 사용, nil이면 로컬 전용
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
        serverId: Int? = nil,
        title: String,
        isCompleted: Bool = false,
        section: Section = .todayPrep,
        date: Date = Date(),
        tripId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.serverId = serverId
        self.title = title
        self.isCompleted = isCompleted
        self.section = section
        self.date = date
        self.tripId = tripId
        self.createdAt = createdAt
    }

    var isServerManaged: Bool { serverId != nil }
}
