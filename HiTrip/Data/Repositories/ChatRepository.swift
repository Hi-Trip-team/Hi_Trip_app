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
        guard let serverId = resolveServerId(for: chatRoomId) else {
            return .error(ChatError.roomNotFound)
        }
        let userId = keychain.getUserId() ?? ""

        return networkService.request(
            .chatMessages(roomId: String(serverId)),
            type: ChatMessagePageDTO.self
        )
        .map { page in
            page.results
                .filter { !$0.isDeleted }
                .map { $0.toMessage(chatRoomId: chatRoomId, currentUserId: userId) }
                .sorted { $0.sentAt < $1.sentAt }
        }
    }

    func sendMessage(message: Message) -> Single<Message> {
        guard let serverId = resolveServerId(for: message.chatRoomId) else {
            return .error(ChatError.roomNotFound)
        }
        let userId = keychain.getUserId() ?? ""

        let body: [String: Any] = [
            "body": message.content,
            "message_type": "text"
        ]

        return networkService.request(
            .chatMessageSend(roomId: String(serverId), body: body),
            type: ChatMessageV1DTO.self
        )
        .map { dto in
            dto.toMessage(chatRoomId: message.chatRoomId, currentUserId: userId)
        }
    }

    func markAsRead(chatRoomId: UUID) -> Single<Void> {
        guard let serverId = resolveServerId(for: chatRoomId) else {
            return .just(())
        }
        return networkService.request(
            .chatRoomRead(id: String(serverId), body: [:]),
            type: ChatReadResponseDTO.self
        )
        .map { _ in () }
        .catch { _ in .just(()) }
    }

    // MARK: - Private

    private func resolveServerId(for roomId: UUID) -> Int? {
        cachedRooms[roomId]?.serverId
    }
}

// MARK: - ChatReadResponseDTO

private struct ChatReadResponseDTO: Decodable {
    let roomId: Int?
    let messageId: Int?
}
