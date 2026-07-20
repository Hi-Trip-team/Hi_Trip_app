import Foundation
import Combine

// MARK: - TripDetailViewModel
/// 화면2+3: 여행 상세 (할일 + 캘린더) 관리
///
/// TripDataStore.shared를 참조하여 데이터 일관성 보장.
/// 일정 페이지(TripListView)에서 변경한 투두 체크 상태 등이
/// 상세 페이지에서도 동일하게 반영된다.

final class TripDetailViewModel: ObservableObject {

    // MARK: - Tab

    enum DetailTab: String, CaseIterable {
        case mySchedule = "내 일정"
        case calendar   = "캘린더"
        case todo       = "할 일"
    }

    // MARK: - Store Reference

    private let store = TripDataStore.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    @Published var selectedTab: DetailTab = .mySchedule
    @Published var trip: Trip
    @Published var selectedDate: Date = Date()
    @Published var displayedMonth: Date = Date()


    // MARK: - Init

    init(trip: Trip) {
        self.trip = trip
        self.selectedDate = trip.date
        self.displayedMonth = trip.date

        // Store의 변경을 감지하여 View 갱신
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Trip: 선택 날짜에 해당하는 일정 목록

    /// 선택된 날짜의 여행 일정 (전체 Store 기준)
    var tripsForSelectedDate: [Trip] {
        store.trips(for: selectedDate)
    }

    /// 전체 여행 일정 (날짜 무관)
    var allTrips: [Trip] {
        store.sortedTrips
    }

    // MARK: - Todo (서버 체크리스트)

    /// 미완료 항목
    var pendingTodos: [TripTodo] { store.pendingTodos }

    /// 완료 항목
    var completedTodos: [TripTodo] { store.completedTodos }

    /// 전체 항목 (displayOrder 순)
    var allTodos: [TripTodo] { store.todos }

    func toggleTodo(_ todoId: UUID) {
        store.toggleTodo(todoId)
    }

    // MARK: - Official Schedules (서버 공식 일정)

    /// 선택된 날짜의 공식 일정
    var officialSchedulesForSelectedDate: [TripOfficialSchedule] {
        store.todayOfficialSchedules(for: selectedDate)
    }

    /// 해당 날짜에 공식 일정이 있는지 여부 (캘린더 도트용)
    func hasOfficialSchedule(on date: Date) -> Bool {
        !store.todayOfficialSchedules(for: date).isEmpty
    }

    /// 해당 날짜의 공식 일정 수
    func officialScheduleCount(on date: Date) -> Int {
        store.todayOfficialSchedules(for: date).count
    }

    // MARK: - Month Navigation

    func goToPreviousMonth() {
        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = prev
        }
    }

    func goToNextMonth() {
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = next
        }
    }
}
