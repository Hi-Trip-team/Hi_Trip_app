import SwiftUI

// MARK: - ErrorStateView
/// 불러오기 실패 화면 — 원인 문구 + [다시 시도]
///
/// 인터넷이 다시 연결되면 자동으로 retry를 한 번 부릅니다(사용자가 누르지 않아도 됨).

struct ErrorStateView: View {
    let message: String
    var retryTitle: String = "다시 시도"
    let retry: () -> Void

    /// 연결 문제로 보이는 문구면 와이파이 아이콘, 아니면 경고 아이콘
    private var iconName: String {
        message.contains("연결") || message.contains("네트워크") ? "wifi.slash" : "exclamationmark.triangle"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: iconName)
                .font(AppFont.icon(34))
                .foregroundColor(AppColor.borderStrong)
            Text(message)
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text(retryTitle)
                    .font(AppFont.bodyBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .frame(height: 44)
                    .background(AppColor.accent)
                    .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: .hiTripNetworkReconnected)) { _ in retry() }
    }
}

// MARK: - EmptyStateView
/// 데이터가 없을 때 — 아이콘 + 제목 + (선택) 설명

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(AppFont.logo)
                .foregroundColor(AppColor.borderStrong)
            Text(title)
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
            if let message {
                Text(message)
                    .font(AppFont.label)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
