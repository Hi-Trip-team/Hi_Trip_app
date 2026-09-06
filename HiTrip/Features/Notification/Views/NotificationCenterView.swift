import SwiftUI

struct NotificationCenterView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter = "전체"

    private let filters = ["전체", "위험", "경고", "이탈", "일반"]

    private let notifications: [NCItem] = [
        NCItem(type: "위험", title: "에디님의 심박수가 위험 수치입니다! 바로 확인하세요!",
               detail: "10:24 · 심박 187bpm", time: "10:24", requiresAction: true),
        NCItem(type: "이탈", title: "둘리님이 안전 구역을 벗어났습니다 (1.2km)",
               detail: "10:18 · 탭하여 위치 확인", time: "10:18", requiresAction: false),
        NCItem(type: "경고", title: "펭수님의 심박수가 경고 수치입니다. 확인이 필요합니다.",
               detail: "09:52 · 심박 135bpm", time: "09:52", requiresAction: false),
        NCItem(type: "일반", title: "일정이 변경되었습니다 — 2일차 13:00 점심 장소 변경",
               detail: "09:30", time: "09:30", requiresAction: false),
    ]

    private var filtered: [NCItem] {
        selectedFilter == "전체" ? notifications : notifications.filter { $0.type == selectedFilter }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            filterRow
                .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filtered) { item in
                        notificationCard(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - Header

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

    // MARK: - 필터 칩

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { f in
                    Button { selectedFilter = f } label: {
                        Text(f)
                            .font(.system(size: 12, weight: selectedFilter == f ? .bold : .medium))
                            .foregroundColor(selectedFilter == f ? .white : Color(hex: "#6B7280"))
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .background(selectedFilter == f ? Color(hex: "#2563EB") : Color(hex: "#F3F4F6"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 4)
    }

    // MARK: - 알림 카드

    private func notificationCard(_ item: NCItem) -> some View {
        let colors = badgeColors(item.type)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Text(item.type)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 10)
                    .frame(height: 22)
                    .background(colors.bg)
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#111827"))
                        .fixedSize(horizontal: false, vertical: true)
                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                }

                Spacer()
            }

            if item.requiresAction {
                HStack {
                    Spacer()
                    Button { } label: {
                        Text("확인")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#EF4444"))
                            .frame(width: 60, height: 32)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#EF4444"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Text("[확인] 전까지 5분 주기 재알림")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#EF4444"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(colors.cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colors.border, lineWidth: 1)
        )
    }

    private func badgeColors(_ type: String) -> (bg: Color, text: Color, cardBg: Color, border: Color) {
        switch type {
        case "위험", "이탈":
            return (Color(hex: "#FCE5E5"), Color(hex: "#EF4444"),
                    Color(hex: "#FFF5F5"), Color(hex: "#FECACA"))
        case "경고":
            return (Color(hex: "#FFF2D9"), Color(hex: "#EB8C0D"),
                    Color(hex: "#FFFBF0"), Color(hex: "#FDE68A"))
        default:
            return (Color(hex: "#E8F0FF"), Color(hex: "#2563EB"),
                    Color(hex: "#F8FAFF"), Color(hex: "#BFDBFE"))
        }
    }
}

private struct NCItem: Identifiable {
    let id = UUID()
    let type: String
    let title: String
    let detail: String
    let time: String
    let requiresAction: Bool
}
