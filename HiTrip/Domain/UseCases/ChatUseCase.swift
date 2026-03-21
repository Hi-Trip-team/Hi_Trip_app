import Foundation
import RxSwift

// MARK: - ChatUseCase
/// 채팅 비즈니스 로직
///
/// 역할:
/// - 입력값 검증 (빈 메시지, 빈 참가자 이름 등)
/// - 검증 통과 시 Repository에 실제 동작 위임
///
/// ScheduleUseCase와 동일한 패턴:
/// - Protocol에만 의존 (DIP)
/// - 검증 실패 시 Repository 호출하지 않음

final class ChatUseCase {

    private let repository: ChatRepositoryProtocol

    init(repository: ChatRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - ChatRoom (채팅방)

    /// 채팅방 생성
    ///
    /// 검증: 상대방 이름이 비어있으면 에러
    /// 통과: Repository.createRoom() 호출
    func createRoom(room: ChatRoom) -> Single<ChatRoom> {
        guard !room.participantName.trimmed.isEmpty else {
            return .error(ChatError.emptyParticipantName)
        }

        return repository.createRoom(room: room)
    }

    /// 전체 채팅방 목록 조회
    /// - 검증 불필요 → 바로 Repository 호출
    func fetchAllRooms() -> Single<[ChatRoom]> {
        return repository.fetchAllRooms()
    }

    /// 채팅방 삭제 (나가기)
    /// - 검증 불필요 → 바로 Repository 호출
    func deleteRoom(id: UUID) -> Single<Void> {
        return repository.deleteRoom(id: id)
    }

    // MARK: - Message (메시지)

    /// 메시지 전송
    ///
    /// 검증: 메시지 내용이 비어있으면 에러
    /// 통과: Repository.sendMessage() 호출
    func sendMessage(message: Message) -> Single<Message> {
        guard !message.content.trimmed.isEmpty else {
            return .error(ChatError.emptyMessage)
        }

        return repository.sendMessage(message: message)
    }

    /// 특정 채팅방의 메시지 목록 조회
    /// - 검증 불필요 → 바로 Repository 호출
    func fetchMessages(chatRoomId: UUID) -> Single<[Message]> {
        return repository.fetchMessages(chatRoomId: chatRoomId)
    }

    /// 메시지 읽음 처리
    /// - 검증 불필요 → 바로 Repository 호출
    func markAsRead(chatRoomId: UUID) -> Single<Void> {
        return repository.markAsRead(chatRoomId: chatRoomId)
    }
}

// MARK: - ChatError
/// 채팅 관련 에러 정의
enum ChatError: LocalizedError, Equatable {
    /// 상대방 이름 미입력
    case emptyParticipantName
    /// 빈 메시지 전송 시도
    case emptyMessage
    /// 채팅방을 찾을 수 없음
    case roomNotFound
    /// 서버 에러
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyParticipantName:
            return "상대방 이름을 입력해주세요."
        case .emptyMessage:
            return "메시지를 입력해주세요."
        case .roomNotFound:
            return "채팅방을 찾을 수 없습니다."
        case .serverError(let msg):
            return msg
        }
    }
}
