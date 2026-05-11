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
/// Mock 데이터 설계:
/// - 여행사가 그룹 생성 시 자동으로 2개 채팅방 개설:
///   1. 단체톡방 (해당 여행 그룹 전원)
///   2. 담당 가이드 개인톡

final class ChatRepository: ChatRepositoryProtocol {

    // MARK: - 저장소

    /// 채팅방 목록
    private var chatRooms: [ChatRoom] = []

    /// 채팅방 ID → 메시지 배열 매핑
    private var messages: [UUID: [Message]] = [:]

    // MARK: - Init (Mock 시드 데이터)

    init() {
        seedMockData()
    }

    /// Mock 채팅방 + 메시지 시드
    private func seedMockData() {
        let cal = Calendar.current
        let now = Date()

        // --- 1) 단체톡방 ---
        let groupRoomId = UUID()
        let groupRoom = ChatRoom(
            id: groupRoomId,
            participantName: "제주 힐링여행 단체톡방",
            participantType: "group",
            isGroupChat: true,
            lastMessage: "내일 일정 변경 공지드립니다",
            lastMessageDate: cal.date(byAdding: .minute, value: -15, to: now) ?? now,
            unreadCount: 3,
            isOnline: false,
            createdAt: cal.date(byAdding: .day, value: -5, to: now) ?? now
        )

        let groupMessages: [Message] = [
            Message(
                chatRoomId: groupRoomId,
                senderId: "guide_lee",
                senderName: "이연세 가이드",
                content: "안녕하세요! 제주 힐링여행 가이드 이연세입니다 😊",
                sentAt: cal.date(byAdding: .hour, value: -3, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: groupRoomId,
                senderId: "guide_lee",
                senderName: "이연세 가이드",
                content: "오늘 일정 안내드립니다. 9시 호텔 로비 집합입니다!",
                sentAt: cal.date(byAdding: .hour, value: -2, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: groupRoomId,
                senderId: "tourist_kim",
                senderName: "김민수",
                content: "네 알겠습니다!",
                sentAt: cal.date(byAdding: .minute, value: -90, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: groupRoomId,
                senderId: "guest",
                senderName: "사용자",
                content: "감사합니다 가이드님",
                sentAt: cal.date(byAdding: .minute, value: -60, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: groupRoomId,
                senderId: "guide_lee",
                senderName: "이연세 가이드",
                content: "내일 일정 변경 공지드립니다",
                sentAt: cal.date(byAdding: .minute, value: -15, to: now) ?? now,
                isRead: false
            )
        ]

        // --- 2) 가이드 개인톡 ---
        let guideRoomId = UUID()
        let guideRoom = ChatRoom(
            id: guideRoomId,
            participantName: "이연세 가이드",
            participantType: "guide",
            isGroupChat: false,
            lastMessage: "혹시 알레르기 있으신 음식 있으실까요?",
            lastMessageDate: cal.date(byAdding: .minute, value: -30, to: now) ?? now,
            unreadCount: 1,
            isOnline: true,
            createdAt: cal.date(byAdding: .day, value: -5, to: now) ?? now
        )

        let guideMessages: [Message] = [
            Message(
                chatRoomId: guideRoomId,
                senderId: "guide_lee",
                senderName: "이연세 가이드",
                content: "안녕하세요! 담당 가이드 이연세입니다.",
                sentAt: cal.date(byAdding: .hour, value: -4, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: guideRoomId,
                senderId: "guide_lee",
                senderName: "이연세 가이드",
                content: "여행 중 궁금하신 점이나 불편한 사항이 있으시면 언제든 연락주세요 😊",
                sentAt: cal.date(byAdding: .hour, value: -4, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: guideRoomId,
                senderId: "guest",
                senderName: "사용자",
                content: "네 감사합니다! 내일 점심 장소는 어디인가요?",
                sentAt: cal.date(byAdding: .hour, value: -1, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: guideRoomId,
                senderId: "guide_lee",
                senderName: "이연세 가이드",
                content: "내일 점심은 제주 흑돼지 맛집으로 예약해두었습니다!",
                sentAt: cal.date(byAdding: .minute, value: -45, to: now) ?? now,
                isRead: true
            ),
            Message(
                chatRoomId: guideRoomId,
                senderId: "guide_lee",
                senderName: "이연세 가이드",
                content: "혹시 알레르기 있으신 음식 있으실까요?",
                sentAt: cal.date(byAdding: .minute, value: -30, to: now) ?? now,
                isRead: false
            )
        ]

        // 저장
        chatRooms = [groupRoom, guideRoom]
        messages = [
            groupRoomId: groupMessages,
            guideRoomId: guideMessages
        ]
    }

    // MARK: - ChatRoom CRUD

    /// 채팅방 생성
    func createRoom(room: ChatRoom) -> Single<ChatRoom> {
        return Single.create { [weak self] single in
            self?.chatRooms.append(room)
            self?.messages[room.id] = []
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
                self.messages.removeValue(forKey: id)
                single(.success(()))
            } else {
                single(.failure(ChatError.roomNotFound))
            }
            return Disposables.create()
        }
    }

    // MARK: - Message CRUD

    /// 메시지 전송
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

            if var roomMessages = self.messages[chatRoomId] {
                for i in 0..<roomMessages.count {
                    roomMessages[i].isRead = true
                }
                self.messages[chatRoomId] = roomMessages
            }

            if let roomIndex = self.chatRooms.firstIndex(where: { $0.id == chatRoomId }) {
                self.chatRooms[roomIndex].unreadCount = 0
            }

            single(.success(()))
            return Disposables.create()
        }
    }
}
