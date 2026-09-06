import SwiftUI

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

    private var chatMessages: [ChatMessage] {
        viewModel.messages.map { $0.toChatMessage(currentUserId: viewModel.currentUserId) }
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Divider()
            messageList
            Divider()
            inputBar
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onTapGesture { isInputFocused = false }
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

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "#1B1E28"))
                    .frame(width: 24, height: 24)
            }
            .padding(.leading, 12)

            // 아바타
            Circle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: chatRoom.isGroupChat ? "person.3.fill" : "person.fill")
                        .font(.system(size: chatRoom.isGroupChat ? 13 : 15))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                )
                .padding(.leading, 16)

            // 이름
            //
            // 디자인에는 "● 활동중"이 있으나 서버가 접속 상태를 주지 않습니다.
            // 근거 없는 상태를 표시하지 않고 이름만 보여줍니다.
            Text(chatRoom.participantName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .lineLimit(1)
                .padding(.leading, 8)

            Spacer(minLength: 8)

            // 전화 버튼 — 개인톡이면서 번호가 등록돼 있을 때만 노출합니다
            if !chatRoom.isGroupChat, let phone = peerPhoneNumber, !phone.isEmpty {
                Button { dial(phone) } label: {
                    Image(systemName: "phone")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "#1B1E28"))
                }
                .padding(.trailing, 32)
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
                            .padding(.vertical, 8)
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
                .padding(.vertical, 16)
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
        if cal.isDateInToday(current)     { return "오늘" }
        if cal.isDateInYesterday(current) { return "어제" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = cal.isDate(current, equalTo: Date(), toGranularity: .year)
            ? "M월 d일 EEEE" : "yyyy년 M월 d일"
        return f.string(from: current)
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
            Button { } label: {
                Text("＋")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.leading, 18)

            // 텍스트 입력
            //
            // 입력 중에 잘라내면 조합형 문자(한/일/중) 입력이 깨지므로
            // 자르지 않고 초과분을 빨간 카운터로 알리고 전송만 막습니다.
            VStack(alignment: .trailing, spacing: 2) {
                TextField("메시지를 입력하세요", text: $viewModel.messageText)
                    .focused($isInputFocused)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#1B1E28"))
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(hex: "#F7F7F9"))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(viewModel.isOverMessageLimit ? Color(hex: "#EF4444") : .clear, lineWidth: 1)
                    )

                if viewModel.messageText.count > viewModel.messageLimit - 100 {
                    Text("\(viewModel.messageText.count)/\(viewModel.messageLimit)")
                        .font(.system(size: 11, weight: viewModel.isOverMessageLimit ? .bold : .regular))
                        .foregroundColor(viewModel.isOverMessageLimit
                                         ? Color(hex: "#EF4444") : Color(hex: "#7D848D"))
                }
            }
            .padding(.leading, 11)

            // 전송 / 마이크 버튼
            Button {
                if !viewModel.messageText.isEmpty, !viewModel.isOverMessageLimit {
                    viewModel.sendMessage(chatRoomId: chatRoom.id)
                }
            } label: {
                Image(systemName: viewModel.messageText.isEmpty ? "mic.fill" : "arrow.up")
                    .font(.system(size: viewModel.messageText.isEmpty ? 18 : 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(viewModel.isOverMessageLimit
                                ? Color(hex: "#C3CDDA") : Color(hex: "#0C46C0"))
                    .clipShape(Circle())
            }
            .disabled(viewModel.isOverMessageLimit)
            .padding(.leading, 14)
            .padding(.trailing, 21)
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }
}
