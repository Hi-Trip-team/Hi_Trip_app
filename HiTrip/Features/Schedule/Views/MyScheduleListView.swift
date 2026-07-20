import SwiftUI

// MARK: - MyScheduleListView
/// "내 일정" 탭 — 선택 날짜의 공식 일정을 개별 카드로 표시

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
        .background(Color.white)
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
            // 썸네일 (이모지 배경)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(HiTripColor.gray100)
                Text(schedule.emoji)
                    .font(.system(size: 32))
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                // 날짜
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(HiTripColor.gray400)
                    Text(dateLabel(schedule.date))
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray400)
                }

                // 장소명 (제목)
                Text(schedule.placeName ?? schedule.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
                    .lineLimit(1)

                // 위치 / 내용
                if let content = schedule.mainContent, !content.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 11))
                            .foregroundColor(HiTripColor.gray400)
                        Text(content)
                            .font(.system(size: 13))
                            .foregroundColor(HiTripColor.gray400)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HiTripColor.gray300)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 10, x: 0, y: 2)
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

    private func dateLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy년 M월 d일"
        return fmt.string(from: date)
    }
}
