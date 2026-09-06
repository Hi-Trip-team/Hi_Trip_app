import SwiftUI

// MARK: - NotificationItemView
/// 알림 센터의 단일 알림 행 컴포넌트

struct NotificationItemView: View {

    let item: NotificationItem
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: HiTripSpacing.md) {
            // 카테고리 뱃지
            categoryBadge

            // 텍스트 영역
            VStack(alignment: .leading, spacing: HiTripSpacing.xs) {
                Text(item.title)
                    .font(HiTripFont.bodyBold)
                    .foregroundColor(HiTripColor.textBlack)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.subtitle)
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.gray500)
                    .lineLimit(2)

                Text(item.time)
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.gray400)
            }

            Spacer(minLength: 0)

            // 위험 알림 "확인" 버튼
            if item.requiresAction && !item.isActioned {
                Button {
                    onAction?()
                } label: {
                    Text("확인")
                        .font(HiTripFont.captionM)
                        .foregroundColor(.white)
                        .padding(.horizontal, HiTripSpacing.md)
                        .padding(.vertical, HiTripSpacing.sm)
                        .background(HiTripColor.danger)
                        .cornerRadius(HiTripRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(HiTripSpacing.cardPadding)
        .background(backgroundForCategory)
        .cornerRadius(HiTripRadius.card)
    }

    // MARK: - Badge

    private var categoryBadge: some View {
        Text(item.category == .all ? "" : item.category.rawValue)
            .font(HiTripFont.badge)
            .foregroundColor(.white)
            .padding(.horizontal, HiTripSpacing.sm)
            .padding(.vertical, HiTripSpacing.xs)
            .background(colorForCategory)
            .cornerRadius(HiTripRadius.chip)
            .opacity(item.category == .all ? 0 : 1)
            .overlay(
                Text(item.category == .all ? "" : item.category.rawValue)
                    .font(HiTripFont.badge)
                    .foregroundColor(.white)
                    .padding(.horizontal, HiTripSpacing.sm)
                    .padding(.vertical, HiTripSpacing.xs)
                    .background(colorForCategory)
                    .cornerRadius(HiTripRadius.chip)
            )
    }

    private var colorForCategory: Color {
        switch item.category {
        case .danger:  return HiTripColor.danger
        case .leave:   return HiTripColor.caution
        case .warning: return HiTripColor.warningYellow
        case .normal:  return HiTripColor.gray400
        case .all:     return .clear
        }
    }

    private var backgroundForCategory: Color {
        switch item.category {
        case .danger:  return HiTripColor.dangerBg
        case .leave:   return HiTripColor.cautionBg
        case .warning: return HiTripColor.warningBg
        default:       return HiTripColor.gray100
        }
    }
}
