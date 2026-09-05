import SwiftUI

// MARK: - ChatBubbleView
/// 채팅 말풍선
///
/// 내 메시지는 오른쪽 파란 말풍선, 상대 메시지는 왼쪽 회색 말풍선입니다.
/// 시각은 내 메시지면 왼쪽, 상대 메시지면 오른쪽에 붙습니다.
///
/// "읽음" 표시는 하지 않습니다. 서버가 메시지별 읽음 여부를 주지 않아
/// 표시하면 근거 없는 정보가 됩니다. 앱이 확실히 아는 전송 상태만 보여줍니다.

struct ChatBubbleView: View {

    let message: ChatMessage
    /// 전송 실패한 메시지를 탭했을 때
    var onRetry: (() -> Void)?

    private var isMine: Bool { message.isMine }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMine {
                Spacer(minLength: 40)
                statusColumn
                bubble
            } else {
                bubble
                timeText
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 말풍선

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                if message.sendFailed {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#EF4444"))
                            .frame(width: 22, height: 22)
                        Text("!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(message.content)
                    .font(.system(size: 14))
                    .lineSpacing(6)
                    .foregroundColor(textColor)
            }

            if message.sendFailed {
                Text("전송 실패 — 탭하여 재전송·삭제")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#EF4444"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(bubbleColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(message.isSending ? 0.6 : 1)
        .contentShape(Rectangle())
        .onTapGesture { if message.sendFailed { onRetry?() } }
    }

    private var bubbleColor: Color {
        if message.sendFailed { return Color(hex: "#E5F4FF") }
        return isMine ? Color(hex: "#2563EB") : Color(hex: "#F7F7F9")
    }

    private var textColor: Color {
        if message.sendFailed { return Color(hex: "#1B1E28") }
        return isMine ? .white : Color(hex: "#1B1E28")
    }

    // MARK: - 시각 / 전송 상태

    private var timeText: some View {
        Text(message.timeString)
            .font(.system(size: 12))
            .foregroundColor(Color(hex: "#7D848D"))
    }

    /// 내 메시지 왼쪽에 붙는 시각과 전송 상태
    @ViewBuilder
    private var statusColumn: some View {
        if message.sendFailed {
            EmptyView()
        } else {
            HStack(spacing: 4) {
                timeText
                if message.isSending {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#7D848D"))
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#7D848D"))
                }
            }
        }
    }
}

// MARK: - 날짜 구분선

struct ChatDateSeparatorView: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "#7D848D"))
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Color(hex: "#F7F7F9"))
            .cornerRadius(8)
    }
}
