import SwiftUI

// MARK: - TouristNotificationListView
/// 여행객 알림함 — 종 아이콘으로 진입
///
/// 알림 목록을 내려주는 엔드포인트가 아직 없어 지금은 빈 상태만 표시합니다.
/// 서버가 준비되면 `notifications`를 ViewModel에서 채우고 emptyState 분기만 유지하면 됩니다.
///
/// 참고: 공지(공지사항 팝업)와는 다른 화면입니다.
/// 공지는 안내사가 올리는 게시물이고, 여기는 일정 변경·안전 확인 등 개별 알림이 쌓이는 곳입니다.

struct TouristNotificationListView: View {

    @Environment(\.dismiss) private var dismiss

    /// 서버 연동 전까지 항상 비어 있습니다.
    private let notifications: [TouristNotificationItem] = []

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            if notifications.isEmpty {
                emptyState
            } else {
                List(notifications) { item in
                    row(item)
                }
                .listStyle(.plain)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - 헤더

    private var headerSection: some View {
        NavigationHeader(title: "알림") { dismiss() }
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        EmptyStateView(icon: "bell", title: "받은 알림이 없습니다", message: "일정 변경이나 안전 확인 요청이 오면\n여기에 표시됩니다")
    }

    // MARK: - 알림 행

    private func row(_ item: TouristNotificationItem) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Circle()
                .fill(item.isRead ? Color.clear : AppColor.danger)
                .frame(width: 7, height: 7)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.title)
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.time)
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textTertiary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
