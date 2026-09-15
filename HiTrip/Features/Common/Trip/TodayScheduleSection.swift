import SwiftUI

// MARK: - 홈 "오늘의 일정" 공통 부품
/// 여행객 홈과 안내사 홈이 같이 씁니다 (기준: 여행객 홈).
///
/// 진행률 카드 → "오늘의 일정" → 현재 일정(없으면 안내 문구) → 다음 일정 → 전체일정 링크.
/// 판정(현재·다음·문구)은 각 ViewModel이 TripClock으로 만들고, 여기서는 그리기만 합니다.

/// 홈 일정 한 줄에 필요한 값 — 정규(공용)·개인 일정, 여행객·안내사 DTO를 같은 모양으로 다룹니다
struct ScheduleSummary: Equatable {
    let id: String
    let title: String
    let startTime: String
    let endTime: String
    let dayNumber: Int
    var isPersonal: Bool = false

    /// 일차 → 시작 시각 순서로 비교하는 키
    var sortKey: String { String(format: "%03d ", dayNumber) + startTime }

    /// "09:00 - 10:30"
    var timeRangeText: String { "\(AppDate.hhmm(startTime)) - \(AppDate.hhmm(endTime))" }
}

struct TodayScheduleSection<ProgressCard: View>: View {

    /// 여행 기간 밖(시작 전·종료 후)이면 일정 대신 보여줄 문구
    var phaseMessage: String?
    let current: ScheduleSummary?
    /// 진행 중인 일정이 없을 때 문구
    let noCurrentText: String
    let next: ScheduleSummary?
    let linkTitle: String
    /// 일정을 누르면 그 일차, 링크를 누르면 nil
    let onOpenDay: (Int?) -> Void
    @ViewBuilder let progressCard: () -> ProgressCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressCard()
                .padding(.horizontal, 21)
                .padding(.bottom, AppSpacing.lg)

            Text("오늘의 일정")
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.md)

            if let phaseMessage {
                ScheduleMessageBox(text: phaseMessage)
            } else {
                // 지금 진행 중인 일정 — 예정 일정은 "다음 일정"에만
                if let current {
                    ScheduleSummaryRow(item: current, height: 64, titleFont: AppFont.bodyMMedium) {
                        onOpenDay(current.dayNumber)
                    }
                } else {
                    ScheduleMessageBox(text: noCurrentText)
                }

                // 다음 일정 — 없으면 레이블째 숨김
                if let next {
                    Text("다음 일정")
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textSecondary)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.top, 14)
                        .padding(.bottom, 6)

                    ScheduleSummaryRow(item: next, height: 48, titleFont: AppFont.bodyMedium) {
                        onOpenDay(next.dayNumber)
                    }
                }
            }

            Button { onOpenDay(nil) } label: {
                Text(linkTitle)
                    .font(AppFont.labelMedium)
                    .foregroundColor(AppColor.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
    }
}

/// 홈 일정 한 줄 — 개인 일정이면 앞에 "내 일정" 표시
struct ScheduleSummaryRow: View {
    let item: ScheduleSummary
    let height: CGFloat
    let titleFont: Font
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if item.isPersonal {
                Text("내 일정")
                    .font(AppFont.caption2Bold)
                    .foregroundColor(AppColor.accent)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(AppColor.accentSubtle)
                    .cornerRadius(AppRadius.xs)
            }
            Text(item.title)
                .font(titleFont)
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(item.timeRangeText)
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: height)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.lg)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .padding(.horizontal, AppSpacing.xl)
    }
}

/// 일정 칸 자리에 보여주는 안내 — 진행 중인 일정 없음 · 여행 시작 전 · 종료 후
struct ScheduleMessageBox: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.body)
            .foregroundColor(AppColor.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.lg)
            .padding(.horizontal, AppSpacing.xl)
    }
}
