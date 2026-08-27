import SwiftUI

// MARK: - ChatRoomView
/// 채팅방 내부 화면
///
/// 피그마 0827 수정본:
/// - 헤더: 뒤로가기 / 이름 + 🟢활동중 / 📞 전화 버튼
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

            // 이름 + 활동중
            VStack(alignment: .leading, spacing: 2) {
                Text(chatRoom.participantName)
                    .font(HiTripFont.title3)
                    .foregroundColor(HiTripColor.textBlack)

                if chatRoom.isOnline && !chatRoom.isGroupChat {
                    HStack(spacing: HiTripSpacing.xs) {
                        Circle()
                            .fill(HiTripColor.onlineGreen)
                            .frame(width: 6, height: 6)
                        Text("활동중")
                            .font(HiTripFont.caption)
                            .foregroundColor(HiTripColor.onlineGreen)
                    }
                }
            }

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
                    ChatDateSeparatorView(text: "오늘")
                        .id("top")

                    ForEach(chatMessages) { msg in
                        ChatBubbleView(message: msg)
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
                    viewModel.sendMessage()
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
