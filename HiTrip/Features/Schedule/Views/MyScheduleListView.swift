import SwiftUI

// MARK: - MyScheduleListView
/// "내 일정" 탭 — 선택 날짜의 공식 일정을 개별 카드로 표시
///
/// 카드 하나 = 장소 하나 (인천국제공항, 마담란 레스토랑, 대성당 등)

struct MyScheduleListView: View {

    @ObservedObject var viewModel: TripDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.officialSchedulesForSelectedDate.isEmpty {
                    emptyState
                        .padding(.top, 60)
                } else {
                    scheduleCardList
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 40)
            }
        }
        .background(HiTripColor.screenBackground)
    }

    // MARK: - Card List

    private var scheduleCardList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.officialSchedulesForSelectedDate) { schedule in
                scheduleCard(schedule)
            }
        }
    }

    private func scheduleCard(_ schedule: TripOfficialSchedule) -> some View {
        HStack(spacing: 14) {
            // 이모지 썸네일
            ZStack {
                HiTripColor.primary800.opacity(0.08)
                Text(schedule.emoji ?? "📍")
                    .font(.system(size: 28))
            }
            .frame(width: 68, height: 68)
            .cornerRadius(14)

            VStack(alignment: .leading, spacing: 6) {
                // 시간
                Text(timeRange(schedule))
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)

                // 장소명
                Text(schedule.placeName ?? schedule.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
                    .lineLimit(1)

                // 주요 내용 또는 이동 수단
                if let content = schedule.mainContent, !content.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray400)
                        Text(content)
                            .font(.system(size: 13))
                            .foregroundColor(HiTripColor.gray400)
                            .lineLimit(1)
                    }
                } else if let transport = schedule.transport {
                    HStack(spacing: 4) {
                        Image(systemName: transportIcon(transport))
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray400)
                        Text(transport)
                            .font(.system(size: 13))
                            .foregroundColor(HiTripColor.gray400)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HiTripColor.gray300)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .hiTripCard()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)

            Text("이 날의 공식 일정이 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Text("다른 날짜를 선택해보세요")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func timeRange(_ schedule: TripOfficialSchedule) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "\(fmt.string(from: schedule.startTime)) ~ \(fmt.string(from: schedule.endTime))"
    }

    private func transportIcon(_ transport: String) -> String {
        switch transport {
        case "도보":    return "figure.walk"
        case "전용버스": return "bus"
        case "자가용":  return "car"
        case "택시":    return "car.side"
        case "공항버스": return "airplane"
        default:       return "arrow.right"
        }
    }
}
