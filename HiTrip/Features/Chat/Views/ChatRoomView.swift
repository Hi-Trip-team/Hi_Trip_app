import SwiftUI

// MARK: - ChatRoomView
/// 채팅 메시지 화면 (대화창)
///
/// 피그마 디자인:
/// - 상단: ← "이름" (활동중 표시) 전화 아이콘
/// - "오늘" 날짜 구분선
/// - 메시지 말풍선:
///   - 내 메시지: 연한 파란 배경 (#ECF2FE), 오른쪽 정렬
///   - 상대 메시지: 회색 배경, 왼쪽 정렬 + 아바타
/// - 읽음 표시: 초록 ✓✓
/// - 하단: "메시지를 입력하세요" + 첨부 아이콘 + 파란 마이크 버튼

struct ChatRoomView: View {

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    let chatRoom: ChatRoom

    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 네비게이션 바
            chatNavigationBar

            Divider()

            // 메시지 목록
            messageList

            // 입력창
            messageInputBar
        }
        .background(HiTripColor.screenBackground)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchMessages(chatRoomId: chatRoom.id)
            viewModel.markAsRead(chatRoomId: chatRoom.id)
        }
    }

    // MARK: - Custom Navigation Bar

    private var chatNavigationBar: some View {
        HStack(spacing: 12) {
            // 뒤로가기
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
            }

            // 이름 + 활동 상태
            VStack(alignment: .leading, spacing: 2) {
                Text(chatRoom.participantName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                if chatRoom.isOnline && !chatRoom.isGroupChat {
                    Text("활동중")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.readCheck)
                }
            }

            Spacer()

            // 전화 아이콘 (개인톡만)
            if !chatRoom.isGroupChat {
                Button { } label: {
                    Image(systemName: "phone")
                        .font(.system(size: 18))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }

            // 더보기
            Button { } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(HiTripColor.textBlack)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 날짜 구분선
                    dateSeparator

                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        let isMe = viewModel.isMyMessage(message)
                        let showAvatar = shouldShowAvatar(at: index)
                        let showTime = shouldShowTime(at: index)

                        messageBubble(message, isMe: isMe, showAvatar: showAvatar, showTime: showTime)
                            .id(message.id)
                            .padding(.top, showAvatar ? 12 : 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Date Separator

    private var dateSeparator: some View {
        HStack {
            line
            Text(dateSeparatorText)
                .font(.system(size: 12))
                .foregroundColor(HiTripColor.gray400)
                .padding(.horizontal, 12)
            line
        }
        .padding(.vertical, 16)
    }

    private var line: some View {
        Rectangle()
            .fill(HiTripColor.gray200)
            .frame(height: 0.5)
    }

    /// 날짜 구분 텍스트 ("오늘", "어제", "5월 3일" 등)
    private var dateSeparatorText: String {
        guard let firstMessage = viewModel.messages.first else { return "오늘" }
        let cal = Calendar.current
        if cal.isDateInToday(firstMessage.sentAt) {
            return "오늘"
        } else if cal.isDateInYesterday(firstMessage.sentAt) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일"
            return formatter.string(from: firstMessage.sentAt)
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: Message, isMe: Bool, showAvatar: Bool, showTime: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMe {
                Spacer(minLength: 60)

                // 읽음 표시 + 시간 (왼쪽)
                VStack(alignment: .trailing, spacing: 2) {
                    if showTime {
                        // 읽음 체크 (✓✓)
                        if message.isRead {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(HiTripColor.readCheck)
                        }

                        Text(formatTime(message.sentAt))
                            .font(.system(size: 11))
                            .foregroundColor(HiTripColor.gray400)
                    }
                }

                // 내 말풍선 (연한 파란 배경)
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(HiTripColor.textBlack)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HiTripColor.secondary100)
                    .cornerRadius(16)
                    .cornerRadius(4, corners: .bottomRight)

            } else {
                // 아바타 (첫 메시지 or 발신자 변경 시)
                if showAvatar {
                    Circle()
                        .fill(HiTripColor.gray200)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: chatRoom.isGroupChat ? "person.fill" : "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(HiTripColor.gray400)
                        )
                } else {
                    Spacer().frame(width: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    // 이름 (아바타 표시 시에만)
                    if showAvatar && chatRoom.isGroupChat {
                        Text(message.senderName)
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray500)
                    }

                    // 상대 말풍선 (회색 배경)
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(HiTripColor.textGrayA)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(HiTripColor.gray100)
                        .cornerRadius(16)
                        .cornerRadius(4, corners: .bottomLeft)
                }

                // 시간 (오른쪽)
                if showTime {
                    Text(formatTime(message.sentAt))
                        .font(.system(size: 11))
                        .foregroundColor(HiTripColor.gray400)
                }

                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - Input Bar

    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
                // 첨부 버튼
                Button { } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(HiTripColor.gray400)
                }

                // 텍스트 입력
                TextField("메시지를 입력하세요", text: $viewModel.messageText)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HiTripColor.gray100)
                    .cornerRadius(20)

                // 전송/마이크 버튼
                if viewModel.isMessageValid {
                    Button {
                        viewModel.sendMessage(chatRoomId: chatRoom.id)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(HiTripColor.primary800)
                    }
                } else {
                    Button { } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(HiTripColor.primary800)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color.white)
    }

    // MARK: - Helpers

    /// 아바타 표시 여부: 첫 메시지거나 이전 메시지의 발신자가 다를 때
    private func shouldShowAvatar(at index: Int) -> Bool {
        let message = viewModel.messages[index]
        if viewModel.isMyMessage(message) { return false }
        if index == 0 { return true }
        let prev = viewModel.messages[index - 1]
        return prev.senderId != message.senderId
    }

    /// 시간 표시 여부: 마지막 메시지거나 다음 메시지와 시간이 다를 때
    private func shouldShowTime(at index: Int) -> Bool {
        if index == viewModel.messages.count - 1 { return true }
        let current = viewModel.messages[index]
        let next = viewModel.messages[index + 1]
        // 발신자가 다르면 항상 표시
        if current.senderId != next.senderId { return true }
        // 같은 발신자라도 분이 다르면 표시
        let cal = Calendar.current
        return cal.component(.minute, from: current.sentAt) != cal.component(.minute, from: next.sentAt)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 특정 모서리만 둥글게 하는 Extension
/// .cornerRadius(4, corners: .bottomRight) 같은 사용을 위한 헬퍼

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
