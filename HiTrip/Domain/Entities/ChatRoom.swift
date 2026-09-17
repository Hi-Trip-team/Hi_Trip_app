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

    /// 연결된 여행 ID — 안내사 "진행중" 필터, 신고·차단에 씁니다
    var tripId: Int?

    /// 1:1 방 상대 관광객 번호 — 신고·차단 대상
    var peerTouristId: Int?

    /// 단체방 참여자(관광객) — 번호와 이름. 메시지를 보낸 사람을 신고할 때 씁니다
    var peerTourists: [ChatPeerTourist] = []

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
        tripId: Int? = nil,
        peerTouristId: Int? = nil,
        peerTourists: [ChatPeerTourist] = [],
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
        self.tripId = tripId
        self.peerTouristId = peerTouristId
        self.peerTourists = peerTourists
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.isOnline = isOnline
        self.createdAt = createdAt
    }
}

// MARK: - 단체방 참여자
/// 신고·차단은 관광객 번호(tourist_id)로 하는데, 메시지에는 사용자 번호만 있어
/// 보낸 사람 이름으로 이 목록에서 찾습니다.
struct ChatPeerTourist: Codable, Equatable, Hashable, Identifiable {
    let id: Int
    let name: String
}
