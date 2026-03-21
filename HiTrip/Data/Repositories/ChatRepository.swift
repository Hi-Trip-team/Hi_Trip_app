import Foundation
import RxSwift

// MARK: - ChatRepository
/// 채팅 저장소 구현체 (메모리 저장)
///
/// 현재: 앱 메모리(배열)에 저장 — 앱 종료 시 데이터 사라짐
/// 나중에: WebSocket + REST API로 교체
///
/// ChatRepositoryProtocol을 구현하므로,
/// UseCase는 이 클래스의 존재를 모름 (DIP)
///
/// 저장소 구조:
/// - chatRooms: [ChatRoom] — 채팅방 목록
/// - messages: [UUID: [Message]] — 채팅방 ID별 메시지 배열 (Dictionary)
///
/// Dictionary를 쓰는 이유:
/// - 채팅방별로 메시지를 따로 관리해야 함
/// - messages[chatRoomId]로 해당 방의 메시지만 빠르게 조회 가능
/// - 배열 하나에 전부 넣으면 매번 filter해야 해서 비효율

final class ChatRepository: ChatRepositoryProtocol {

    // MARK: - 저장소

    /// 채팅방 목록
    private var chatRooms: [ChatRoom] = []

    /// 채팅방 ID → 메시지 배열 매핑
    /// 예: [roomA의 UUID: [메시지1, 메시지2], roomB의 UUID: [메시지3]]
    private var messages: [UUID: [Message]] = [:]

    // MARK: - ChatRoom CRUD

    /// 채팅방 생성
    func createRoom(room: ChatRoom) -> Single<ChatRoom> {
        return Single.create { [weak self] single in
            self?.chatRooms.append(room)
            self?.messages[room.id] = []  // 빈 메시지 배열 초기화
            single(.success(room))
            return Disposables.create()
        }
    }

    /// 전체 채팅방 조회 — 마지막 메시지 시간 기준 최신순 정렬
    func fetchAllRooms() -> Single<[ChatRoom]> {
        return Single.create { [weak self] single in
            let sorted = self?.chatRooms.sorted {
                $0.lastMessageDate > $1.lastMessageDate
            } ?? []
            single(.success(sorted))
            return Disposables.create()
        }
    }

    /// 채팅방 삭제 — 채팅방 + 해당 메시지 모두 제거
    func deleteRoom(id: UUID) -> Single<Void> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(ChatError.roomNotFound))
                return Disposables.create()
            }

            if let index = self.chatRooms.firstIndex(where: { $0.id == id }) {
                self.chatRooms.remove(at: index)
                self.messages.removeValue(forKey: id)  // 메시지도 함께 삭제
                single(.success(()))
            } else {
                single(.failure(ChatError.roomNotFound))
            }
            return Disposables.create()
        }
    }

    // MARK: - Message CRUD

    /// 메시지 전송
    /// 1. 메시지를 해당 채팅방 배열에 추가
    /// 2. 채팅방의 lastMessage, lastMessageDate 갱신
    func sendMessage(message: Message) -> Single<Message> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(ChatError.roomNotFound))
                return Disposables.create()
            }

            // 1. 메시지 저장
            if self.messages[message.chatRoomId] != nil {
                self.messages[message.chatRoomId]?.append(message)
            } else {
                self.messages[message.chatRoomId] = [message]
            }

            // 2. 채팅방 lastMessage 갱신
            if let roomIndex = self.chatRooms.firstIndex(where: { $0.id == message.chatRoomId }) {
                self.chatRooms[roomIndex].lastMessage = message.content
                self.chatRooms[roomIndex].lastMessageDate = message.sentAt
            }

            single(.success(message))
            return Disposables.create()
        }
    }

    /// 특정 채팅방의 메시지 조회 — 시간순 정렬 (오래된 순)
    func fetchMessages(chatRoomId: UUID) -> Single<[Message]> {
        return Single.create { [weak self] single in
            let roomMessages = self?.messages[chatRoomId] ?? []
            let sorted = roomMessages.sorted { $0.sentAt < $1.sentAt }
            single(.success(sorted))
            return Disposables.create()
        }
    }

    /// 읽음 처리 — 해당 채팅방의 모든 메시지를 읽음으로 + unreadCount 초기화
    func markAsRead(chatRoomId: UUID) -> Single<Void> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.success(()))
                return Disposables.create()
            }

            // 메시지 읽음 처리
            if var roomMessages = self.messages[chatRoomId] {
                for i in 0..<roomMessages.count {
                    roomMessages[i].isRead = true
                }
                self.messages[chatRoomId] = roomMessages
            }

            // 채팅방 unreadCount 초기화
            if let roomIndex = self.chatRooms.firstIndex(where: { $0.id == chatRoomId }) {
                self.chatRooms[roomIndex].unreadCount = 0
            }

            single(.success(()))
            return Disposables.create()
        }
    }
}
