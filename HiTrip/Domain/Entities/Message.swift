import Foundation

// MARK: - Message
/// 채팅 메시지 도메인 모델
///
/// TravelerMessageDTO에서 변환되거나 전송 직전 로컬 생성.
/// senderType: "traveler" = 내가 보낸 것, "staff" = 담당자 발신.

struct Message: Identifiable, Codable, Equatable {

    let id: UUID

    /// 서버 메시지 ID (nil이면 미전송 상태)
    var serverId: Int?

    /// "traveler" | "staff" — nil이면 로컬 전용
    var senderType: String?

    let chatRoomId: UUID
    let senderId: String
    let senderName: String
    var content: String
    let sentAt: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        serverId: Int? = nil,
        senderType: String? = nil,
        chatRoomId: UUID,
        senderId: String,
        senderName: String,
        content: String,
        sentAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.serverId = serverId
        self.senderType = senderType
        self.chatRoomId = chatRoomId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.sentAt = sentAt
        self.isRead = isRead
    }

    /// 내가 보낸 메시지인지 (traveler 타입이거나 senderType 미설정 시 senderId 비교)
    func isMyMessage(currentUserId: String) -> Bool {
        if let type = senderType { return type == "traveler" }
        return senderId == currentUserId
    }
}
