import SwiftUI

struct TodayScheduleView: View {

    @ObservedObject var viewModel: TripListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay: Int

    init(viewModel: TripListViewModel) {
        self.viewModel = viewModel
        _selectedDay = State(initialValue: viewModel.currentDayNumber)
    }

    private var schedules: [TripOfficialSchedule] {
        (viewModel.schedulesByDay[selectedDay] ?? [])
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        VStack(spacing: 0) {
            dayTabStrip
            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    if schedules.isEmpty {
                        emptyState.padding(.top, 80)
                    } else {
                        timelineList.padding(.top, 24)
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white)
        }
        .background(Color.white)
        .navigationTitle("여행 일정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
    }

    // MARK: - Day Tab Strip

    private var dayTabStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(1...max(1, viewModel.totalDays)), id: \.self) { day in
                        dayTab(day: day, proxy: proxy)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .onAppear {
                proxy.scrollTo(selectedDay, anchor: .center)
            }
        }
    }

    private func dayTab(day: Int, proxy: ScrollViewProxy) -> some View {
        let isSelected = selectedDay == day
        let isToday = day == viewModel.currentDayNumber
        let date = viewModel.date(forDay: day)
        let dateStr = shortDate(date)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDay = day
                proxy.scrollTo(day, anchor: .center)
            }
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(day)일차")
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    if isToday {
                        Text("오늘")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(HiTripColor.primary800)
                            .cornerRadius(6)
                    }
                }
                Text(dateStr)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? HiTripColor.primary800 : HiTripColor.gray400)
            }
            .foregroundColor(isSelected ? HiTripColor.textBlack : HiTripColor.gray400)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? HiTripColor.primary800.opacity(0.08) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? HiTripColor.primary800 : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .id(day)
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        VStack(spacing: 0) {
            ForEach(Array(schedules.enumerated()), id: \.element.id) { index, schedule in
                timelineRow(schedule, index: index, isLast: index == schedules.count - 1)
            }
        }
    }

    private func timelineRow(_ schedule: TripOfficialSchedule, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {

            // 타임라인 세로선 + 도트
            VStack(spacing: 0) {
                Circle()
                    .fill(HiTripColor.primary800)
                    .frame(width: 10, height: 10)
                    .padding(.top, 14)

                if !isLast {
                    Rectangle()
                        .fill(HiTripColor.gray200)
                        .frame(width: 2)
                        .frame(minHeight: 50)
                }
            }
            .frame(width: 10)

            // 카드
            VStack(alignment: .leading, spacing: 10) {

                // 시간 행
                HStack(spacing: 6) {
                    Text(schedule.timeText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(HiTripColor.primary800)
                    if let dur = schedule.durationDisplay {
                        Text("·")
                            .foregroundColor(HiTripColor.gray300)
                        Text(dur)
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray400)
                    }
                }

                // 이모지 + 장소명
                HStack(alignment: .center, spacing: 10) {
                    Text(schedule.emoji)
                        .font(.system(size: 28))
                        .frame(width: 40, height: 40)
                        .background(HiTripColor.gray100)
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(schedule.placeName ?? schedule.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(HiTripColor.textBlack)

                        if let content = schedule.mainContent, !content.isEmpty, schedule.placeName != nil {
                            Text(content)
                                .font(.system(size: 13))
                                .foregroundColor(HiTripColor.gray500)
                                .lineLimit(2)
                        }
                    }
                }

                // 이동수단/집합 뱃지
                if let detail = schedule.detailText {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(HiTripColor.primary800.opacity(0.6))
                        Text(detail)
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.primary800)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(HiTripColor.primary800.opacity(0.07))
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 12, x: 0, y: 4)
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)
            Text("\(selectedDay)일차 일정이 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)
            Text("여행사에서 일정을 등록하면 여기에 표시됩니다")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func shortDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M/d (E)"
        return fmt.string(from: date)
    }
}
