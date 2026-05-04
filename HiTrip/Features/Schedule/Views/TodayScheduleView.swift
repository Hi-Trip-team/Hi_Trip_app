import SwiftUI

// MARK: - TodayScheduleView
/// 오늘의 일정 전체 보기 화면
///
/// 여행사가 그룹에 등록한 공식 일정(TripOfficialSchedule)을
/// 타임라인 형태로 표시한다.
///
/// 홈 화면 "오늘의 일정" → "전체 보기 >" 탭 시 이동.
///
/// 디자인:
/// - 타임라인 형태: 시간순 정렬
/// - 각 일정: 이모지 + 제목 + 시간 + 연결선

struct TodayScheduleView: View {

    @ObservedObject var viewModel: TripListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.todaySchedules.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    timelineList
                        .padding(.top, 20)
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(HiTripColor.screenBackground)
        .navigationTitle("오늘의 일정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.todaySchedules.enumerated()), id: \.element.id) { index, schedule in
                timelineRow(schedule, isLast: index == viewModel.todaySchedules.count - 1)
            }
        }
    }

    // MARK: - Timeline Row

    private func timelineRow(_ schedule: TripOfficialSchedule, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // 왼쪽: 타임라인 도트 + 연결선
            VStack(spacing: 0) {
                // 도트
                Circle()
                    .fill(HiTripColor.primary800)
                    .frame(width: 12, height: 12)

                // 연결선
                if !isLast {
                    Rectangle()
                        .fill(HiTripColor.gray200)
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }

            // 오른쪽: 일정 카드
            VStack(alignment: .leading, spacing: 8) {
                // 시간
                Text(schedule.timeText)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray500)

                // 이모지 + 제목
                HStack(spacing: 8) {
                    Text(schedule.emoji)
                        .font(.system(size: 24))

                    Text(schedule.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color(hex: "B4BCC9").opacity(0.12), radius: 12, x: 0, y: 4)

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)

            Text("오늘 등록된 일정이 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Text("여행사에서 일정을 등록하면 여기에 표시됩니다")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
        }
    }
}
