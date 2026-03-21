import SwiftUI

// MARK: - ChatRoomView
/// 채팅 메시지 화면 (대화창)
///
/// 카카오톡 대화방과 유사한 구조:
/// - 내 메시지: 오른쪽 (파란 말풍선)
/// - 상대 메시지: 왼쪽 (회색 말풍선)
/// - 하단 고정: 메시지 입력창 + 전송 버튼
///
/// 새로운 SwiftUI 패턴:
/// - ScrollViewReader: 새 메시지 전송 시 자동 스크롤
/// - safeAreaInset: 입력창을 하단에 고정

struct ChatRoomView: View {

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    let chatRoom: ChatRoom

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 메시지 목록
                messageList

                // MARK: - 입력창
                messageInputBar
            }
            .navigationTitle(chatRoom.participantName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .onAppear {
                viewModel.fetchMessages(chatRoomId: chatRoom.id)
                viewModel.markAsRead(chatRoomId: chatRoom.id)
            }
        }
    }

    // MARK: - 메시지 목록

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { _ in
                // 새 메시지가 추가되면 자동으로 맨 아래로 스크롤
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - 말풍선

    /// 내 메시지 / 상대 메시지에 따라 좌우 배치 + 색상 변경
    private func messageBubble(_ message: Message) -> some View {
        let isMe = viewModel.isMyMessage(message)

        return HStack(alignment: .bottom, spacing: 8) {
            if isMe {
                Spacer(minLength: 60)

                // 시간 (왼쪽)
                messageTime(message.sentAt)

                // 내 말풍선 (오른쪽, 파란색)
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HiTripColor.primary800)
                    .cornerRadius(16)
                    .cornerRadius(4, corners: .bottomRight)
            } else {
                // 상대 말풍선 (왼쪽, 회색)
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(HiTripColor.textGrayA)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HiTripColor.gray100)
                    .cornerRadius(16)
                    .cornerRadius(4, corners: .bottomLeft)

                // 시간 (오른쪽)
                messageTime(message.sentAt)

                Spacer(minLength: 60)
            }
        }
    }

    /// 시간 표시 ("오후 3:42")
    private func messageTime(_ date: Date) -> some View {
        Text(formatTime(date))
            .font(.system(size: 11))
            .foregroundColor(HiTripColor.gray400)
    }

    // MARK: - 입력창

    /// 하단 고정 메시지 입력 바
    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("메시지를 입력하세요", text: $viewModel.messageText)
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(HiTripColor.gray100)
                    .cornerRadius(20)

                // 전송 버튼
                Button {
                    viewModel.sendMessage(chatRoomId: chatRoom.id)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(
                            viewModel.isMessageValid
                                ? HiTripColor.primary800
                                : HiTripColor.gray300
                        )
                }
                .disabled(!viewModel.isMessageValid)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 시간 포맷

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 특정 모서리만 둥글게 하는 Extension
/// .cornerRadius(4, corners: .bottomRight) 같은 사용을 위한 헬퍼
///
/// SwiftUI 기본 .cornerRadius()는 4개 모서리 전부 둥글게 함
/// 카톡 말풍선은 한쪽 모서리만 뾰족해야 하므로 이 Extension 필요

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

/// 특정 모서리만 둥글게 만드는 Shape
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
