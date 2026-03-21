import Foundation
import RxSwift

// MARK: - ChatRepositoryProtocol
/// 채팅 데이터 접근 인터페이스 (Domain 레이어)
///
/// 채팅방 관리 + 메시지 CRUD를 Protocol로 정의
/// - 실제 구현은 Data 레이어의 ChatRepository에서 담당
/// - 추후 WebSocket 서버 연동 시 WebSocketChatRepository로 교체
///
/// Schedule과 동일한 DIP 패턴:
/// - Domain은 Protocol만 알고, 구현체는 모름
/// - UseCase가 이 Protocol에 의존

protocol ChatRepositoryProtocol {

    // MARK: - ChatRoom (채팅방)

    /// 채팅방 생성 — 새로운 1:1 대화방 개설
    func createRoom(room: ChatRoom) -> Single<ChatRoom>

    /// 전체 채팅방 조회 — 채팅 목록 화면용
    func fetchAllRooms() -> Single<[ChatRoom]>

    /// 채팅방 삭제 — 대화방 나가기
    func deleteRoom(id: UUID) -> Single<Void>

    // MARK: - Message (메시지)

    /// 메시지 전송 — 새 메시지 저장 + 채팅방 lastMessage 갱신
    func sendMessage(message: Message) -> Single<Message>

    /// 메시지 조회 — 특정 채팅방의 모든 메시지 (시간순)
    func fetchMessages(chatRoomId: UUID) -> Single<[Message]>

    /// 메시지 읽음 처리 — 특정 채팅방의 모든 메시지를 읽음으로
    func markAsRead(chatRoomId: UUID) -> Single<Void>
}
