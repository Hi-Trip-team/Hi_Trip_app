import SwiftUI

// MARK: - AdvantageCardView
/// 스팟 상세 화면의 어드벤티지(혜택) 카드
///
/// 피그마: 파란 배경(secondary100), 볼드 타이틀, 설명 텍스트

struct AdvantageCardView: View {

    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
            HStack(spacing: HiTripSpacing.sm) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.advantageAccent)
                Text("어드벤티지")
                    .font(HiTripFont.labelM)
                    .foregroundColor(HiTripColor.advantageAccent)
            }

            Text(title)
                .font(HiTripFont.bodyBold)
                .foregroundColor(HiTripColor.textBlack)

            if !description.isEmpty {
                Text(description)
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.gray500)
                    .lineLimit(2)
            }
        }
        .padding(HiTripSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HiTripColor.advantageBg)
        .cornerRadius(HiTripRadius.card)
    }
}
