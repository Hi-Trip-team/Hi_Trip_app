import SwiftUI

// MARK: - WeekCalendarStripView
/// 주간 캘린더 스트립 — 화면1(최근 일정)과 화면2(할일)에서 공용
///
/// 피그마 디자인:
/// - 좌우 화살표로 주(week) 이동
/// - 요일 라벨 (S M T W T F S 또는 월 화 수 목 금 토 일)
/// - 날짜 숫자 — 선택된 날짜는 파란 원 배경
///
/// 사용:
/// ```swift
/// WeekCalendarStripView(
///     selectedDate: $viewModel.selectedDate,
///     style: .sundayStart   // 화면1: 일요일 시작
/// )
/// ```

struct WeekCalendarStripView: View {

    @Binding var selectedDate: Date

    /// 주 시작 요일 스타일
    var style: WeekStyle = .mondayStart

    /// 날짜 탭 시 콜백 (nil이면 selectedDate 바인딩만 변경)
    var onDateTap: ((Date) -> Void)?

    enum WeekStyle {
        case sundayStart   // 화면1: S M T W T F S
        case mondayStart   // 화면2: 월 화 수 목 금 토 일
    }

    /// 표시 중인 주의 기준 날짜
    @State private var weekOffset: Int = 0

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            // 상단: 날짜 텍스트 + 좌우 화살표
            headerRow

            // 요일 + 날짜 그리드
            weekDaysRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(headerDateText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            HStack(spacing: 16) {
                Button { weekOffset -= 1 } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HiTripColor.gray500)
                }

                Button { weekOffset += 1 } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(HiTripColor.gray500)
                }
            }
        }
    }

    // MARK: - Week Days Row

    private var weekDaysRow: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { date in
                VStack(spacing: 6) {
                    // 요일 라벨
                    Text(dayLabel(for: date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isToday(date) ? HiTripColor.primary800 : HiTripColor.gray400)

                    // 날짜 숫자
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 16, weight: isSelected(date) ? .bold : .medium))
                        .foregroundColor(isSelected(date) ? .white : HiTripColor.textBlack)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isSelected(date) ? HiTripColor.primary800 : Color.clear)
                        )
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    selectedDate = date
                    onDateTap?(date)
                }
            }
        }
    }

    // MARK: - Helpers

    /// 헤더에 표시할 날짜 텍스트 (예: "4월")
    /// 표시 중인 주의 중간 날짜 기준으로 월 표시 — '>' 클릭 시 자동 변경
    private var headerDateText: String {
        let days = weekDays
        // 주의 중간(4번째) 날짜 기준으로 월 표시
        let referenceDate = days.isEmpty ? selectedDate : days[min(3, days.count - 1)]
        let month = calendar.component(.month, from: referenceDate)
        return "\(month)월"
    }

    /// 현재 표시 중인 주의 7일 배열
    private var weekDays: [Date] {
        let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()

        // 주의 시작일 계산
        var cal = calendar
        cal.firstWeekday = style == .sundayStart ? 1 : 2  // 1=일요일, 2=월요일

        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: baseDate)?.start else {
            return []
        }

        return (0..<7).compactMap { day in
            cal.date(byAdding: .day, value: day, to: weekStart)
        }
    }

    /// 요일 라벨
    private func dayLabel(for date: Date) -> String {
        switch style {
        case .sundayStart:
            let symbols = ["S", "M", "T", "W", "T", "F", "S"]
            let weekday = calendar.component(.weekday, from: date)
            return symbols[weekday - 1]
        case .mondayStart:
            let symbols = ["일", "월", "화", "수", "목", "금", "토"]
            let weekday = calendar.component(.weekday, from: date)
            return symbols[weekday - 1]
        }
    }

    /// 오늘 날짜인지
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// 선택된 날짜인지
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
}
