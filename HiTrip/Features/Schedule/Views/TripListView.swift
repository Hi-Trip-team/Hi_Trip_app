import SwiftUI

// MARK: - TripListView
/// 화면1: 최근 일정 — 피그마 디자인
///
/// UI 구성:
/// - 네비게이션 바: 뒤로가기 + "최근 일정" + 알림 아이콘
/// - 주간 캘린더 스트립 (날짜 선택)
/// - 선택한 날짜의 일정 + 투두 미리보기
/// - "내 일정" 섹션 + "View all" 링크
/// - 여행 카드 리스트 (썸네일 + 날짜 + 제목 + 위치)

struct TripListView: View {

    @StateObject private var viewModel = TripListViewModel()
    @EnvironmentObject var router: AppRouter

    /// "View all" 클릭 → AllTripsView로 이동
    @State private var navigateToAllTrips: Bool = false

    /// 내 일정 카드 클릭 → 상세보기 (SpotDetailView 스타일)
    @State private var selectedTripForDetail: Trip?

    /// 투두 탭 → 해당 Trip 상세 (할일 탭)로 이동
    @State private var navigateToTripDetail: Bool = false
    @State private var selectedTripForNav: Trip?

    /// 이벤트 탭 → 해당 Trip 상세 (캘린더 탭)로 이동
    @State private var navigateToCalendar: Bool = false
    @State private var selectedTripForCalendar: Trip?

    var body: some View {
        NavigationStack {
            ZStack {
                HiTripColor.screenBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // 주간 캘린더 스트립
                        calendarCard

                        // 선택한 날짜의 일정 + 투두
                        dailyScheduleSection
                            .padding(.top, 16)

                        // "내 일정" 헤더
                        sectionHeader
                            .padding(.top, 24)

                        // 여행 카드 리스트
                        tripCardList
                            .padding(.top, 12)

                        Spacer().frame(height: 24)
                    }
                }
            }
            // "View all" → 전체 일정 리스트
            .navigationDestination(isPresented: $navigateToAllTrips) {
                AllTripsView()
            }
            // 투두 영역 탭 → Trip 상세 (할일 탭)
            .navigationDestination(isPresented: $navigateToTripDetail) {
                if let trip = selectedTripForNav {
                    TripDetailView(trip: trip)
                }
            }
            // 이벤트 영역 탭 → Trip 상세 (캘린더 탭)
            .navigationDestination(isPresented: $navigateToCalendar) {
                if let trip = selectedTripForCalendar {
                    TripDetailView(trip: trip, initialTab: .calendar)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("최근 일정")
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { } label: {
                        Image(systemName: "bell")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
            }
        }
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(spacing: 0) {
            WeekCalendarStripView(
                selectedDate: $viewModel.selectedDate,
                style: .sundayStart
            )
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Daily Schedule Section

    private var dailyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 날짜 헤더
            Text(selectedDateText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
                .padding(.horizontal, 24)

            if viewModel.hasScheduleForSelectedDate {
                // 이벤트 목록
                if !viewModel.eventsForSelectedDate.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("일정", systemImage: "calendar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HiTripColor.primary800)
                            .padding(.horizontal, 24)

                        ForEach(viewModel.eventsForSelectedDate) { event in
                            Button {
                                // 이벤트 클릭 → 해당 Trip 캘린더 탭으로 이동
                                if let trip = viewModel.trip(for: event.tripId) {
                                    selectedTripForCalendar = trip
                                    navigateToCalendar = true
                                }
                            } label: {
                                dailyEventRow(event)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                }

                // 투두 목록
                if !viewModel.todosForSelectedDate.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("할 일", systemImage: "checklist")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HiTripColor.primary800)
                            .padding(.horizontal, 24)
                            .padding(.top, viewModel.eventsForSelectedDate.isEmpty ? 0 : 4)

                        ForEach(viewModel.todosForSelectedDate) { todo in
                            dailyTodoRow(todo)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            } else {
                // 빈 상태
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "calendar.badge.minus")
                            .font(.system(size: 28))
                            .foregroundColor(HiTripColor.gray300)
                        Text("이 날짜에 등록된 일정이 없습니다.")
                            .font(.system(size: 14))
                            .foregroundColor(HiTripColor.gray400)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .padding(.horizontal, 20)
    }

    /// 선택된 날짜 텍스트 (예: "4월 20일 월요일")
    private var selectedDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: viewModel.selectedDate)
    }

    // MARK: - Daily Event Row

    private func dailyEventRow(_ event: TripEvent) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.category.color)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)

                Text(eventTimeText(event))
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray500)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(HiTripColor.gray300)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(HiTripColor.gray100)
        .cornerRadius(10)
    }

    private func eventTimeText(_ event: TripEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: event.startTime)) - \(formatter.string(from: event.endTime))"
    }

    // MARK: - Daily Todo Row

    /// 투두 행: 체크 아이콘 클릭 → 토글, 나머지 영역 클릭 → 상세보기
    private func dailyTodoRow(_ todo: TripTodo) -> some View {
        HStack(spacing: 10) {
            // 체크 아이콘 — 탭 시 완료 토글
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleTodo(todo.id)
                }
            } label: {
                if todo.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(HiTripColor.primary800)
                } else {
                    Circle()
                        .stroke(HiTripColor.gray300, lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                }
            }
            .buttonStyle(.plain)

            // 나머지 영역 — 탭 시 해당 Trip 상세보기
            Button {
                if let trip = viewModel.trip(for: todo.tripId) {
                    selectedTripForNav = trip
                    navigateToTripDetail = true
                }
            } label: {
                HStack {
                    Text(todo.title)
                        .font(.system(size: 14))
                        .foregroundColor(
                            todo.isCompleted ? HiTripColor.gray400 : HiTripColor.textBlack
                        )
                        .strikethrough(todo.isCompleted, color: HiTripColor.gray400)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray300)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(HiTripColor.gray100)
        .cornerRadius(10)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("내 일정")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            Button {
                navigateToAllTrips = true
            } label: {
                HStack(spacing: 4) {
                    Text("View all")
                        .font(.system(size: 14))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .foregroundColor(HiTripColor.secondary700)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Trip Card List

    private var tripCardList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredTrips) { trip in
                Button {
                    selectedTripForDetail = trip
                } label: {
                    TripCardRow(trip: trip)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .sheet(item: $selectedTripForDetail) { trip in
            TripScheduleDetailView(trip: trip)
        }
    }
}

// MARK: - TripCardRow

struct TripCardRow: View {

    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(formattedDate)
                        .font(.system(size: 13))
                }
                .foregroundColor(HiTripColor.gray500)

                Text(trip.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                if !trip.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text("위치: \(trip.location)")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(HiTripColor.gray400)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray300)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [HiTripColor.primary800.opacity(0.3), HiTripColor.secondary300],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: thumbnailIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            )
    }

    private var thumbnailIcon: String {
        switch trip.thumbnailName {
        case "mountain": return "mountain.2.fill"
        case "building": return "building.2.fill"
        case "beach":    return "water.waves"
        default:         return "photo.fill"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: trip.date)
    }
}
