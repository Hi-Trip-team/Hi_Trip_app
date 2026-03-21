import Foundation
import RxSwift

// MARK: - ChatViewModel
/// 채팅 화면의 ViewModel
///
/// ScheduleViewModel과 동일한 패턴:
/// - @Published로 View와 양방향 바인딩
/// - UseCase를 통해 비즈니스 로직 실행
/// - View는 ViewModel의 @Published만 관찰
///
/// 2가지 화면을 모두 관리:
/// - ChatListView: 채팅방 목록 (chatRooms)
/// - ChatRoomView: 메시지 목록 (messages) + 메시지 전송 (messageText)

final class ChatViewModel: ObservableObject {

    // MARK: - 채팅방 목록 상태 (ChatListView용)

    /// 채팅방 목록 — ChatListView에서 ForEach로 표시
    @Published var chatRooms: [ChatRoom] = []

    // MARK: - 메시지 상태 (ChatRoomView용)

    /// 현재 채팅방의 메시지 목록 — ChatRoomView에서 표시
    @Published var messages: [Message] = []

    /// 메시지 입력 — TextField와 바인딩
    @Published var messageText: String = ""

    // MARK: - 채팅방 생성 폼

    /// 상대방 이름 입력
    @Published var participantName: String = ""

    /// 상대방 유형 선택 ("guide" 또는 "tourist")
    @Published var participantType: String = "guide"

    // MARK: - UI 상태

    /// 로딩 중 여부
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 작업 완료 여부 (채팅방 생성 성공 시 true)
    @Published var isCompleted: Bool = false

    // MARK: - Dependencies

    private let chatUseCase: ChatUseCase
    private let disposeBag = DisposeBag()

    /// 현재 로그인한 사용자 ID — 내 메시지 / 상대 메시지 구분용
    private(set) var currentUserId: String

    /// 현재 로그인한 사용자 이름
    private(set) var currentUserName: String

    init(chatUseCase: ChatUseCase) {
        self.chatUseCase = chatUseCase
        // Keychain에서 현재 로그인 유저 정보 가져오기
        self.currentUserId = KeychainManager.shared.getUserId() ?? "me"
        self.currentUserName = KeychainManager.shared.getUserId() ?? "나"
    }

    // MARK: - ChatRoom (채팅방)

    /// 전체 채팅방 목록 불러오기
    /// - ChatListView 진입 시 (.onAppear) 호출
    func fetchChatRooms() {
        isLoading = true

        chatUseCase.fetchAllRooms()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] rooms in
                    self?.isLoading = false
                    self?.chatRooms = rooms
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    /// 새 채팅방 생성
    func createChatRoom() {
        let newRoom = ChatRoom(
            participantName: participantName.trimmed,
            participantType: participantType
        )

        isLoading = true
        errorMessage = nil

        chatUseCase.createRoom(room: newRoom)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    self?.isCompleted = true
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    /// 채팅방 삭제 (나가기)
    func deleteChatRoom(id: UUID) {
        isLoading = true
        errorMessage = nil

        chatUseCase.deleteRoom(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    self?.chatRooms.removeAll { $0.id == id }
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Message (메시지)

    /// 특정 채팅방의 메시지 목록 불러오기
    /// - ChatRoomView 진입 시 호출
    func fetchMessages(chatRoomId: UUID) {
        isLoading = true

        chatUseCase.fetchMessages(chatRoomId: chatRoomId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] messages in
                    self?.isLoading = false
                    self?.messages = messages
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    /// 메시지 전송
    /// - 입력창의 텍스트로 Message 생성 후 전송
    func sendMessage(chatRoomId: UUID) {
        let newMessage = Message(
            chatRoomId: chatRoomId,
            senderId: currentUserId,
            senderName: currentUserName,
            content: messageText.trimmed
        )

        errorMessage = nil

        chatUseCase.sendMessage(message: newMessage)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] message in
                    self?.messages.append(message)
                    self?.messageText = ""  // 입력창 비우기
                },
                onFailure: { [weak self] error in
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    /// 메시지 읽음 처리
    func markAsRead(chatRoomId: UUID) {
        chatUseCase.markAsRead(chatRoomId: chatRoomId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    // 채팅방 목록의 unreadCount도 로컬에서 초기화
                    if let index = self?.chatRooms.firstIndex(where: { $0.id == chatRoomId }) {
                        self?.chatRooms[index].unreadCount = 0
                    }
                },
                onFailure: { _ in }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 내 메시지인지 확인

    /// 발신자 ID와 현재 유저 ID 비교 → 말풍선 좌우 배치에 사용
    func isMyMessage(_ message: Message) -> Bool {
        return message.senderId == currentUserId
    }

    // MARK: - 폼 관련 헬퍼

    /// 채팅방 생성 폼 초기화
    func resetForm() {
        participantName = ""
        participantType = "guide"
        isCompleted = false
        errorMessage = nil
    }

    /// 메시지 입력이 유효한지 (전송 버튼 활성화용)
    var isMessageValid: Bool {
        !messageText.trimmed.isEmpty
    }
}
