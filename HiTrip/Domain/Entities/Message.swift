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

    /// 전송 상태 — 서버에서 받은 메시지는 항상 .sent
    var sendStatus: MessageSendStatus

    /// 첨부 파일 — 사진·동영상·음성
    var attachments: [MessageAttachment]

    init(
        id: UUID = UUID(),
        serverId: Int? = nil,
        senderType: String? = nil,
        chatRoomId: UUID,
        senderId: String,
        senderName: String,
        content: String,
        sentAt: Date = Date(),
        sendStatus: MessageSendStatus = .sent,
        attachments: [MessageAttachment] = []
    ) {
        self.id = id
        self.serverId = serverId
        self.senderType = senderType
        self.chatRoomId = chatRoomId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.sentAt = sentAt
        self.sendStatus = sendStatus
        self.attachments = attachments
    }

    /// 내가 보낸 메시지인지
    ///
    /// senderType(서버의 sender_role)으로 판단하지 않습니다. 서버는 "tourist"/"staff"를
    /// 주는데 앱에서 어느 쪽이 "나"인지는 로그인 역할에 따라 달라지기 때문입니다.
    /// Repository가 내 메시지의 senderId를 현재 사용자 id로 넣어주므로 그것으로 판단합니다.
    func isMyMessage(currentUserId: String) -> Bool {
        senderId == currentUserId
    }

    /// ChatBubbleView 표시용 래퍼로 변환
    func toChatMessage(currentUserId: String) -> ChatMessage {
        ChatMessage(
            id: id.uuidString,
            content: content,
            isMine: isMyMessage(currentUserId: currentUserId),
            sendStatus: sendStatus,
            sentAt: sentAt,
            attachments: attachments
        )
    }
}

// MARK: - 첨부

/// 서버 ChatAttachment — 사진·동영상·음성
struct MessageAttachment: Identifiable, Codable, Equatable {
    let id: Int
    /// "photo" | "video" | "audio"
    let mediaType: String
    let downloadUrl: String?
    let originalName: String?
    /// 음성 길이(초)
    let duration: Int?

    var isPhoto: Bool { mediaType == "photo" }
    var isVideo: Bool { mediaType == "video" }
    var isAudio: Bool { mediaType == "audio" }
}

// MARK: - 전송 상태

/// 서버가 per-message 읽음 여부를 주지 않아 "읽음"은 표현하지 않습니다.
/// 앱이 확실히 아는 것은 전송 성공 여부뿐입니다.
enum MessageSendStatus: String, Codable {
    /// 서버 응답 대기 중
    case sending
    /// 서버에 저장됨
    case sent
    /// 전송 실패 — 탭하면 재전송
    case failed
}

// MARK: - ChatMessage (표시용 모델)

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isMine: Bool
    var sendStatus: MessageSendStatus
    let sentAt: Date
    var attachments: [MessageAttachment] = []

    var sendFailed: Bool { sendStatus == .failed }
    var isSending: Bool { sendStatus == .sending }

    var timeString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f.string(from: sentAt)
    }
}
