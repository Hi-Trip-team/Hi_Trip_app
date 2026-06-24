import SwiftUI

// MARK: - TripCalendarView
/// 캘린더 탭 — 월간 캘린더 + 날짜별 공식 일정
///
/// 데이터: TripDataStore → TripDetailViewModel → officialSchedulesForSelectedDate
/// 캘린더 도트: 서버 공식 일정이 있는 날짜에 파란 도트 표시
/// 하단 리스트: 선택 날짜의 공식 일정 타임라인

struct TripCalendarView: View {

    @ObservedObject var viewModel: TripDetailViewModel

    private let calendar = Calendar.current
    private let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 월 + 이동 버튼
                monthHeader
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                // 요일 헤더
                weekdayHeader
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // 월간 캘린더 그리드
                monthGrid
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                // 선택 날짜 공식 일정
                officialScheduleSection
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { viewModel.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HiTripColor.gray500)
            }

            Spacer()

            Text("\(calendar.component(.year, from: viewModel.displayedMonth))년 \(calendar.component(.month, from: viewModel.displayedMonth))월")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            Button { viewModel.goToNextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HiTripColor.gray500)
            }
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HiTripColor.gray400)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                        .onTapGesture { viewModel.selectedDate = date }
                } else {
                    Text("").frame(height: 44)
                }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday    = calendar.isDateInToday(date)
        let hasSchedule = viewModel.hasOfficialSchedule(on: date)

        return VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday ? .bold : .regular))
                .foregroundColor(
                    isSelected ? .white :
                    isToday    ? HiTripColor.primary800 :
                    HiTripColor.textBlack
                )
                .frame(width: 32, height: 32)
                .background(Circle().fill(isSelected ? HiTripColor.primary800 : Color.clear))

            // 공식 일정 있는 날 파란 도트
            Circle()
                .fill(hasSchedule ? HiTripColor.primary800.opacity(isSelected ? 0 : 0.6) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(height: 44)
    }

    // MARK: - Official Schedule Section

    private var officialScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateLabel)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
                Spacer()
                if !viewModel.officialSchedulesForSelectedDate.isEmpty {
                    Text("\(viewModel.officialSchedulesForSelectedDate.count)개")
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray400)
                }
            }

            if viewModel.officialSchedulesForSelectedDate.isEmpty {
                emptyScheduleView
            } else {
                scheduleTimeline
            }
        }
    }

    private var selectedDateLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일 (E)"
        return fmt.string(from: viewModel.selectedDate)
    }

    private var emptyScheduleView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 32))
                    .foregroundColor(HiTripColor.gray300)
                Text("이 날의 공식 일정이 없습니다")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray400)
            }
            .padding(.vertical, 32)
            Spacer()
        }
    }

    private var scheduleTimeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.officialSchedulesForSelectedDate.enumerated()), id: \.element.id) { index, schedule in
                calendarScheduleRow(
                    schedule,
                    isLast: index == viewModel.officialSchedulesForSelectedDate.count - 1
                )
            }
        }
    }

    private func calendarScheduleRow(_ schedule: TripOfficialSchedule, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 타임라인
            VStack(spacing: 0) {
                Circle()
                    .fill(HiTripColor.primary800)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)
                if !isLast {
                    Rectangle()
                        .fill(HiTripColor.gray200)
                        .frame(width: 2)
                        .frame(minHeight: 48)
                }
            }
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // 시간
                Text(timeRange(schedule))
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)

                // 이모지 + 제목
                HStack(spacing: 6) {
                    Text(schedule.emoji ?? "📍")
                        .font(.system(size: 18))
                    Text(schedule.placeName ?? schedule.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(HiTripColor.textBlack)
                }

                // 주요 내용
                if let content = schedule.mainContent, !content.isEmpty, schedule.placeName != nil {
                    Text(content)
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray500)
                }

                // 이동 수단
                if let transport = schedule.transport {
                    Label(transport, systemImage: "figure.walk")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.primary800.opacity(0.7))
                }
            }
            .padding(.bottom, 20)

            Spacer()
        }
    }

    private func timeRange(_ schedule: TripOfficialSchedule) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "\(fmt.string(from: schedule.startTime)) ~ \(fmt.string(from: schedule.endTime))"
    }

    // MARK: - Calendar Helpers

    private func daysInMonth() -> [Date?] {
        let month = viewModel.displayedMonth
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        var weekday = calendar.component(.weekday, from: firstDay)
        weekday = (weekday + 5) % 7  // 월요일 시작

        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}
