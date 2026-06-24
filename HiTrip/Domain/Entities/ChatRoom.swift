import Foundation

// MARK: - ChatRoom
/// 채팅(문의) 스레드 도메인 모델
///
/// 서버 TravelerMessageThreadDTO에서 변환되거나 새 스레드 생성 시 사용.
/// serverId가 있으면 서버 스레드와 매핑됨.

struct ChatRoom: Identifiable, Codable, Equatable, Hashable {

    /// SwiftUI 식별자 (로컬 UUID)
    let id: UUID

    /// 서버 스레드 ID — API 호출 시 사용 (nil이면 아직 서버에 생성 안 됨)
    var serverId: Int?

    /// 스레드 제목 (문의 주제)
    var threadSubject: String?

    /// 스레드 상태 "open" | "closed"
    var status: String?

    /// 목록에 표시되는 이름 (subject or 상대방 이름)
    var participantName: String

    /// 채팅방 유형 — "staff"(담당자) 또는 "group"
    var participantType: String

    /// 단체톡방 여부
    var isGroupChat: Bool

    /// 마지막 메시지 내용
    var lastMessage: String

    /// 마지막 메시지 시간
    var lastMessageDate: Date

    /// 읽지 않은 메시지 수
    var unreadCount: Int

    /// 온라인 상태 (참고용)
    var isOnline: Bool

    let createdAt: Date

    init(
        id: UUID = UUID(),
        serverId: Int? = nil,
        threadSubject: String? = nil,
        status: String? = nil,
        participantName: String,
        participantType: String = "staff",
        isGroupChat: Bool = false,
        lastMessage: String = "",
        lastMessageDate: Date = Date(),
        unreadCount: Int = 0,
        isOnline: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.serverId = serverId
        self.threadSubject = threadSubject
        self.status = status
        self.participantName = participantName
        self.participantType = participantType
        self.isGroupChat = isGroupChat
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.isOnline = isOnline
        self.createdAt = createdAt
    }
}
