import SwiftUI

// MARK: - NotificationCenterView
/// 알림 센터 화면
///
/// 피그마 0827 수정본:
/// - 헤더: 뒤로가기 + "알림"
/// - 카테고리 탭 필터: 전체 / 위험 / 경고 / 이탈 / 알반
/// - 알림 목록: NotificationItemView
/// - 위험 알림은 "확인" 버튼 포함 (빨간)

struct NotificationCenterView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: NotificationCategory = .all
    @State private var items: [NotificationItem] = Self.mockItems

    private var filteredItems: [NotificationItem] {
        guard selectedCategory != .all else { return items }
        return items.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryTabBar
                    .padding(.top, HiTripSpacing.md)

                Divider()
                    .padding(.top, HiTripSpacing.sm)

                if filteredItems.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
            .background(HiTripColor.screenBackground)
            .navigationTitle("알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
            }
        }
    }

    // MARK: - Category Tab Bar

    private var categoryTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HiTripSpacing.sm) {
                ForEach(NotificationCategory.allCases) { cat in
                    categoryTab(cat)
                }
            }
            .padding(.horizontal, HiTripSpacing.pagePadding)
        }
    }

    private func categoryTab(_ cat: NotificationCategory) -> some View {
        let isSelected = selectedCategory == cat
        return Button {
            selectedCategory = cat
        } label: {
            Text(cat.rawValue)
                .font(HiTripFont.labelM)
                .foregroundColor(isSelected ? .white : HiTripColor.gray500)
                .padding(.horizontal, HiTripSpacing.mdl)
                .padding(.vertical, HiTripSpacing.sm)
                .background(isSelected ? categoryColor(cat) : HiTripColor.gray100)
                .cornerRadius(HiTripRadius.pill)
        }
        .buttonStyle(.plain)
    }

    private func categoryColor(_ cat: NotificationCategory) -> Color {
        switch cat {
        case .danger:  return HiTripColor.danger
        case .leave:   return HiTripColor.caution
        case .warning: return HiTripColor.warningYellow
        case .normal:  return HiTripColor.gray400
        case .all:     return HiTripColor.primary800
        }
    }

    // MARK: - Notification List

    private var notificationList: some View {
        ScrollView {
            VStack(spacing: HiTripSpacing.sm) {
                ForEach(filteredItems) { item in
                    NotificationItemView(item: item) {
                        actionItem(item)
                    }
                }
            }
            .padding(.horizontal, HiTripSpacing.pagePadding)
            .padding(.top, HiTripSpacing.md)
            .padding(.bottom, HiTripSpacing.xxl)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: HiTripSpacing.md) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)
            Text("알림이 없습니다")
                .font(HiTripFont.bodyBold)
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
        }
    }

    // MARK: - Actions

    private func actionItem(_ item: NotificationItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isActioned = true
        }
    }

    // MARK: - Mock Data

    private static var mockItems: [NotificationItem] = [
        NotificationItem(
            category: .danger,
            title: "에디님의 심박수가 위험 수치입니다! 바로 확인하세요!",
            subtitle: "10:24 · 심박 187bpm",
            time: "10:24",
            requiresAction: true
        ),
        NotificationItem(
            category: .leave,
            title: "돌리님이 안전 구역을 벗어났습니다 (1.2km)",
            subtitle: "10:18 · 멤버 위치 확인",
            time: "10:18"
        ),
        NotificationItem(
            category: .warning,
            title: "팽수님의 심박수가 경고 수치입니다. 확인이 필요합니다.",
            subtitle: "09:52 · 심박 135bpm",
            time: "09:52"
        ),
        NotificationItem(
            category: .normal,
            title: "일정이 변경되었습니다 — 2일차 13:00 점심 장소 변경",
            subtitle: "",
            time: "09:30"
        )
    ]
}
