import SwiftUI

// MARK: - ChatBubbleView
/// 채팅 말풍선 단일 컴포넌트
///
/// 피그마 0827 수정본:
/// - 내 메시지: 파란 배경(primary800), 흰 텍스트, 오른쪽 정렬
/// - 상대 메시지: 회색 배경(F2F2F2), 검은 텍스트, 왼쪽 정렬
/// - 읽음 체크: 파란/회색 이중 체크마크
/// - 전송 실패: 빨간 ! + "탭하여 재전송·삭제"

struct ChatBubbleView: View {

    let message: ChatMessage
    var onRetry: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    private var isMine: Bool { message.isMine }

    var body: some View {
        HStack(alignment: .bottom, spacing: HiTripSpacing.sm) {
            if isMine {
                Spacer(minLength: 60)
                metaView          // 시간 + 읽음
                bubble
            } else {
                bubble
                metaView          // 시간
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, HiTripSpacing.pagePadding)
    }

    // MARK: - Bubble

    private var bubble: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: HiTripSpacing.xs) {
            Text(message.content)
                .font(HiTripFont.bodyM)
                .foregroundColor(isMine ? .white : HiTripColor.textBlack)
                .padding(.horizontal, HiTripSpacing.bubbleH)
                .padding(.vertical, HiTripSpacing.bubbleV)
                .background(isMine ? HiTripColor.bubbleMine : HiTripColor.bubbleOther)
                .cornerRadius(HiTripRadius.card,
                              corners: isMine
                              ? [.topLeft, .topRight, .bottomLeft]
                              : [.topLeft, .topRight, .bottomRight])

            // 전송 실패
            if message.sendFailed {
                Button {
                    // 탭 제스처 — 재전송 or 삭제 액션시트
                } label: {
                    HStack(spacing: HiTripSpacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(HiTripColor.sendFailed)
                        Text("전송 실패 — 탭하여 재전송·삭제")
                            .font(HiTripFont.caption)
                            .foregroundColor(HiTripColor.sendFailed)
                    }
                }
            }
        }
    }

    // MARK: - Meta (시간 + 읽음 체크)

    private var metaView: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
            if isMine {
                readCheckView
            }
            Text(message.timeString)
                .font(HiTripFont.caption)
                .foregroundColor(HiTripColor.gray400)
        }
    }

    @ViewBuilder
    private var readCheckView: some View {
        if message.isRead {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(HiTripColor.readCheckGreen)
        } else {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(HiTripColor.gray300)
        }
    }
}

// MARK: - DateSeparatorView

struct ChatDateSeparatorView: View {
    let text: String

    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .font(HiTripFont.caption)
                .foregroundColor(HiTripColor.gray400)
                .padding(.horizontal, HiTripSpacing.md)
                .padding(.vertical, HiTripSpacing.xs)
                .background(HiTripColor.gray100)
                .cornerRadius(HiTripRadius.pill)
            Spacer()
        }
        .padding(.vertical, HiTripSpacing.sm)
    }
}
