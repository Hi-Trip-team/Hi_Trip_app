import Foundation

// MARK: - TripTodo
/// 여행 체크리스트 아이템
///
/// 서버 GET /api/traveler/checklists/ 에서 로드.
/// 토글(완료 체크)만 허용 — PATCH /api/traveler/checklists/{id}/
/// 여행객 앱에서 직접 추가/수정/삭제 불가 (여행사에서 관리).

struct TripTodo: Identifiable, Codable, Equatable {

    let id: UUID
    let serverId: Int?          // PATCH 호출 시 사용
    var title: String
    var subtitle: String?       // 서버 description 필드
    var isCompleted: Bool
    var displayOrder: Int       // 서버 정렬 순서
    let tripId: UUID

    var isServerManaged: Bool { serverId != nil }

    init(
        id: UUID = UUID(),
        serverId: Int? = nil,
        title: String,
        subtitle: String? = nil,
        isCompleted: Bool = false,
        displayOrder: Int = 0,
        tripId: UUID
    ) {
        self.id = id
        self.serverId = serverId
        self.title = title
        self.subtitle = subtitle
        self.isCompleted = isCompleted
        self.displayOrder = displayOrder
        self.tripId = tripId
    }
}
