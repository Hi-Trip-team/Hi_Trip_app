import Foundation

// MARK: - Schedule
/// 일정 데이터 모델
///
/// CRUD의 기본 단위 — 하나의 "일정"이 가지는 모든 정보
///
/// 필드 설계 기준:
/// - id: 각 일정을 고유하게 식별 (UUID 자동 생성)
/// - title: 일정 제목 (필수)
/// - description: 상세 내용 (선택)
/// - date: 일정 날짜 (필수)
/// - location: 장소 (선택, Phase 4에서 KakaoMap 연동)
/// - createdAt: 생성 시간 (자동, 정렬용)
///
/// Identifiable 채택 이유:
/// - SwiftUI의 List, ForEach에서 각 항목을 구분하기 위해 필요
/// - id 프로퍼티가 있으면 SwiftUI가 자동으로 항목 추적
///
/// Codable 채택 이유:
/// - 나중에 서버 JSON ↔ Swift 변환용 (현재는 메모리 저장이지만 미리 준비)

struct Schedule: Identifiable, Codable, Equatable {

    /// 고유 식별자 — UUID로 자동 생성
    let id: UUID

    /// 일정 제목 (필수)
    /// 예: "제주도 한라산 등반", "서울 궁궐 투어"
    var title: String

    /// 일정 상세 설명 (선택)
    /// 예: "오전 9시 출발, 등산 장비 준비"
    var description: String

    /// 일정 날짜 (필수)
    var date: Date

    /// 장소 (선택)
    /// Phase 4에서 KakaoMap 좌표와 연동 예정
    var location: String

    /// 생성 시간 — 목록 정렬에 사용
    let createdAt: Date

    /// 기본 생성자
    /// - id와 createdAt은 자동 생성 (직접 지정할 필요 없음)
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        date: Date,
        location: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.location = location
        self.createdAt = createdAt
    }
}
