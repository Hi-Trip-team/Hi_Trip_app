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

    /// 현재 사용자에게 배정된 여행 패키지 (여행사 등록 데이터)
    @Published var currentPackage: TripPackage?
    @Published var trips: [Trip] = []
    @Published var todos: [TripTodo] = []
    @Published var events: [TripEvent] = []

    // MARK: - Dependencies

    /// 데이터 소스 — 현재 Mock, 추후 Remote로 교체
    private let repository: TripRepositoryProtocol
    private let disposeBag = DisposeBag()

    // MARK: - Init

    /// 프로덕션 — APIEnvironment에 따라 Mock/Remote 자동 전환
    private init() {
        self.networkService = .shared
        self.scheduleRepository = RemoteScheduleRepository(networkService: .shared)
        if APIEnvironment.current.useMock {
            self.repository = MockTripRepository()
        } else {
            self.repository = RemoteTripRepository(networkService: .shared)
        }
        loadInitialData()
    }

    /// 테스트용 — 커스텀 Repository 주입
    init(repository: TripRepositoryProtocol) {
        self.networkService = .shared
        self.scheduleRepository = RemoteScheduleRepository(networkService: .shared)
        self.repository = repository
        loadInitialData()
    }

    /// 스케줄 Repository (서버 공식 일정 조회용)
    private let scheduleRepository: RemoteScheduleRepository

    /// NetworkService (추천 장소 등 직접 호출용)
    private let networkService: NetworkService

    /// Repository에서 초기 데이터 로드
    private func loadInitialData() {
        // 여행 패키지 로드 (여행사 등록 데이터)
        repository.fetchCurrentPackage()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] package in
                self?.currentPackage = package

                // 패키지 로드 후 서버 스케줄 + 추천 장소도 가져오기
                if let pkg = package {
                    self?.loadServerSchedules()
                    self?.loadServerRecommendations()
                }
            })
            .disposed(by: disposeBag)

        // 개인 일정 로드
        repository.fetchTrips()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] trips in
                self?.trips = trips
                for trip in trips {
                    self?.loadTodos(for: trip.id)
                    self?.loadEvents(for: trip.id)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Server Schedule 로드

    /// 서버에서 공식 일정 가져와서 currentPackage.officialSchedules에 반영
    func loadServerSchedules() {
        // 서버 Trip 목록에서 첫 번째(활성) Trip의 ID를 사용
        networkService.request(.tripsList(), type: [TripDTO].self)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] dtos -> Single<[ScheduleDTO]> in
                guard let self,
                      let activeTripId = dtos.first(where: { $0.status == "ongoing" })?.id ?? dtos.first?.id else {
                    return .just([])
                }
                // activeTripPk 설정 (ScheduleViewModel에서도 사용)
                self.scheduleRepository.activeTripPk = activeTripId
                return self.networkService.request(.schedulesList(tripPk: activeTripId), type: [ScheduleDTO].self)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] scheduleDTOs in
                guard let self, var pkg = self.currentPackage else { return }

                // 일차별로 그룹화하여 날짜 계산
                let schedules = scheduleDTOs.compactMap { dto -> TripOfficialSchedule? in
                    let dayOffset = (dto.dayNumber ?? 1) - 1
                    let scheduleDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: pkg.startDate) ?? pkg.startDate
                    return dto.toOfficialSchedule(for: scheduleDate)
                }

                pkg.officialSchedules = schedules
                self.currentPackage = pkg
                print("✅ [TripDataStore] 서버 스케줄 \(schedules.count)개 로드 완료")
            }, onFailure: { error in
                print("⚠️ [TripDataStore] 서버 스케줄 로드 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Server Recommendations 로드

    /// 서버에서 AI 추천 장소 가져와서 currentPackage.nearbySpots에 반영
    func loadServerRecommendations() {
        networkService.request(.recommendationsList(), type: [RecommendationDTO].self)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] dtos in
                guard let self, var pkg = self.currentPackage else { return }

                let spots = dtos.map { $0.toNearbySpot() }
                pkg.nearbySpots = spots
                self.currentPackage = pkg
                print("✅ [TripDataStore] 추천 장소 \(spots.count)개 로드 완료")
            }, onFailure: { error in
                print("⚠️ [TripDataStore] 추천 장소 로드 실패: \(error.localizedDescription)")
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

    // MARK: - Package: Dashboard Helpers

    /// 전체 공지사항 (최신순)
    var allNotices: [TripNotice] {
        guard let pkg = currentPackage else { return [] }
        return pkg.notices.sorted { $0.date > $1.date }
    }

    /// 대표 공지사항 (홈 메인 노출용)
    var representativeNotice: TripNotice? {
        guard let pkg = currentPackage else { return nil }
        return pkg.notices.first { $0.isRepresentative }
            ?? pkg.notices.sorted(by: { $0.date > $1.date }).first
    }

    /// 오늘의 공지사항
    func todayNotices(for date: Date = Date()) -> [TripNotice] {
        guard let pkg = currentPackage else { return [] }
        let cal = Calendar.current
        return pkg.notices.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    /// 오늘의 미션
    func todayMissions(for date: Date = Date()) -> [TripMission] {
        guard let pkg = currentPackage else { return [] }
        let cal = Calendar.current
        return pkg.missions.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    /// 오늘의 공식 일정 (여행사 등록)
    func todayOfficialSchedules(for date: Date = Date()) -> [TripOfficialSchedule] {
        guard let pkg = currentPackage else { return [] }
        let cal = Calendar.current
        return pkg.officialSchedules
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
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

    /// 특정 날짜의 Trip 목록 (날짜 일치)
    func trips(for date: Date) -> [Trip] {
        let cal = Calendar.current
        return trips
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
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
        .sorted { !$0.isCompleted && $1.isCompleted }
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
