import Foundation
import Combine
import RxSwift

// MARK: - TripDataStore
/// 여행 데이터 중앙 저장소 (싱글턴)
///
/// 모든 Trip, TripTodo, TripEvent를 한 곳에서 관리.
/// TripListViewModel, TripDetailViewModel 등 여러 ViewModel이
/// 이 Store를 공유하여 데이터 일관성을 보장한다.
///
/// Repository를 통해 데이터를 읽고 쓰며,
/// API 연동 시 MockTripRepository → RemoteTripRepository로 교체하면 된다.
/// Store 외부 코드(ViewModel, View)는 변경 불필요.

final class TripDataStore: ObservableObject {

    // MARK: - Singleton

    static let shared = TripDataStore()

    // MARK: - Published Data

    @Published var trips: [Trip] = []
    @Published var todos: [TripTodo] = []
    @Published var events: [TripEvent] = []

    // MARK: - Dependencies

    /// 데이터 소스 — 현재 Mock, 추후 Remote로 교체
    private let repository: TripRepositoryProtocol
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// 프로덕션 (Mock Repository)
    private init() {
        self.repository = MockTripRepository()
        loadInitialData()
    }

    /// 테스트용 — 커스텀 Repository 주입
    init(repository: TripRepositoryProtocol) {
        self.repository = repository
        loadInitialData()
    }

    /// Repository에서 초기 데이터 로드
    private func loadInitialData() {
        repository.fetchTrips()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] trips in
                self?.trips = trips
                // 각 Trip의 Todo/Event도 로드
                for trip in trips {
                    self?.loadTodos(for: trip.id)
                    self?.loadEvents(for: trip.id)
                }
            })
            .disposed(by: disposeBag)
    }

    /// 특정 Trip의 Todo 로드
    private func loadTodos(for tripId: UUID) {
        repository.fetchTodos(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] fetchedTodos in
                // 기존 해당 Trip의 todo 제거 후 새로 추가
                self?.todos.removeAll { $0.tripId == tripId }
                self?.todos.append(contentsOf: fetchedTodos)
            })
            .disposed(by: disposeBag)
    }

    /// 특정 Trip의 Event 로드
    private func loadEvents(for tripId: UUID) {
        repository.fetchEvents(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] fetchedEvents in
                self?.events.removeAll { $0.tripId == tripId }
                self?.events.append(contentsOf: fetchedEvents)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Trip: Read

    /// 전체 여행 (최신순 정렬)
    var sortedTrips: [Trip] {
        trips.sorted { $0.date > $1.date }
    }

    /// ID로 Trip 찾기
    func trip(for id: UUID) -> Trip? {
        trips.first { $0.id == id }
    }

    // MARK: - Todo: CRUD

    /// 특정 Trip + 날짜 + 섹션 필터
    func todos(for tripId: UUID, date: Date, section: TripTodo.Section) -> [TripTodo] {
        let cal = Calendar.current
        return todos.filter {
            $0.tripId == tripId &&
            $0.section == section &&
            cal.isDate($0.date, inSameDayAs: date)
        }
    }

    /// 특정 날짜의 전체 투두 (모든 Trip)
    func todos(for date: Date) -> [TripTodo] {
        let cal = Calendar.current
        return todos
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }

    /// 특정 Trip의 전체 투두
    func todos(for tripId: UUID) -> [TripTodo] {
        todos.filter { $0.tripId == tripId }
    }

    func addTodo(title: String, section: TripTodo.Section, date: Date, tripId: UUID) {
        let todo = TripTodo(title: title, section: section, date: date, tripId: tripId)
        todos.append(todo)

        // Repository에도 저장 (향후 API 동기화)
        repository.createTodo(todo)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func toggleTodo(_ todoId: UUID) {
        if let i = todos.firstIndex(where: { $0.id == todoId }) {
            todos[i].isCompleted.toggle()

            repository.updateTodo(todos[i])
                .subscribe()
                .disposed(by: disposeBag)
        }
    }

    func updateTodo(_ todoId: UUID, newTitle: String) {
        if let i = todos.firstIndex(where: { $0.id == todoId }) {
            todos[i].title = newTitle

            repository.updateTodo(todos[i])
                .subscribe()
                .disposed(by: disposeBag)
        }
    }

    func deleteTodo(_ todoId: UUID) {
        todos.removeAll { $0.id == todoId }

        repository.deleteTodo(id: todoId)
            .subscribe()
            .disposed(by: disposeBag)
    }

    // MARK: - Event: CRUD

    /// 특정 날짜의 전체 이벤트 (모든 Trip)
    func events(for date: Date) -> [TripEvent] {
        let cal = Calendar.current
        return events
            .filter { cal.isDate($0.startTime, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    /// 특정 Trip의 특정 날짜 이벤트
    func events(for tripId: UUID, date: Date) -> [TripEvent] {
        let cal = Calendar.current
        return events
            .filter { $0.tripId == tripId && cal.isDate($0.startTime, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    /// 특정 Trip의 전체 이벤트
    func events(for tripId: UUID) -> [TripEvent] {
        events.filter { $0.tripId == tripId }
    }

    /// 특정 날짜에 존재하는 카테고리 목록 (캘린더 도트용)
    func eventCategories(for tripId: UUID, date: Date) -> [TripEvent.Category] {
        let cal = Calendar.current
        let dayEvents = events.filter {
            $0.tripId == tripId && cal.isDate($0.startTime, inSameDayAs: date)
        }
        var seen = Set<TripEvent.Category>()
        return dayEvents.compactMap { event in
            if seen.contains(event.category) { return nil }
            seen.insert(event.category)
            return event.category
        }
    }

    func addEvent(title: String, startTime: Date, endTime: Date, category: TripEvent.Category, tripId: UUID) {
        let event = TripEvent(title: title, startTime: startTime, endTime: endTime, category: category, tripId: tripId)
        events.append(event)

        repository.createEvent(event)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func updateEvent(_ eventId: UUID, title: String, startTime: Date, endTime: Date, category: TripEvent.Category) {
        if let i = events.firstIndex(where: { $0.id == eventId }) {
            events[i].title = title
            events[i].startTime = startTime
            events[i].endTime = endTime
            events[i].category = category

            repository.updateEvent(events[i])
                .subscribe()
                .disposed(by: disposeBag)
        }
    }

    func deleteEvent(_ eventId: UUID) {
        events.removeAll { $0.id == eventId }

        repository.deleteEvent(id: eventId)
            .subscribe()
            .disposed(by: disposeBag)
    }
}
