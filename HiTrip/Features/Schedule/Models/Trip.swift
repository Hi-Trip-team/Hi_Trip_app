import Foundation

// MARK: - Trip
/// 여행 일정 모델 — "최근 일정" 리스트의 카드 단위
///
/// 하나의 Trip = 하나의 여행 (예: "한라산 등반", "서울 타워 방문")
/// Trip 안에 여러 TripTodo와 TripEvent가 포함됨
///
/// 피그마 화면1의 카드에 표시되는 정보:
/// - 썸네일 이미지
/// - 날짜
/// - 제목
/// - 위치

struct Trip: Identifiable, Codable, Equatable {

    let id: UUID
    var title: String
    var date: Date
    var location: String
    var thumbnailName: String   // 로컬 이미지 이름 또는 URL
    var memberAvatars: [String] // 멤버 아바타 이미지 이름 목록
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        location: String = "",
        thumbnailName: String = "",
        memberAvatars: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.thumbnailName = thumbnailName
        self.memberAvatars = memberAvatars
        self.createdAt = createdAt
    }
}
