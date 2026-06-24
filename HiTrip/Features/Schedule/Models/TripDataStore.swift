import Foundation
import Combine
import RxSwift

// MARK: - TripDataStore
/// 여행 데이터 중앙 상태 저장소 (싱글턴)
///
/// 데이터 흐름:
///   TravelerRepository (API) → TripDataStore (상태) → ViewModel (UI 바인딩)
///
/// 역할:
///   - 여행객 데이터 전체를 @Published로 보관
///   - reload() 한 번으로 앱 전체 데이터 갱신
///   - 개별 ViewModel은 이 Store를 관찰하기만 함
///
/// 직접 NetworkService를 호출하지 않음 — 모든 API 접근은 TravelerRepository로 위임.

final class TripDataStore: ObservableObject {

    // MARK: - Singleton

    static let shared = TripDataStore()

    // MARK: - Published State

    @Published var currentPackage: TripPackage?
    @Published var trips: [Trip] = []
    @Published var todos: [TripTodo] = []        // 서버 체크리스트 + 로컬 추가 항목 혼합
    @Published var events: [TripEvent] = []      // 로컬 전용 (서버 API 없음)
    @Published var notices: [TripNotice] = []
    @Published var recommendedSpots: [TravelerSpotDTO] = []
    @Published var popularSpots: [TravelerSpotDTO] = []
    @Published var isLoading: Bool = false
    private(set) var isDataLoaded: Bool = false

    // MARK: - Dependencies

    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()

    // MARK: - Init

    private init() {
        self.repository = APIEnvironment.current.useMock
            ? MockTravelerRepository()
            : TravelerRepository()
        setupTokenExpiredObserver()
    }

    /// 테스트용 — Mock Repository 주입
    init(repository: TravelerRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public API

    func reload() {
        loadInitialData()
    }

    func clear() {
        currentPackage = nil
        trips = []
        todos = []
        events = []
        notices = []
        recommendedSpots = []
        popularSpots = []
        isDataLoaded = false
    }

    // MARK: - Token 만료 감지

    private func setupTokenExpiredObserver() {
        NotificationCenter.default.addObserver(
            forName: .hiTripTokenExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clear()
        }
    }

    // MARK: - Initial Load

    private func loadInitialData() {
        isLoading = true
        print("🔄 [TripDataStore] 데이터 로드 시작")

        repository.fetchTrip()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dto in
                    guard let self else { return }
                    self.currentPackage = dto.toTripPackage()
                    self.trips = [dto.toTrip()]
                    self.isLoading = false
                    self.isDataLoaded = true
                    print("✅ [TripDataStore] 여행: \(dto.title)")

                    self.loadSchedules()
                    self.loadNotices()
                    self.loadChecklists()
                    self.loadSpots()
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.isDataLoaded = true
                    print("⚠️ [TripDataStore] 여행 로드 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Secondary Loads

    private func loadSchedules() {
        repository.fetchSchedules()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dtos in
                    guard let self, var pkg = self.currentPackage else { return }
                    pkg.officialSchedules = dtos.map { dto in
                        let offset = dto.dayNumber - 1
                        let date = Calendar.current.date(
                            byAdding: .day, value: offset, to: pkg.startDate
                        ) ?? pkg.startDate
                        return dto.toOfficialSchedule(for: date)
                    }
                    self.currentPackage = pkg
                    print("✅ [TripDataStore] 일정 \(dtos.count)개 로드")
                },
                onFailure: { error in
                    print("⚠️ [TripDataStore] 일정 로드 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func loadNotices() {
        repository.fetchNotices()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dtos in
                    guard let self else { return }
                    let list = dtos.map { $0.toTripNotice() }
                    self.notices = list.sorted { $0.date > $1.date }
                    if var pkg = self.currentPackage {
                        pkg.notices = list
                        self.currentPackage = pkg
                    }
                    print("✅ [TripDataStore] 공지 \(dtos.count)개 로드")
                },
                onFailure: { error in
                    print("⚠️ [TripDataStore] 공지 로드 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func loadChecklists() {
        repository.fetchChecklists()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dtos in
                    guard let self, let tripId = self.trips.first?.id else { return }
                    let serverTodos = dtos.map { $0.toTripTodo(tripId: tripId) }
                    let localOnly = self.todos.filter { !$0.isServerManaged }
                    self.todos = serverTodos + localOnly
                    print("✅ [TripDataStore] 체크리스트 \(dtos.count)개 로드")
                },
                onFailure: { error in
                    print("⚠️ [TripDataStore] 체크리스트 로드 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func loadSpots() {
        repository.fetchRecommendedSpots()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dtos in
                    self?.recommendedSpots = dtos
                    self?.syncNearbySpots()
                    print("✅ [TripDataStore] 추천 스팟 \(dtos.count)개 로드")
                },
                onFailure: { error in
                    print("⚠️ [TripDataStore] 추천 스팟 로드 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)

        repository.fetchPopularSpots()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dtos in
                    self?.popularSpots = dtos
                    self?.syncNearbySpots()
                    print("✅ [TripDataStore] 인기 스팟 \(dtos.count)개 로드")
                },
                onFailure: { error in
                    print("⚠️ [TripDataStore] 인기 스팟 로드 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func syncNearbySpots() {
        guard var pkg = currentPackage else { return }
        pkg.nearbySpots = (recommendedSpots + popularSpots).map { $0.toNearbySpot() }
        currentPackage = pkg
    }

    // MARK: - Checklist Toggle (서버 동기화)

    func toggleTodo(_ todoId: UUID) {
        guard let idx = todos.firstIndex(where: { $0.id == todoId }) else { return }
        todos[idx].isCompleted.toggle()
        let updated = todos[idx]

        guard let serverId = updated.serverId else { return }
        repository.toggleChecklist(itemId: serverId, isChecked: updated.isCompleted)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { _ in
                    print("✅ [TripDataStore] 체크리스트 \(serverId) 업데이트")
                },
                onFailure: { [weak self] error in
                    // 실패 시 롤백
                    if let i = self?.todos.firstIndex(where: { $0.id == todoId }) {
                        self?.todos[i].isCompleted.toggle()
                    }
                    print("⚠️ [TripDataStore] 체크리스트 토글 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Package / Notice Helpers

    var allNotices: [TripNotice] {
        notices.sorted { $0.date > $1.date }
    }

    var representativeNotice: TripNotice? {
        notices.first { $0.isRepresentative } ?? notices.sorted { $0.date > $1.date }.first
    }

    func todayOfficialSchedules(for date: Date = Date()) -> [TripOfficialSchedule] {
        guard let pkg = currentPackage else { return [] }
        let cal = Calendar.current
        return pkg.officialSchedules
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    func tomorrowOfficialSchedules() -> [TripOfficialSchedule] {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return [] }
        return todayOfficialSchedules(for: tomorrow)
    }

    func officialSchedules(forDay dayNumber: Int) -> [TripOfficialSchedule] {
        guard let pkg = currentPackage else { return [] }
        return pkg.officialSchedules
            .filter { $0.dayNumber == dayNumber }
            .sorted { $0.startTime < $1.startTime }
    }

    func officialSchedulesByDay() -> [Int: [TripOfficialSchedule]] {
        guard let pkg = currentPackage else { return [:] }
        return Dictionary(grouping: pkg.officialSchedules) { $0.dayNumber ?? 1 }
    }

    // MARK: - Trip Helpers

    var sortedTrips: [Trip] { trips.sorted { $0.date > $1.date } }

    func trip(for id: UUID) -> Trip? { trips.first { $0.id == id } }

    func trips(for date: Date) -> [Trip] {
        let cal = Calendar.current
        return trips.filter { cal.isDate($0.date, inSameDayAs: date) }.sorted { $0.date < $1.date }
    }

    // MARK: - Todo Helpers

    func todos(for tripId: UUID, date: Date, section: TripTodo.Section) -> [TripTodo] {
        let cal = Calendar.current
        return todos
            .filter { $0.tripId == tripId && $0.section == section && cal.isDate($0.date, inSameDayAs: date) }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }

    func todos(for date: Date) -> [TripTodo] {
        let cal = Calendar.current
        return todos.filter { cal.isDate($0.date, inSameDayAs: date) }.sorted { !$0.isCompleted && $1.isCompleted }
    }

    func todos(for tripId: UUID) -> [TripTodo] { todos.filter { $0.tripId == tripId } }

    /// 로컬 전용 항목 추가 (앱 재시작 시 초기화 — UserDefaults 저장은 별도 작업)
    func addTodo(title: String, section: TripTodo.Section, date: Date, tripId: UUID) {
        todos.append(TripTodo(title: title, section: section, date: date, tripId: tripId))
    }

    func updateTodo(_ todoId: UUID, newTitle: String) {
        if let i = todos.firstIndex(where: { $0.id == todoId }) { todos[i].title = newTitle }
    }

    /// 서버 관리 항목은 삭제 불가 (DELETE 엔드포인트 없음)
    func deleteTodo(_ todoId: UUID) {
        guard let todo = todos.first(where: { $0.id == todoId }), !todo.isServerManaged else { return }
        todos.removeAll { $0.id == todoId }
    }

    // MARK: - Event Helpers (로컬 전용)

    func events(for date: Date) -> [TripEvent] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.startTime, inSameDayAs: date) }.sorted { $0.startTime < $1.startTime }
    }

    func events(for tripId: UUID, date: Date) -> [TripEvent] {
        let cal = Calendar.current
        return events.filter { $0.tripId == tripId && cal.isDate($0.startTime, inSameDayAs: date) }.sorted { $0.startTime < $1.startTime }
    }

    func events(for tripId: UUID) -> [TripEvent] { events.filter { $0.tripId == tripId } }

    func eventCategories(for tripId: UUID, date: Date) -> [TripEvent.Category] {
        let cal = Calendar.current
        var seen = Set<TripEvent.Category>()
        return events
            .filter { $0.tripId == tripId && cal.isDate($0.startTime, inSameDayAs: date) }
            .compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }

    func addEvent(title: String, startTime: Date, endTime: Date, category: TripEvent.Category, tripId: UUID) {
        events.append(TripEvent(title: title, startTime: startTime, endTime: endTime, category: category, tripId: tripId))
    }

    func updateEvent(_ eventId: UUID, title: String, startTime: Date, endTime: Date, category: TripEvent.Category) {
        if let i = events.firstIndex(where: { $0.id == eventId }) {
            events[i].title = title
            events[i].startTime = startTime
            events[i].endTime = endTime
            events[i].category = category
        }
    }

    func deleteEvent(_ eventId: UUID) { events.removeAll { $0.id == eventId } }
}
