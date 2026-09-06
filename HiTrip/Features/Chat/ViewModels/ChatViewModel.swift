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

    /// 입력 상한 (자)
    let messageLimit = 1_000

    /// 상한을 넘겼는지 — 넘기면 전송을 막습니다.
    /// 입력 중에 잘라내면 한국어·일본어·중국어 조합이 깨지므로 자르지 않습니다.
    var isOverMessageLimit: Bool { messageText.count > messageLimit }

    /// 첨부 업로드 중 — 진행 표시
    @Published private(set) var isUploading = false

    /// 첨부 관련 안내 (용량 초과·권한 등)
    @Published var toast: String?

    /// 오프라인 상태 — 상단 배너
    @Published private(set) var isOffline = false

    /// 파일당 최대 용량 (서버 제한과 동일)
    let attachmentSizeLimit = 50 * 1024 * 1024

    /// 과거 메시지 커서 — nil이면 더 불러올 게 없습니다
    @Published private(set) var olderCursor: Int?
    @Published private(set) var isLoadingOlder = false
    var hasOlderMessages: Bool { olderCursor != nil }

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

    /// 오프라인일 때 쌓아 두는 전송 대기 큐 — 재연결되면 순서대로 보냅니다
    private var pendingQueue: [(message: Message, attachmentIds: [Int])] = []

    init(chatUseCase: ChatUseCase) {
        self.chatUseCase = chatUseCase
        // Keychain에서 현재 로그인 유저 정보 가져오기
        let keychain = KeychainManager.shared
        self.currentUserId = keychain.getUserId() ?? "guest"
        self.currentUserName = keychain.getUserName() ?? keychain.getUserId() ?? "사용자"

        isOffline = !NetworkMonitor.shared.isConnected
        NetworkMonitor.shared.onReconnect = { [weak self] in
            self?.isOffline = false
            self?.flushPendingQueue()
        }
    }

    // MARK: - 오프라인 전송 큐

    /// 연결이 없으면 서버로 보내지 않고 큐에 담아 둡니다.
    /// 메시지는 .sending 상태로 화면에 남아 있다가 재연결 시 전송됩니다.
    private func enqueueOrDeliver(_ message: Message, attachmentIds: [Int] = []) {
        guard NetworkMonitor.shared.isConnected else {
            isOffline = true
            pendingQueue.append((message, attachmentIds))
            return
        }
        deliver(message, attachmentIds: attachmentIds)
    }

    /// 재연결되면 쌓인 것을 순서대로 내보냅니다
    private func flushPendingQueue() {
        let queued = pendingQueue
        pendingQueue.removeAll()
        queued.forEach { deliver($0.message, attachmentIds: $0.attachmentIds) }
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
                    // 가장 오래된 메시지를 다음 페이지 커서로 잡아둡니다
                    self?.olderCursor = messages.first?.serverId
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
    /// 위로 스크롤했을 때 과거 메시지 30개를 앞에 붙입니다.
    func loadOlderMessages(chatRoomId: UUID) {
        guard !isLoadingOlder, let cursor = olderCursor else { return }
        isLoadingOlder = true

        chatUseCase.fetchOlderMessages(chatRoomId: chatRoomId, before: cursor)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] page in
                    guard let self else { return }
                    self.isLoadingOlder = false
                    guard !page.messages.isEmpty else {
                        self.olderCursor = nil
                        return
                    }
                    self.messages.insert(contentsOf: page.messages, at: 0)
                    self.olderCursor = page.nextCursor
                },
                onFailure: { [weak self] _ in self?.isLoadingOlder = false }
            )
            .disposed(by: disposeBag)
    }

    /// 메시지 전송
    ///
    /// 화면에 먼저 붙이고(.sending) 결과에 따라 .sent / .failed 로 바꿉니다.
    /// 실패한 메시지를 목록에서 지우지 않아야 사용자가 재전송할 수 있습니다.
    func sendMessage(chatRoomId: UUID) {
        let text = messageText.trimmed
        guard !text.isEmpty, !isOverMessageLimit else { return }

        let pending = Message(
            chatRoomId: chatRoomId,
            senderId: currentUserId,
            senderName: currentUserName,
            content: text,
            sendStatus: .sending
        )

        errorMessage = nil
        messages.append(pending)
        messageText = ""

        enqueueOrDeliver(pending)
    }

    // MARK: - 첨부

    /// 사진·동영상·음성을 올리고 첨부 메시지로 보냅니다.
    /// - Parameter duration: 음성일 때 초 단위 길이 (서버 최대 180초)
    func sendAttachment(
        chatRoomId: UUID,
        data: Data,
        mediaType: String,
        fileName: String,
        mimeType: String,
        duration: Int? = nil
    ) {
        guard data.count <= attachmentSizeLimit else {
            toast = "50MB 이하 파일만 첨부할 수 있어요"
            return
        }
        guard NetworkMonitor.shared.isConnected else {
            // 업로드는 연결이 있어야 시작할 수 있습니다
            isOffline = true
            toast = "연결되면 다시 시도해주세요"
            return
        }

        isUploading = true
        chatUseCase.uploadAttachment(
            chatRoomId: chatRoomId, data: data, mediaType: mediaType,
            fileName: fileName, mimeType: mimeType, duration: duration
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] attachmentId in
                guard let self else { return }
                self.isUploading = false

                let pending = Message(
                    chatRoomId: chatRoomId,
                    senderId: self.currentUserId,
                    senderName: self.currentUserName,
                    content: "",
                    sendStatus: .sending,
                    attachments: [MessageAttachment(
                        id: attachmentId, mediaType: mediaType,
                        downloadUrl: nil, originalName: fileName, duration: duration
                    )]
                )
                self.messages.append(pending)
                self.enqueueOrDeliver(pending, attachmentIds: [attachmentId])
            },
            onFailure: { [weak self] _ in
                self?.isUploading = false
                self?.toast = "첨부하지 못했어요"
            }
        )
        .disposed(by: disposeBag)
    }

    /// 실패한 메시지 재전송
    ///
    /// Message.id를 client_message_id로 그대로 다시 보내므로,
    /// 서버에 이미 저장됐다면 중복 생성되지 않습니다.
    func retry(messageId: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }),
              messages[idx].sendStatus == .failed else { return }

        messages[idx].sendStatus = .sending
        let attachmentIds = messages[idx].attachments.map(\.id)
        enqueueOrDeliver(messages[idx], attachmentIds: attachmentIds)
    }

    /// 실패한 메시지 삭제 (로컬)
    func discard(messageId: UUID) {
        messages.removeAll { $0.id == messageId && $0.sendStatus == .failed }
    }

    private func deliver(_ message: Message, attachmentIds: [Int] = []) {
        chatUseCase.sendMessage(message: message, attachmentIds: attachmentIds)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] saved in
                    guard let self,
                          let idx = self.messages.firstIndex(where: { $0.id == message.id }) else { return }
                    // 로컬 id는 그대로 둡니다. 이 값이 client_message_id로 나가므로
                    // 바꾸면 재전송 시 멱등키가 달라져 메시지가 중복될 수 있습니다.
                    self.messages[idx].serverId = saved.serverId
                    self.messages[idx].sendStatus = .sent
                },
                onFailure: { [weak self] error in
                    guard let self,
                          let idx = self.messages.firstIndex(where: { $0.id == message.id }) else { return }
                    // 연결이 끊긴 것이면 실패로 두지 않고 큐에 넣어 재연결 때 보냅니다
                    if !NetworkMonitor.shared.isConnected {
                        self.isOffline = true
                        self.pendingQueue.append((message, attachmentIds))
                        return
                    }
                    self.messages[idx].sendStatus = .failed
                    self.errorMessage = error.localizedDescription
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

    /// 모든 채팅방 읽음 처리 — "모두 확인"
    ///
    /// 뱃지는 즉시 지우고, 서버에도 방마다 읽음을 보냅니다.
    /// 실패해도 다음 목록 조회 때 서버 값으로 되돌아옵니다.
    func markAllAsRead() {
        let unreadIds = chatRooms.filter { $0.unreadCount > 0 }.map(\.id)
        for i in chatRooms.indices {
            chatRooms[i].unreadCount = 0
        }
        for id in unreadIds {
            chatUseCase.markAsRead(chatRoomId: id)
                .subscribe(onSuccess: { _ in }, onFailure: { _ in })
                .disposed(by: disposeBag)
        }
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
