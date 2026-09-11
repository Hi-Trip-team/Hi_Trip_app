import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - ChatRoomView
/// 채팅방 내부 화면
///
/// 피그마 0827 수정본:
/// - 헤더: 뒤로가기 / 아바타 / 이름 / 📞 전화 버튼
/// - 날짜 구분선 ("오늘")
/// - 말풍선: ChatBubbleView 컴포넌트 사용
/// - 입력창: + 버튼 / TextField / 🎤 파란 마이크 버튼

struct ChatRoomView: View {

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    let chatRoom: ChatRoom

    /// 입력창 포커스 — 대화 영역을 누르면 키보드를 내립니다
    @FocusState private var isInputFocused: Bool

    /// 전송 실패 메시지를 탭했을 때 뜨는 선택 시트
    @State private var failedMessageId: UUID?

    /// 상대 연락처 — 없으면 전화 버튼을 숨깁니다 (서버가 아직 주지 않습니다)
    var peerPhoneNumber: String?

    /// 첨부
    @State private var showAttachmentOptions = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showPermissionGuide = false

    /// 음성 녹음
    @StateObject private var recorder = VoiceRecorder()

    private var chatMessages: [ChatMessage] {
        viewModel.messages.map { $0.toChatMessage(currentUserId: viewModel.currentUserId) }
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            separator
            messageList
            separator
            inputBar
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onTapGesture { isInputFocused = false }
        .confirmationDialog("첨부", isPresented: $showAttachmentOptions, titleVisibility: .visible) {
            Button("사진·동영상") { showPhotoPicker = true }
            Button("취소", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .any(of: [.images, .videos]))
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await attach(item) }
        }
        .alert("권한이 필요해요", isPresented: $showPermissionGuide) {
            Button("설정 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("닫기", role: .cancel) { }
        } message: {
            Text("설정에서 사진·마이크 접근을 허용해주세요")
        }
        .toast($viewModel.toast, inset: 90)
        .overlay(alignment: .top) { offlineBanner }
        .confirmationDialog(
            "전송하지 못한 메시지",
            isPresented: Binding(
                get: { failedMessageId != nil },
                set: { if !$0 { failedMessageId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("재전송") {
                if let id = failedMessageId { viewModel.retry(messageId: id) }
                failedMessageId = nil
            }
            Button("삭제", role: .destructive) {
                if let id = failedMessageId { viewModel.discard(messageId: id) }
                failedMessageId = nil
            }
            Button("취소", role: .cancel) { failedMessageId = nil }
        }
        .onAppear {
            viewModel.fetchMessages(chatRoomId: chatRoom.id)
            viewModel.markAsRead(chatRoomId: chatRoom.id)
        }
    }

    /// 구분선 — Figma는 #F7F7F9 1.5pt입니다.
    /// SwiftUI 기본 Divider는 시스템 separator라 훨씬 진하게 보입니다.
    private var separator: some View {
        Rectangle()
            .fill(AppColor.surfaceMuted)
            .frame(height: 1.5)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(AppFont.title3Medium)
                    .foregroundColor(AppColor.textStrong)
                    .frame(width: 24, height: 24)
            }
            .padding(.leading, AppSpacing.sm)

            // 아바타
            Circle()
                .fill(AppColor.surface)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: chatRoom.isGroupChat ? "person.3.fill" : "person.fill")
                        .font(AppFont.icon(chatRoom.isGroupChat ? 13 : 15))
                        .foregroundColor(AppColor.textTertiary)
                )
                .padding(.leading, AppSpacing.md)

            // 이름
            //
            // 디자인에는 "● 활동중"이 있으나 서버가 접속 상태를 주지 않습니다.
            // 근거 없는 상태를 표시하지 않고 이름만 보여줍니다.
            Text(chatRoom.participantName)
                .font(AppFont.bodyMBold)
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
                .padding(.leading, AppSpacing.xs)

            Spacer(minLength: 8)

            // 전화 버튼 — 개인톡이면서 번호가 등록돼 있을 때만 노출합니다
            if !chatRoom.isGroupChat, let phone = peerPhoneNumber, !phone.isEmpty {
                Button { dial(phone) } label: {
                    Image(systemName: "phone")
                        .font(AppFont.headline)
                        .foregroundColor(AppColor.textStrong)
                }
                .padding(.trailing, AppSpacing.xxl)
            }
        }
        .frame(height: 62)
        .background(Color.white)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    // 맨 위에 닿으면 과거 30개를 더 불러옵니다
                    if viewModel.hasOlderMessages {
                        ProgressView()
                            .padding(.vertical, AppSpacing.xs)
                            .onAppear { viewModel.loadOlderMessages(chatRoomId: chatRoom.id) }
                    }

                    ForEach(Array(chatMessages.enumerated()), id: \.element.id) { index, msg in
                        // 날짜가 바뀌는 지점마다 구분선을 넣습니다.
                        if let label = dateSeparator(at: index) {
                            ChatDateSeparatorView(text: label)
                                .padding(.vertical, 6)
                        }

                        ChatBubbleView(message: msg) {
                            failedMessageId = UUID(uuidString: msg.id)
                        }
                        .id(msg.id)
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: chatMessages.count) { _ in
                withAnimation {
                    proxy.scrollTo(chatMessages.last?.id, anchor: .bottom)
                }
            }
        }
        .background(Color.white)
    }

    /// 앞 메시지와 날짜가 다르면 구분선 문구를 만듭니다. 첫 메시지에는 항상 붙습니다.
    private func dateSeparator(at index: Int) -> String? {
        let cal = Calendar.current
        let current = chatMessages[index].sentAt
        if index > 0,
           cal.isDate(chatMessages[index - 1].sentAt, inSameDayAs: current) {
            return nil
        }
        return AppDate.chatDaySeparator(current)
    }

    // MARK: - 첨부 / 녹음

    /// 고른 사진·동영상을 올립니다. 용량 초과는 ViewModel이 걸러 안내합니다.
    private func attach(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            viewModel.toast = "첨부하지 못했어요"
            return
        }

        let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
        viewModel.sendAttachment(
            chatRoomId: chatRoom.id,
            data: data,
            mediaType: isVideo ? "video" : "photo",
            fileName: isVideo ? "video.mp4" : "photo.jpg",
            mimeType: isVideo ? "video/mp4" : "image/jpeg"
        )
    }

    private func beginRecording() async {
        switch await recorder.start() {
        case .started:          break
        case .permissionDenied: showPermissionGuide = true
        case .failed:           viewModel.toast = "녹음을 시작하지 못했어요"
        }
    }

    private func finishRecording() {
        guard recorder.isRecording else { return }
        guard let result = recorder.stop() else { return }

        viewModel.sendAttachment(
            chatRoomId: chatRoom.id,
            data: result.data,
            mediaType: "audio",
            fileName: "voice.m4a",
            mimeType: "audio/mp4",
            duration: result.duration
        )
    }

    // MARK: - 배너 / 토스트

    @ViewBuilder
    private var offlineBanner: some View {
        if viewModel.isOffline {
            Text("연결이 끊겼어요. 다시 연결되면 보낼게요")
                .font(AppFont.captionMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(AppColor.textSecondary)
        }
    }

    /// OS 다이얼러로 넘깁니다 (인앱 통화가 아닙니다)
    private func dial(_ number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 0) {
            // + 첨부 버튼
            Button { showAttachmentOptions = true } label: {
                Group {
                    if viewModel.isUploading {
                        ProgressView()
                    } else {
                        Text("＋")
                            .font(AppFont.title1)
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .disabled(viewModel.isUploading)
            .padding(.leading, 18)

            // 텍스트 입력
            //
            // 입력 중에 잘라내면 조합형 문자(한/일/중) 입력이 깨지므로
            // 자르지 않고 초과분을 빨간 카운터로 알리고 전송만 막습니다.
            VStack(alignment: .trailing, spacing: 2) {
                TextField("메시지를 입력하세요", text: $viewModel.messageText)
                    .focused($isInputFocused)
                    .font(AppFont.bodyL)
                    .foregroundColor(AppColor.textStrong)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(AppColor.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(viewModel.isOverMessageLimit ? AppColor.danger : .clear, lineWidth: 1)
                    )

                if viewModel.messageText.count > viewModel.messageLimit - 100 {
                    Text("\(viewModel.messageText.count)/\(viewModel.messageLimit)")
                        .font(viewModel.isOverMessageLimit ? AppFont.caption2Bold : AppFont.caption2)
                        .foregroundColor(viewModel.isOverMessageLimit
                                         ? AppColor.danger : AppColor.textMuted)
                }
            }
            .padding(.leading, 11)

            // 전송 / 마이크 버튼
            Button {
                if !viewModel.messageText.isEmpty, !viewModel.isOverMessageLimit {
                    viewModel.sendMessage(chatRoomId: chatRoom.id)
                }
            } label: {
                Image(systemName: recorder.isRecording
                      ? "stop.fill"
                      : (viewModel.messageText.isEmpty ? "mic.fill" : "arrow.up"))
                    .font(AppFont.icon(viewModel.messageText.isEmpty ? 18 : 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(recorder.isRecording
                                ? AppColor.danger
                                : (viewModel.isOverMessageLimit
                                   ? AppColor.borderMuted : AppColor.brand))
                    .clipShape(Circle())
            }
            .disabled(viewModel.isOverMessageLimit)
            // 입력이 비어 있을 때만 꾹 눌러 녹음합니다 (떼면 전송)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onEnded { _ in
                        guard viewModel.messageText.isEmpty else { return }
                        Task { await beginRecording() }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in finishRecording() }
            )
            .padding(.leading, 14)
            .padding(.trailing, 21)
        }
        .padding(.vertical, AppSpacing.xs)
        .background(Color.white)
    }
}
