import Foundation

// MARK: - Message
/// 채팅 메시지 데이터 모델
///
/// 하나의 채팅 메시지가 가지는 모든 정보
///
/// 필드 설계 기준:
/// - id: 메시지 고유 식별자 (UUID)
/// - chatRoomId: 이 메시지가 속한 채팅방 ID (FK 역할)
/// - senderId: 보낸 사람 ID (누가 보냈는지)
/// - senderName: 보낸 사람 이름 (UI 표시용)
/// - content: 메시지 내용 (텍스트)
/// - sentAt: 보낸 시간 (정렬 + 시간 표시)
/// - isRead: 읽음 여부 (읽음 표시용)
///
/// isMyMessage 계산:
/// - senderId와 현재 로그인 유저 ID를 비교해서
///   내 메시지인지 상대 메시지인지 구분 → 말풍선 좌우 배치에 사용

struct Message: Identifiable, Codable, Equatable {

    /// 고유 식별자
    let id: UUID

    /// 소속 채팅방 ID — 어떤 채팅방의 메시지인지
    let chatRoomId: UUID

    /// 발신자 ID — 누가 보냈는지 식별
    let senderId: String

    /// 발신자 이름 — 메시지 UI에 표시
    let senderName: String

    /// 메시지 내용 (텍스트)
    var content: String

    /// 발신 시간 — 시간순 정렬 + "오후 3:42" 같은 표시
    let sentAt: Date

    /// 읽음 여부 — true면 상대가 읽었다는 뜻
    var isRead: Bool

    /// 기본 생성자
    init(
        id: UUID = UUID(),
        chatRoomId: UUID,
        senderId: String,
        senderName: String,
        content: String,
        sentAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.chatRoomId = chatRoomId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.sentAt = sentAt
        self.isRead = isRead
    }
}
