import Foundation
import SwiftUI

// MARK: - TripEvent
/// 여행 캘린더 이벤트 모델
///
/// 피그마 화면3의 캘린더에 표시되는 이벤트
/// - 월간 캘린더의 날짜 아래 색상 도트로 표시
/// - 하단 "오늘의 일정" 타임라인에 시간대별 표시

struct TripEvent: Identifiable, Codable, Equatable {

    let id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var category: Category
    let tripId: UUID        // 소속 여행
    let createdAt: Date

    /// 이벤트 카테고리 (캘린더 도트 색상 결정)
    /// 피그마 기준: 여행지(네이비), 목록(라이트블루), 일정(옐로), 기타(핑크)
    enum Category: String, Codable, CaseIterable {
        case destination = "여행지"
        case list = "목록"
        case schedule = "일정"
        case etc = "기타"

        /// 캘린더 도트 색상
        var color: Color {
            switch self {
            case .destination: return Color(hex: "062360")  // 네이비
            case .list:        return Color(hex: "90ACF7")  // 라이트블루
            case .schedule:    return Color(hex: "F5C842")  // 옐로
            case .etc:         return Color(hex: "F5A0B5")  // 핑크
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        endTime: Date,
        category: Category = .schedule,
        tripId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
        self.tripId = tripId
        self.createdAt = createdAt
    }
}
