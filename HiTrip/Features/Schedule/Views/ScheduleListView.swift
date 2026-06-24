import SwiftUI

// MARK: - ScheduleListView
/// 서버 공식 일정 목록 화면 (읽기 전용)
///
/// 데이터: TripDataStore → ScheduleViewModel → officialSchedulesByDay
/// 구성: 일차 탭 선택 → 해당 일차 일정 타임라인

struct ScheduleListView: View {

    @StateObject private var viewModel = ScheduleViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isEmpty {
                    emptyView
                } else {
                    scheduleContent
                }
            }
            .navigationTitle("공식 일정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Day Selector + Content

    private var scheduleContent: some View {
        VStack(spacing: 0) {
            dayTabBar
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.schedulesForSelectedDay) { schedule in
                        OfficialScheduleRow(schedule: schedule)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Day Tab Bar

    private var dayTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.sortedDayNumbers, id: \.self) { day in
                    Button {
                        viewModel.selectedDayNumber = day
                    } label: {
                        Text(viewModel.dayLabel(day))
                            .font(.system(size: 14, weight: viewModel.selectedDayNumber == day ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedDayNumber == day ? .white : HiTripColor.gray500)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedDayNumber == day ? HiTripColor.primary800 : Color.clear)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack { Spacer(); ProgressView("일정 불러오는 중..."); Spacer() }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 50))
                .foregroundColor(HiTripColor.gray300)
            Text("등록된 공식 일정이 없습니다")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(HiTripColor.gray500)
            Spacer()
        }
    }
}

// MARK: - OfficialScheduleRow

struct OfficialScheduleRow: View {

    let schedule: TripOfficialSchedule

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text(schedule.emoji ?? "📍")
                    .font(.system(size: 20))
                Rectangle()
                    .fill(HiTripColor.gray200)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(timeRange)
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)

                Text(schedule.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                if let place = schedule.placeName, !place.isEmpty {
                    Label(place, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray500)
                }

                if let transport = schedule.transport, !transport.isEmpty {
                    Label(transport, systemImage: "figure.walk")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray400)
                }

                if let content = schedule.mainContent, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray500)
                        .lineLimit(2)
                }
            }
            .padding(.bottom, 20)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var timeRange: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "\(fmt.string(from: schedule.startTime)) ~ \(fmt.string(from: schedule.endTime))"
    }
}
