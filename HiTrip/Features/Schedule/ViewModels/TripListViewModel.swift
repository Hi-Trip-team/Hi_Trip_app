import Foundation
import Combine

// MARK: - TripListViewModel
/// 화면1: 최근 일정 리스트 관리
///
/// TripDataStore.shared를 참조하여 데이터 일관성 보장.
/// Store에서 변경이 발생하면 자동으로 UI 갱신.

final class TripListViewModel: ObservableObject {

    // MARK: - Store Reference

    private let store = TripDataStore.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    /// 주간 캘린더에서 선택된 날짜
    @Published var selectedDate: Date = Date()

    /// 로딩 상태
    @Published var isLoading: Bool = false

    // MARK: - Init

    init() {
        // Store의 변경을 감지하여 View 갱신
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Trips

    /// 전체 여행 (최신순)
    var filteredTrips: [Trip] {
        store.sortedTrips
    }

    /// tripId로 Trip 찾기
    func trip(for tripId: UUID) -> Trip? {
        store.trip(for: tripId)
    }

    // MARK: - 선택된 날짜의 투두

    var todosForSelectedDate: [TripTodo] {
        store.todos(for: selectedDate)
    }

    // MARK: - 선택된 날짜의 이벤트

    var eventsForSelectedDate: [TripEvent] {
        store.events(for: selectedDate)
    }

    /// 선택된 날짜에 일정 또는 투두가 있는지
    var hasScheduleForSelectedDate: Bool {
        !todosForSelectedDate.isEmpty || !eventsForSelectedDate.isEmpty
    }

    // MARK: - Todo Actions

    func toggleTodo(_ todoId: UUID) {
        store.toggleTodo(todoId)
    }
}
