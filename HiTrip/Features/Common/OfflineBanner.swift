import SwiftUI

// MARK: - OfflineBanner
/// 앱을 쓰는 중 인터넷이 끊기면 상단에 띄우는 배너.
/// 다시 연결되면 사라지고, 실패 화면(ErrorStateView)은 자동으로 다시 불러옵니다.

struct OfflineBanner: View {

    @ObservedObject private var network = NetworkMonitor.shared

    var body: some View {
        if !network.isConnected {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "wifi.slash")
                    .font(AppFont.icon(13, weight: .semibold))
                Text("인터넷 연결이 끊겼어요")
                    .font(AppFont.labelMedium)
                Text("연결되면 자동으로 새로고침해요")
                    .font(AppFont.caption)
                    .opacity(0.8)
                Spacer(minLength: 0)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(AppColor.textDark)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
        }
    }
}
