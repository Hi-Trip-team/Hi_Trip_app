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
        ZStack {
            Text("알림")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#D1D5DB"))
            Text("받은 알림이 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Text("일정 변경이나 안전 확인 요청이 오면\n여기에 표시됩니다")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 알림 행

    private func row(_ item: TouristNotificationItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(item.isRead ? Color.clear : Color(hex: "#EF4444"))
                .frame(width: 7, height: 7)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.time)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct TouristNotificationItem: Identifiable {
    let id: Int
    let title: String
    let time: String
    let isRead: Bool
}
