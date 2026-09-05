import Foundation
import RxSwift

// MARK: - ChatRepository
/// 채팅 API 연동 구현체
///
/// GET  /api/v1/chat/rooms/                             → 채팅방 목록
/// POST /api/v1/chat/rooms/direct/                      → 1:1 채팅방 열기
/// GET  /api/v1/chat/rooms/{room_id}/messages/          → 메시지 이력
/// POST /api/v1/chat/rooms/{room_id}/messages/          → 메시지 전송
/// POST /api/v1/chat/rooms/{room_id}/read/              → 읽음 처리
///
/// ChatRoom.id(UUID) ↔ 서버 room id(Int) 매핑은 cachedRooms로 관리.

final class ChatRepository: ChatRepositoryProtocol {

    // MARK: - Dependencies

    private let networkService: NetworkService
    private let keychain: KeychainManager

    /// UUID → ChatRoom 캐시 (serverId 조회용)
    private var cachedRooms: [UUID: ChatRoom] = [:]

    /// 방별 마지막으로 본 서버 메시지 id — 읽음 처리에 필요
    private var lastSeenMessageId: [UUID: Int] = [:]

    // MARK: - Init

    init(networkService: NetworkService = .shared, keychain: KeychainManager = .shared) {
        self.networkService = networkService
        self.keychain = keychain
    }

    // MARK: - ChatRoom

    func fetchAllRooms() -> Single<[ChatRoom]> {
        networkService.request(.chatRooms(), type: [ChatRoomV1DTO].self)
            .map { [weak self] dtos in
                let rooms = dtos.map { dto -> ChatRoom in
                    let room = dto.toChatRoom()
                    self?.cachedRooms[room.id] = room

                    // 목록의 마지막 메시지 id를 읽음 기준점으로 삼습니다.
                    // 방을 열지 않아도 "모두 확인"으로 읽음 처리할 수 있어야 하는데,
                    // 서버 읽음 API가 message_id를 필수로 받기 때문입니다.
                    let rawLatestId = dto.latestMessage?["id"]?.value
                    if let latestId = rawLatestId as? Int ?? (rawLatestId as? Double).map(Int.init) {
                        let prev = self?.lastSeenMessageId[room.id] ?? 0
                        self?.lastSeenMessageId[room.id] = max(prev, latestId)
                    }
                    return room
                }
                return rooms.sorted { $0.lastMessageDate > $1.lastMessageDate }
            }
    }

    func createRoom(room: ChatRoom) -> Single<ChatRoom> {
        var body: [String: Any] = [:]
        if let sid = room.serverId { body["tourist_id"] = sid }
        return networkService.request(.chatRoomDirect(body: body), type: ChatRoomV1DTO.self)
            .map { [weak self] dto in
                let newRoom = dto.toChatRoom()
                self?.cachedRooms[newRoom.id] = newRoom
                return newRoom
            }
    }

    func deleteRoom(id: UUID) -> Single<Void> {
        cachedRooms.removeValue(forKey: id)
        return .just(())
    }

    // MARK: - Message

    func fetchMessages(chatRoomId: UUID) -> Single<[Message]> {
        fetchMessages(chatRoomId: chatRoomId, before: nil).map(\.messages)
    }

    /// 커서 페이징 — `before`보다 id가 작은(= 더 오래된) 메시지를 불러옵니다.
    /// - Returns: 메시지와 다음 페이지 커서. `nextCursor`가 nil이면 더 없음.
    func fetchMessages(
        chatRoomId: UUID,
        before: Int?
    ) -> Single<(messages: [Message], nextCursor: Int?)> {
        guard let serverId = resolveServerId(for: chatRoomId) else {
            return .error(ChatError.roomNotFound)
        }
        let userId = keychain.getUserId() ?? ""
        let role = currentRole

        return networkService.request(
            .chatMessages(roomId: String(serverId), cursor: before.map(String.init)),
            type: ChatMessagePageDTO.self
        )
        .map { [weak self] page in
            let messages = page.results
                .filter { !$0.isDeleted }
                .map { $0.toMessage(chatRoomId: chatRoomId, currentUserId: userId, currentRole: role) }
                .sorted { $0.sentAt < $1.sentAt }

            // 읽음 처리에 쓸 기준점을 여기서 갱신 — 최신 페이지에서만 올립니다.
            if let maxId = page.results.map(\.id).max() {
                let prev = self?.lastSeenMessageId[chatRoomId] ?? 0
                self?.lastSeenMessageId[chatRoomId] = max(prev, maxId)
            }
            return (messages, page.nextCursor)
        }
    }

    func sendMessage(message: Message) -> Single<Message> {
        guard let serverId = resolveServerId(for: message.chatRoomId) else {
            return .error(ChatError.roomNotFound)
        }
        let userId = keychain.getUserId() ?? ""
        let role = currentRole

        // client_message_id는 서버 필수값이자 멱등키입니다.
        // 재전송 시 같은 값을 유지해야 메시지가 중복 생성되지 않으므로
        // Message.id(로컬 UUID)를 그대로 씁니다.
        let body: [String: Any] = [
            "client_message_id": message.id.uuidString,
            "message_type": "text",
            "body": message.content,
        ]

        return networkService.request(
            .chatMessageSend(roomId: String(serverId), body: body),
            type: ChatMessageV1DTO.self
        )
        .map { dto in
            dto.toMessage(chatRoomId: message.chatRoomId, currentUserId: userId, currentRole: role)
        }
    }

    /// 읽음 처리 — 서버가 `message_id`(마지막으로 읽은 메시지)를 필수로 요구합니다.
    func markAsRead(chatRoomId: UUID) -> Single<Void> {
        guard let serverId = resolveServerId(for: chatRoomId),
              let lastMessageId = lastSeenMessageId[chatRoomId] else {
            return .just(())
        }
        return networkService.request(
            .chatRoomRead(id: String(serverId), body: ["message_id": lastMessageId]),
            type: ChatReadResponseDTO.self
        )
        .map { _ in () }
        .catch { _ in .just(()) }
    }

    // MARK: - Private

    private func resolveServerId(for roomId: UUID) -> Int? {
        cachedRooms[roomId]?.serverId
    }

    /// 내 역할 — 말풍선 좌/우 판정에 사용. 관리자 앱이면 "staff".
    private var currentRole: String {
        keychain.getUserType() == "tourist" ? "tourist" : "staff"
    }
}

// MARK: - ChatReadResponseDTO

private struct ChatReadResponseDTO: Decodable {
    let roomId: Int?
    let messageId: Int?
}
