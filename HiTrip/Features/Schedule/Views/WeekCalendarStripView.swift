import SwiftUI

// MARK: - WeekCalendarStripView
/// 주간 캘린더 스트립 — 공용 컴포넌트
///
/// 피그마 디자인:
/// - 헤더: "10월 22일" + 좌우 화살표(< >)
/// - 요일 라벨: S M T W T F S (일요일 시작)
/// - 날짜 숫자: 선택된 날짜는 파란 둥근사각 배경 (radius 16)
/// - 전체 카드: 흰색 배경, radius 24 (외부에서 적용)

struct WeekCalendarStripView: View {

    @Binding var selectedDate: Date

    /// 주 시작 요일 스타일
    var style: WeekStyle = .sundayStart

    /// 날짜 탭 시 콜백 (nil이면 selectedDate 바인딩만 변경)
    var onDateTap: ((Date) -> Void)?

    enum WeekStyle {
        case sundayStart   // S M T W T F S
        case mondayStart   // 월 화 수 목 금 토 일
    }

    /// 표시 중인 주의 기준 날짜
    @State private var weekOffset: Int = 0

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // 상단: 날짜 텍스트 + 좌우 화살표
            headerRow

            // 요일 라벨 + 날짜 숫자 (간격 좁게)
            VStack(spacing: 4) {
                weekdayLabels
                weekDaysRow
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Header

    /// 피그마: "10월 22일" + < > 화살표
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

    // MARK: - Weekday Labels

    /// 요일 라벨 행 (S M T W T F S)
    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { date in
                Text(dayLabel(for: date))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HiTripColor.gray400)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Week Days Row

    /// 날짜 숫자 행 — 선택된 날짜는 파란 RoundedRectangle(16)
    private var weekDaysRow: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { date in
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected(date) ? .bold : .medium))
                    .foregroundColor(isSelected(date) ? .white : HiTripColor.textBlack)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSelected(date) ? HiTripColor.primary800 : Color.clear)
                    )
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        selectedDate = date
                        onDateTap?(date)
                    }
            }
        }
    }

    // MARK: - Helpers

    /// 헤더 날짜 텍스트 — 피그마: "10월 22일"
    /// 선택된 날짜 기준으로 표시
    private var headerDateText: String {
        let month = calendar.component(.month, from: selectedDate)
        let day = calendar.component(.day, from: selectedDate)
        return "\(month)월 \(day)일"
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

    /// 선택된 날짜인지
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
}
