import SwiftUI

// MARK: - TripCalendarView
/// 화면3: 캘린더 탭 — 월간 캘린더 + 오늘의 일정
///
/// 피그마 디자인:
/// - 월 숫자 (큰 텍스트)
/// - 카테고리 범례 (여행지, 목록, 일정, 기타)
/// - 월간 캘린더 그리드 (이벤트 날짜에 색상 도트)
/// - "오늘의 일정" 타임라인 리스트
/// - FAB (+) 일정 추가 버튼

struct TripCalendarView: View {

    @ObservedObject var viewModel: TripDetailViewModel

    private let calendar = Calendar.current
    private let daysOfWeek = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 월 표시
                    monthHeader
                        .padding(.top, 16)
                        .padding(.horizontal, 24)

                    // 카테고리 범례
                    categoryLegend
                        .padding(.top, 12)
                        .padding(.horizontal, 24)

                    // 요일 헤더
                    weekdayHeader
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    // 월간 캘린더 그리드
                    monthGrid
                        .padding(.top, 8)
                        .padding(.horizontal, 20)

                    // "오늘의 일정" 섹션
                    todayEventsSection
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 80)
                }
            }

            // FAB (+) 버튼
            fabButton
                .padding(.trailing, 24)
                .padding(.bottom, 24)
        }
        // 이벤트 추가 시트
        .sheet(isPresented: $viewModel.showAddEventSheet) {
            addEventSheet
        }
    }

    // MARK: - Add Event Sheet

    private var addEventSheet: some View {
        NavigationStack {
            Form {
                Section("일정 정보") {
                    TextField("일정 제목", text: $viewModel.newEventTitle)

                    DatePicker("시작 시간", selection: $viewModel.newEventStartTime, displayedComponents: [.date, .hourAndMinute])

                    DatePicker("종료 시간", selection: $viewModel.newEventEndTime, displayedComponents: [.date, .hourAndMinute])

                    Picker("카테고리", selection: $viewModel.newEventCategory) {
                        ForEach(TripEvent.Category.allCases, id: \.self) { category in
                            HStack {
                                Circle().fill(category.color).frame(width: 10, height: 10)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.editingEventId != nil ? "일정 수정" : "일정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { viewModel.resetEventForm() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") { viewModel.addEvent() }
                        .disabled(viewModel.newEventTitle.trimmed.isEmpty)
                }
            }
        }
    }

    // MARK: - Month Header

    /// 큰 월 표시 (예: "4월")
    private var monthHeader: some View {
        Text("\(calendar.component(.month, from: viewModel.displayedMonth))월")
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(HiTripColor.textBlack)
    }

    // MARK: - Category Legend

    /// 카테고리 범례 (피그마: 여행지, 목록, 일정, 기타)
    private var categoryLegend: some View {
        HStack(spacing: 12) {
            ForEach(TripEvent.Category.allCases, id: \.self) { category in
                HStack(spacing: 4) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 8, height: 8)
                    Text(category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray500)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(HiTripColor.gray100)
                .cornerRadius(12)
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

    /// 월간 캘린더 날짜 그리드
    private var monthGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                        .onTapGesture {
                            viewModel.selectedDate = date
                        }
                } else {
                    // 빈 셀 (이전/다음 달의 빈 칸)
                    Text("")
                        .frame(height: 44)
                }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
        let isToday = calendar.isDateInToday(date)
        let categories = viewModel.eventCategories(for: date)

        return VStack(spacing: 2) {
            // 날짜 숫자
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday ? .bold : .regular))
                .foregroundColor(
                    isSelected ? .white :
                    isToday ? HiTripColor.primary800 :
                    HiTripColor.textBlack
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isSelected ? HiTripColor.primary800 : Color.clear)
                )

            // 이벤트 카테고리 도트들
            HStack(spacing: 2) {
                ForEach(categories.prefix(3), id: \.self) { category in
                    Circle()
                        .fill(category.color)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 44)
    }

    // MARK: - Today Events Section

    private var todayEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 일정")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            if viewModel.eventsForSelectedDate.isEmpty {
                Text("선택한 날짜에 일정이 없습니다.")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray400)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.eventsForSelectedDate) { event in
                    TripEventRow(
                        event: event,
                        onEdit: { viewModel.prepareEditEvent(event) },
                        onDelete: { withAnimation { viewModel.deleteEvent(event.id) } }
                    )
                }
            }
        }
    }

    // MARK: - FAB Button

    /// 플로팅 액션 버튼 — 일정 추가
    private var fabButton: some View {
        Button { viewModel.prepareAddEvent() } label: {
            Circle()
                .fill(HiTripColor.primary800)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: HiTripColor.primary800.opacity(0.3), radius: 8, y: 4)
        }
    }

    // MARK: - Calendar Helpers

    /// 현재 월의 날짜 배열 (빈 칸 포함)
    /// 월요일 시작 기준으로 앞쪽 빈 칸을 nil로 채움
    private func daysInMonth() -> [Date?] {
        let month = viewModel.displayedMonth

        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        // 첫째 날의 요일 (월=0, 화=1, ... 일=6)
        var weekday = calendar.component(.weekday, from: firstDay)
        // .weekday: 1=일, 2=월, ..., 7=토 → 월요일 시작으로 변환
        weekday = (weekday + 5) % 7  // 월=0, 화=1, ... 일=6

        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }
}
