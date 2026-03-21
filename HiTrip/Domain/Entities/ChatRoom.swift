import Foundation

// MARK: - ChatRoom
/// 채팅방 데이터 모델
///
/// 안내사 ↔ 관광객 1:1 채팅방을 나타냄
///
/// 필드 설계 기준:
/// - id: 채팅방 고유 식별자 (UUID 자동 생성)
/// - participantName: 상대방 이름 (채팅 목록에 표시)
/// - participantType: 상대방 유형 (안내사/관광객 구분용)
/// - lastMessage: 마지막 메시지 내용 (목록 미리보기)
/// - lastMessageDate: 마지막 메시지 시간 (목록 정렬용)
/// - unreadCount: 읽지 않은 메시지 수 (뱃지 표시용)
/// - createdAt: 채팅방 생성 시간
///
/// Identifiable 채택 이유:
/// - SwiftUI List/ForEach에서 각 채팅방을 구분하기 위해 필요
///
/// Codable 채택 이유:
/// - 추후 서버 JSON ↔ Swift 변환용

struct ChatRoom: Identifiable, Codable, Equatable {

    /// 고유 식별자
    let id: UUID

    /// 상대방 이름 — 채팅 목록에 표시
    /// 예: "김안내", "박관광"
    var participantName: String

    /// 상대방 유형 — "guide" 또는 "tourist"
    /// 목록에서 안내사/관광객 배지 표시에 사용
    var participantType: String

    /// 마지막 메시지 내용 — 목록 미리보기
    /// 예: "내일 9시에 만나요!"
    var lastMessage: String

    /// 마지막 메시지 시간 — 목록 정렬 기준
    var lastMessageDate: Date

    /// 읽지 않은 메시지 수 — 뱃지 숫자 표시
    var unreadCount: Int

    /// 채팅방 생성 시간
    let createdAt: Date

    /// 기본 생성자
    init(
        id: UUID = UUID(),
        participantName: String,
        participantType: String,
        lastMessage: String = "",
        lastMessageDate: Date = Date(),
        unreadCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participantName = participantName
        self.participantType = participantType
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.createdAt = createdAt
    }
}
