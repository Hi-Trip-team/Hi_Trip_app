import Foundation
import SwiftData

// MARK: - PersonalTodo
/// 여행객이 직접 추가하는 개인 할일 (SwiftData — 로컬 저장)
///
/// 가이드가 관리하는 TripTodo와 별도로 존재.
/// tripServerId: 어느 여행 패키지에 속하는지 구분 (서버 tripId)

@Model
final class PersonalTodo {

    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var tripId: UUID             // TripPackage.id 기준

    init(title: String, tripId: UUID) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.tripId = tripId
    }
}
