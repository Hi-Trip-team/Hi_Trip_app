import SwiftUI

// MARK: - CountBadge
/// 빨간 숫자 뱃지 — 안 읽은 메시지 수 등

struct CountBadge: View {
    let text: String
    var diameter: CGFloat = 22

    var body: some View {
        Text(text)
            .font(AppFont.captionBold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .frame(minWidth: diameter, minHeight: diameter)
            .background(AppColor.danger)
            .clipShape(Capsule())
    }
}
