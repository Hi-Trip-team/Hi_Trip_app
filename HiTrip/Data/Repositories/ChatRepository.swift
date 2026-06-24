import Foundation
import RxSwift

// MARK: - ChatRepository
/// 문의 스레드 + 메시지 API 연동 구현체
///
/// GET  /api/traveler/messages/threads/                     → 스레드 목록
/// POST /api/traveler/messages/threads/                     → 스레드 생성
/// GET  /api/traveler/messages/threads/{id}/messages/       → 메시지 목록
/// POST /api/traveler/messages/threads/{id}/messages/       → 메시지 전송
///
/// ChatRoom.id(UUID) ↔ 서버 thread id(Int) 매핑은 cachedRooms로 관리.

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
        networkService.request(.travelerMessageThreads(), type: [TravelerMessageThreadDTO].self)
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
        let subject = room.threadSubject ?? room.participantName
        return networkService.request(
            .travelerMessageThreadCreate(subject: subject, body: ""),
            type: TravelerMessageThreadDTO.self
        )
        .map { [weak self] dto in
            let newRoom = dto.toChatRoom()
            self?.cachedRooms[newRoom.id] = newRoom
            return newRoom
        }
    }

    func deleteRoom(id: UUID) -> Single<Void> {
        // 서버에 DELETE 엔드포인트 없음 — 로컬 캐시에서만 제거
        cachedRooms.removeValue(forKey: id)
        return .just(())
    }

    // MARK: - Message

    func fetchMessages(chatRoomId: UUID) -> Single<[Message]> {
        guard let serverId = resolveServerId(for: chatRoomId) else {
            return .error(ChatError.roomNotFound)
        }
        let userId = keychain.getUserId() ?? ""
        let userName = keychain.getUserName() ?? "나"

        return networkService.request(
            .travelerMessages(threadId: serverId),
            type: [TravelerMessageDTO].self
        )
        .map { dtos in
            dtos
                .map { $0.toMessage(chatRoomId: chatRoomId, currentUserId: userId, currentUserName: userName) }
                .sorted { $0.sentAt < $1.sentAt }
        }
    }

    func sendMessage(message: Message) -> Single<Message> {
        guard let serverId = resolveServerId(for: message.chatRoomId) else {
            return .error(ChatError.roomNotFound)
        }
        let userId = keychain.getUserId() ?? ""
        let userName = keychain.getUserName() ?? "나"

        return networkService.request(
            .travelerMessageCreate(threadId: serverId, body: message.content),
            type: TravelerMessageDTO.self
        )
        .map { dto in
            dto.toMessage(chatRoomId: message.chatRoomId, currentUserId: userId, currentUserName: userName)
        }
    }

    func markAsRead(chatRoomId: UUID) -> Single<Void> {
        // 서버에 읽음 처리 엔드포인트 없음 — 로컬 전용 (unreadCount 초기화는 ChatViewModel에서)
        return .just(())
    }

    // MARK: - Private

    private func resolveServerId(for roomId: UUID) -> Int? {
        cachedRooms[roomId]?.serverId
    }
}
