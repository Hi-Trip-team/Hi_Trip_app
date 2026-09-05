import SwiftUI

struct StaffTripDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var showContextMenu: Int? = nil

    private let day1Items = [
        ScheduleItem(title: "숙소로 이동", time: "09:00 - 10:00"),
        ScheduleItem(title: "부산시민공원", time: "10:00 - 11:30"),
        ScheduleItem(title: "포폴로피자 (중식)", time: "12:00 - 13:30"),
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    headerSection

                    // 여행 정보 카드
                    tripInfoCard
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // 1일차 섹션
                    daySection(
                        day: "1일차",
                        date: "2025.04.24 12:00 출발",
                        isExpanded: true,
                        items: day1Items,
                        dayIndex: 0
                    )
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                    // + 일정 추가 버튼
                    addScheduleButton
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    // 2일차 섹션 (접힘)
                    collapsedDaySection(day: "2일차", date: "2025.04.25")
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
            }
            .background(Color.white)

            // 컨텍스트 메뉴
            if showContextMenu != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { showContextMenu = nil }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("전체 일정")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
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

    // MARK: - 여행 정보 카드

    private var tripInfoCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("뉴진스 바다여행")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            Text("2025.04.24 - 04.26 · 참여 인원 10명")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .frame(height: 72)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
    }

    // MARK: - 일차 섹션 (펼침)

    private func daySection(day: String, date: String, isExpanded: Bool, items: [ScheduleItem], dayIndex: Int) -> some View {
        VStack(spacing: 8) {
            // 일차 헤더
            HStack {
                Text(day)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 24)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(6)
                Text(date)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                Spacer()
                Text("∧")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color(hex: "#E8F0FF"))
            .cornerRadius(12)

            // 스케줄 아이템들
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                ZStack(alignment: .topTrailing) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#111827"))
                            Text(item.time)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#6B7280"))
                        }
                        Spacer()
                        Button {
                            showContextMenu = showContextMenu == idx ? nil : idx
                        } label: {
                            Text("⋮")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#6B7280"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
                    )

                    // 컨텍스트 메뉴
                    if showContextMenu == idx {
                        contextMenu
                            .offset(x: -8, y: 36)
                    }
                }
                .zIndex(showContextMenu == idx ? 10 : 0)
            }
        }
    }

    // MARK: - 컨텍스트 메뉴

    private var contextMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuRow(title: "시간 변경", color: Color(hex: "#111827"))
            Divider()
            menuRow(title: "메모 수정", color: Color(hex: "#111827"))
            Divider()
            menuRow(title: "삭제", color: Color(hex: "#EF4444"))
        }
        .frame(width: 150)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private func menuRow(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 13))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .frame(height: 44)
    }

    // MARK: - + 일정 추가

    private var addScheduleButton: some View {
        Button { } label: {
            Text("+ 일정 추가")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#2563EB"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#6B7280").opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 접힌 일차 섹션

    private func collapsedDaySection(day: String, date: String) -> some View {
        HStack {
            Text(day)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 48, height: 24)
                .background(Color(hex: "#E5E7EB"))
                .cornerRadius(6)
            Text(date)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#6B7280"))
            Spacer()
            Text("∨")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
    }
}

private struct ScheduleItem {
    let title: String
    let time: String
}
