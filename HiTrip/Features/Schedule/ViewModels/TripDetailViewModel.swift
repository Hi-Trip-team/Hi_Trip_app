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
        case todo = "할일"
        case calendar = "캘린더"
    }

    // MARK: - Store Reference

    private let store = TripDataStore.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    @Published var selectedTab: DetailTab = .todo
    @Published var trip: Trip
    @Published var selectedDate: Date = Date()
    @Published var displayedMonth: Date = Date()

    /// 이벤트 추가/수정 시트 표시
    @Published var showAddEventSheet: Bool = false

    /// 이벤트 폼 (추가 & 수정 공용)
    @Published var newEventTitle: String = ""
    @Published var newEventStartTime: Date = Date()
    @Published var newEventEndTime: Date = Date()
    @Published var newEventCategory: TripEvent.Category = .schedule

    /// 수정 중인 이벤트 ID (nil이면 추가 모드)
    @Published var editingEventId: UUID?

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

    // MARK: - Todo: Filtered by Date + Section

    /// 선택된 날짜 + "오늘 일정 준비" 섹션
    var todayPrepTodos: [TripTodo] {
        store.todos(for: trip.id, date: selectedDate, section: .todayPrep)
    }

    /// 선택된 날짜 + "여행 준비 & 관리" 섹션
    var travelPrepTodos: [TripTodo] {
        store.todos(for: trip.id, date: selectedDate, section: .travelPrep)
    }

    // MARK: - Todo: CRUD (Store 위임)

    func addTodo(title: String, section: TripTodo.Section) {
        store.addTodo(title: title, section: section, date: selectedDate, tripId: trip.id)
    }

    func toggleTodo(_ todoId: UUID) {
        store.toggleTodo(todoId)
    }

    func updateTodo(_ todoId: UUID, newTitle: String) {
        store.updateTodo(todoId, newTitle: newTitle)
    }

    func deleteTodo(_ todoId: UUID) {
        store.deleteTodo(todoId)
    }

    // MARK: - Event: CRUD (Store 위임)

    /// 새 이벤트 추가 / 기존 이벤트 수정
    func addEvent() {
        guard !newEventTitle.trimmed.isEmpty else { return }

        if let editId = editingEventId {
            store.updateEvent(editId,
                              title: newEventTitle.trimmed,
                              startTime: newEventStartTime,
                              endTime: newEventEndTime,
                              category: newEventCategory)
        } else {
            store.addEvent(title: newEventTitle.trimmed,
                           startTime: newEventStartTime,
                           endTime: newEventEndTime,
                           category: newEventCategory,
                           tripId: trip.id)
        }
        resetEventForm()
    }

    func deleteEvent(_ eventId: UUID) {
        store.deleteEvent(eventId)
    }

    /// 이벤트 폼 초기화
    func resetEventForm() {
        newEventTitle = ""
        newEventStartTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        newEventEndTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        newEventCategory = .schedule
        editingEventId = nil
        showAddEventSheet = false
    }

    /// FAB 버튼 탭 시 호출 (추가 모드)
    func prepareAddEvent() {
        resetEventForm()
        showAddEventSheet = true
    }

    /// 이벤트 수정 시트 열기
    func prepareEditEvent(_ event: TripEvent) {
        editingEventId = event.id
        newEventTitle = event.title
        newEventStartTime = event.startTime
        newEventEndTime = event.endTime
        newEventCategory = event.category
        showAddEventSheet = true
    }

    // MARK: - Events: Filtered (Store 참조)

    var eventsForSelectedDate: [TripEvent] {
        store.events(for: trip.id, date: selectedDate)
    }

    func eventCategories(for date: Date) -> [TripEvent.Category] {
        store.eventCategories(for: trip.id, date: date)
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
