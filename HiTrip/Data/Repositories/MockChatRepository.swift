import Foundation
import RxSwift

// MARK: - MockChatRepository
/// 서버 없이 채팅 화면을 확인하기 위한 목 구현체
///
/// 채팅만 목이 없어 .mock 환경에서도 실서버로 붙었고, 토큰이 없으면 항상 빈 화면이 됐습니다.
/// 다른 화면과 같은 기준으로 맞추기 위해 추가했습니다.
///
/// 전송은 성공을 흉내 내되, 본문이 "실패"(또는 "fail")로 시작하면 오류를 돌려줍니다.
/// 전송 실패 UI와 재전송을 서버 없이 확인하기 위한 장치입니다.

final class MockChatRepository: ChatRepositoryProtocol {

    private static let guideRoomId = UUID()
    private static let groupRoomId = UUID()

    /// 내 메시지 판정 기준 — ChatViewModel이 Keychain에서 읽는 값과 같아야 합니다.
    /// 목 환경에서는 로그인을 거치지 않아 "guest"가 됩니다.
    private static var myId: String { KeychainManager.shared.getUserId() ?? "guest" }

    private static var rooms: [ChatRoom] = [
        ChatRoom(
            id: groupRoomId,
            serverId: 1,
            participantName: "📌 여행 단체톡방",
            participantType: "trip_group",
            isGroupChat: true,
            lastMessage: "오늘 저녁 집합 시간 안내드립니다",
            lastMessageDate: Date().addingTimeInterval(-1800),
            unreadCount: 3
        ),
        ChatRoom(
            id: guideRoomId,
            serverId: 2,
            participantName: "투어 가이드 김안내",
            participantType: "direct",
            isGroupChat: false,
            lastMessage: "안녕하세요! 오늘 체크인은 15시부터 가능합니다.",
            lastMessageDate: Date().addingTimeInterval(-600),
            unreadCount: 1
        ),
    ]

    private static var messages: [UUID: [Message]] = makeMessages()

    private static func makeMessages() -> [UUID: [Message]] {
        let myId = KeychainManager.shared.getUserId() ?? "guest"
        return [
        guideRoomId: [
            Message(
                serverId: 101, senderType: "staff", chatRoomId: guideRoomId,
                senderId: "staff_2", senderName: "김안내",
                content: "안녕하세요! 오늘 체크인은 15시부터 가능합니다.",
                sentAt: Date().addingTimeInterval(-86_400 - 3600)
            ),
            Message(
                serverId: 102, senderType: "tourist", chatRoomId: guideRoomId,
                senderId: myId, senderName: "나",
                content: "네, 감사합니다!",
                sentAt: Date().addingTimeInterval(-86_400 - 3000)
            ),
            Message(
                serverId: 103, senderType: "tourist", chatRoomId: guideRoomId,
                senderId: myId, senderName: "나",
                content: "주차도 가능한가요? 2박 예정입니다.",
                sentAt: Date().addingTimeInterval(-3600)
            ),
            Message(
                serverId: 104, senderType: "staff", chatRoomId: guideRoomId,
                senderId: "staff_2", senderName: "김안내",
                content: "네, 호텔 지하 주차장 이용하시면 됩니다.",
                sentAt: Date().addingTimeInterval(-600)
            ),
        ],
        groupRoomId: [
            Message(
                serverId: 201, senderType: "staff", chatRoomId: groupRoomId,
                senderId: "staff_2", senderName: "김안내",
                content: "오늘 저녁 집합 시간 안내드립니다. 18:00 호텔 1층 로비입니다.",
                sentAt: Date().addingTimeInterval(-1800)
            ),
        ],
        ]
    }

    private static var nextServerId = 900

    // MARK: - Rooms

    func fetchAllRooms() -> Single<[ChatRoom]> {
        .just(Self.rooms.sorted { $0.lastMessageDate > $1.lastMessageDate })
    }

    func createRoom(room: ChatRoom) -> Single<ChatRoom> {
        Self.rooms.append(room)
        return .just(room)
    }

    func deleteRoom(id: UUID) -> Single<Void> {
        Self.rooms.removeAll { $0.id == id }
        Self.messages[id] = nil
        return .just(())
    }

    // MARK: - Messages

    func fetchMessages(chatRoomId: UUID) -> Single<[Message]> {
        .just((Self.messages[chatRoomId] ?? []).sorted { $0.sentAt < $1.sentAt })
    }

    func sendMessage(message: Message) -> Single<Message> {
        // 전송 실패 화면을 확인할 수 있게 남겨둔 통로
        if message.content.hasPrefix("실패") || message.content.lowercased().hasPrefix("fail") {
            return .error(HiTripError.networkFailure("목 전송 실패"))
        }

        var saved = message
        saved.serverId = Self.nextServerId
        saved.sendStatus = .sent
        Self.nextServerId += 1

        Self.messages[message.chatRoomId, default: []].append(saved)

        if let idx = Self.rooms.firstIndex(where: { $0.id == message.chatRoomId }) {
            Self.rooms[idx].lastMessage = saved.content
            Self.rooms[idx].lastMessageDate = saved.sentAt
        }
        return .just(saved)
    }

    func markAsRead(chatRoomId: UUID) -> Single<Void> {
        if let idx = Self.rooms.firstIndex(where: { $0.id == chatRoomId }) {
            Self.rooms[idx].unreadCount = 0
        }
        return .just(())
    }
}
