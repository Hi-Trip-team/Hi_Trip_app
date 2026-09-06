import SwiftUI

// MARK: - ChatBubbleView
/// 채팅 말풍선
///
/// 피그마 채팅방 (1:1 / 단체) 기준
/// - 내 말풍선 #0C46C0 / 상대 말풍선 #F7F7F9 / 전송 실패 #E5F4FF
/// - 모서리 12, 보내는 쪽 아래 모서리만 각짐
/// - 좌우 여백: 상대 30, 나 24
///
/// "읽음" 표시는 하지 않습니다. 디자인에는 읽음이면 시각이 초록(#219E4D)에
/// 겹친 체크로 표시되지만, 서버가 메시지별 읽음 여부를 주지 않습니다.
/// 앱이 확실히 아는 전송 상태만 회색으로 보여줍니다.

struct ChatBubbleView: View {

    let message: ChatMessage
    /// 전송 실패한 메시지를 탭했을 때
    var onRetry: (() -> Void)?

    private var isMine: Bool { message.isMine }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine {
                Spacer(minLength: 40)
                if message.sendFailed {
                    failureBadge
                } else {
                    statusColumn
                }
                bubbleColumn
            } else {
                bubbleColumn
                timeText
                Spacer(minLength: 40)
            }
        }
        .padding(.leading, isMine ? 20 : 30)
        .padding(.trailing, isMine ? 24 : 20)
    }

    // MARK: - 말풍선

    /// 말풍선과, 실패했을 때 그 아래 붙는 안내 문구
    private var bubbleColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            bubble

            if message.sendFailed {
                Text("전송 실패 — 탭하여 재전송·삭제")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .padding(.leading, 10)
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(message.attachments) { attachment in
                attachmentView(attachment)
            }

            if !message.content.isEmpty {
                Text(message.content)
                    .font(.system(size: 14))
                    .lineSpacing(6)
                    .foregroundColor(textColor)
            }
        }
            // 사진만 보낸 메시지는 여백을 줄여 사진이 말풍선을 채우게 합니다
            .padding(.horizontal, isPhotoOnly ? 4 : 12)
            .padding(.vertical, isPhotoOnly ? 4 : 10)
            .background(bubbleColor)
            .clipShape(bubbleShape)
            .opacity(message.isSending ? 0.6 : 1)
            .contentShape(Rectangle())
            .onTapGesture { if message.sendFailed { onRetry?() } }
    }

    /// 보내는 쪽 아래 모서리만 각진 형태
    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 12,
            bottomLeadingRadius: 12,
            bottomTrailingRadius: 0,
            topTrailingRadius: 12
        )
    }

    /// 사진은 그대로, 동영상·음성은 아이콘 줄로 보여줍니다.
    @ViewBuilder
    private func attachmentView(_ attachment: MessageAttachment) -> some View {
        if attachment.isPhoto {
            AsyncImage(url: attachment.downloadUrl.flatMap(URL.init)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color(hex: "#E5E7EB"))
            }
            .frame(width: 180, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            HStack(spacing: 8) {
                Image(systemName: attachment.isVideo ? "play.rectangle.fill" : "waveform")
                    .font(.system(size: 16))
                Text(attachmentLabel(attachment))
                    .font(.system(size: 13))
            }
            .foregroundColor(textColor)
            .padding(.vertical, 2)
        }
    }

    private func attachmentLabel(_ attachment: MessageAttachment) -> String {
        if attachment.isAudio {
            let seconds = attachment.duration ?? 0
            return String(format: "음성 %d:%02d", seconds / 60, seconds % 60)
        }
        return attachment.originalName ?? "동영상"
    }

    /// 사진 한 장만 있고 본문이 없는 메시지
    private var isPhotoOnly: Bool {
        message.content.isEmpty && message.attachments.allSatisfy(\.isPhoto)
            && !message.attachments.isEmpty
    }

    private var bubbleColor: Color {
        if message.sendFailed { return Color(hex: "#E5F4FF") }
        return isMine ? Color(hex: "#0C46C0") : Color(hex: "#F7F7F9")
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
    private var statusColumn: some View {
        HStack(spacing: 4) {
            timeText
            Image(systemName: message.isSending ? "clock" : "checkmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#7D848D"))
        }
    }

    /// 전송 실패 표시 — 말풍선 왼쪽 바깥에 붙습니다
    private var failureBadge: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#EF4444"))
                .frame(width: 22, height: 22)
            Text("!")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        // 실패 안내 문구 높이만큼 위로 올려 말풍선과 나란히 둡니다
        .padding(.bottom, 20)
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
