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
        .onAppear {
            viewModel.fetchMessages(chatRoomId: chatRoom.id)
            viewModel.markAsRead(chatRoomId: chatRoom.id)
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: HiTripSpacing.md) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
            }

            // 아바타
            Circle()
                .fill(HiTripColor.gray100)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: chatRoom.isGroupChat ? "person.3.fill" : "person.fill")
                        .font(.system(size: chatRoom.isGroupChat ? 13 : 15))
                        .foregroundColor(HiTripColor.gray400)
                )

            // 이름
            //
            // 디자인에는 "● 활동중"이 있으나 서버가 접속 상태를 주지 않습니다.
            // 근거 없는 상태를 표시하지 않고 이름만 보여줍니다.
            Text(chatRoom.participantName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .lineLimit(1)

            Spacer()

            // 전화 버튼 (개인톡만)
            if !chatRoom.isGroupChat {
                Button { } label: {
                    Image(systemName: "phone")
                        .font(.system(size: 18))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
        .padding(.horizontal, HiTripSpacing.pagePadding)
        .frame(height: HiTripSpacing.navBarHeight)
        .background(Color.white)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: HiTripSpacing.sm) {
                    ForEach(Array(chatMessages.enumerated()), id: \.element.id) { index, msg in
                        // 날짜가 바뀌는 지점마다 구분선을 넣습니다.
                        if let label = dateSeparator(at: index) {
                            ChatDateSeparatorView(text: label)
                                .padding(.vertical, 6)
                        }

                        ChatBubbleView(message: msg) {
                            viewModel.retry(messageId: UUID(uuidString: msg.id) ?? UUID())
                        }
                        .id(msg.id)
                    }
                }
                .padding(.vertical, HiTripSpacing.md)
            }
            .onChange(of: chatMessages.count) { _ in
                withAnimation {
                    proxy.scrollTo(chatMessages.last?.id, anchor: .bottom)
                }
            }
        }
        .background(HiTripColor.screenBackground)
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

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: HiTripSpacing.md) {
            // + 첨부 버튼
            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(HiTripColor.gray500)
            }

            // 텍스트 입력
            TextField("메시지를 입력하세요", text: $viewModel.messageText)
                .font(HiTripFont.body)
                .padding(.horizontal, HiTripSpacing.md)
                .padding(.vertical, HiTripSpacing.smd)
                .background(HiTripColor.gray100)
                .cornerRadius(HiTripRadius.pill)

            // 전송/마이크 버튼
            if viewModel.messageText.isEmpty {
                Button { } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(HiTripColor.primary800)
                        .clipShape(Circle())
                }
            } else {
                Button {
                    viewModel.sendMessage(chatRoomId: chatRoom.id)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(HiTripColor.primary800)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, HiTripSpacing.pagePadding)
        .padding(.vertical, HiTripSpacing.inputBarV)
        .background(Color.white)
    }
}
