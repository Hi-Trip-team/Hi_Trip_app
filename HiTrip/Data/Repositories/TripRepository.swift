import Foundation
import RxSwift

// MARK: - MockTripRepository
/// 메모리 기반 Mock 구현체
///
/// 앱 실행 시 Mock 데이터를 메모리에 생성하여 반환.
/// API 연동 시 이 클래스를 RemoteTripRepository로 교체하면 된다.
/// Protocol만 맞추면 TripDataStore 코드는 변경 불필요.

final class MockTripRepository: TripRepositoryProtocol {

    // MARK: - In-Memory Storage

    private var currentPackage: TripPackage?
    private var trips: [Trip] = []
    private var todos: [TripTodo] = []
    private var events: [TripEvent] = []

    init() {
        loadMockData()
    }

    // MARK: - TripPackage

    func fetchCurrentPackage() -> Single<TripPackage?> {
        .just(currentPackage)
    }

    func fetchPackages() -> Single<[TripPackage]> {
        if let pkg = currentPackage {
            return .just([pkg])
        }
        return .just([])
    }

    // MARK: - Trip

    func fetchTrips() -> Single<[Trip]> {
        .just(trips)
    }

    func createTrip(_ trip: Trip) -> Single<Trip> {
        trips.append(trip)
        return .just(trip)
    }

    func deleteTrip(id: UUID) -> Single<Void> {
        trips.removeAll { $0.id == id }
        todos.removeAll { $0.tripId == id }
        events.removeAll { $0.tripId == id }
        return .just(())
    }

    // MARK: - Todo

    func fetchTodos(tripId: UUID) -> Single<[TripTodo]> {
        .just(todos.filter { $0.tripId == tripId })
    }

    func createTodo(_ todo: TripTodo) -> Single<TripTodo> {
        todos.append(todo)
        return .just(todo)
    }

    func updateTodo(_ todo: TripTodo) -> Single<TripTodo> {
        if let i = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[i] = todo
        }
        return .just(todo)
    }

    func deleteTodo(id: UUID) -> Single<Void> {
        todos.removeAll { $0.id == id }
        return .just(())
    }

    // MARK: - Event

    func fetchEvents(tripId: UUID) -> Single<[TripEvent]> {
        .just(events.filter { $0.tripId == tripId })
    }

    func createEvent(_ event: TripEvent) -> Single<TripEvent> {
        events.append(event)
        return .just(event)
    }

    func updateEvent(_ event: TripEvent) -> Single<TripEvent> {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        }
        return .just(event)
    }

    func deleteEvent(id: UUID) -> Single<Void> {
        events.removeAll { $0.id == id }
        return .just(())
    }

    // MARK: - Mock Data

    private func loadMockData() {
        let calendar = Calendar.current
        let now = Date()

        let today = now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let dayAfter = calendar.date(byAdding: .day, value: 2, to: now) ?? now

        // ── TripPackage (여행사 등록 데이터) ──────────────────

        let packageStart = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        let packageEnd = calendar.date(byAdding: .day, value: 3, to: now) ?? now

        currentPackage = TripPackage(
            name: "제주 힐링여행",
            startDate: packageStart,
            endDate: packageEnd,
            destination: "제주",
            totalParticipants: 20,
            currentParticipants: 18,
            weatherDescription: "맑음 22°C",
            notices: [
                TripNotice(title: "집합 안내", content: "오전 9시 로비 집합 — 우산 꼭 챙겨주세요!", date: today, isImportant: true, isRepresentative: true),
                TripNotice(title: "준비물 안내", content: "내일 해변 투어 준비물: 선크림, 모자, 수건 필수!", date: today),
                TripNotice(title: "식사 안내", content: "점심은 12시 30분 한림 맛집에서 단체 식사입니다.", date: today),
                TripNotice(title: "해변 투어", content: "내일 오전 9시 해변 투어 출발합니다. 편한 신발 착용해주세요.", date: tomorrow),
                TripNotice(title: "귀국 안내", content: "마지막 날 체크아웃은 11시까지입니다.", date: dayAfter)
            ],
            missions: [
                TripMission(content: "제주 명소 3곳 방문하기", date: today),
                TripMission(content: "현지 맛집에서 사진 남기기", date: tomorrow)
            ],
            officialSchedules: [
                TripOfficialSchedule(
                    emoji: "🏠",
                    title: "숙소로 이동",
                    startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? now,
                    endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today) ?? now,
                    date: today
                ),
                TripOfficialSchedule(
                    emoji: "🌅",
                    title: "자유 시간",
                    startTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today) ?? now,
                    endTime: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: today) ?? now,
                    date: today
                ),
                TripOfficialSchedule(
                    emoji: "🏖️",
                    title: "해변 투어",
                    startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? now,
                    endTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow) ?? now,
                    date: tomorrow
                ),
                TripOfficialSchedule(
                    emoji: "🍽️",
                    title: "점심 식사",
                    startTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: tomorrow) ?? now,
                    endTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow) ?? now,
                    date: tomorrow
                )
            ],
            nearbySpots: [
                TripNearbySpot(name: "협재 해수욕장", distance: "도보 8분", category: "beach"),
                TripNearbySpot(name: "한림공원", distance: "도보 11분", category: "leaf"),
                TripNearbySpot(name: "금오름", distance: "차량 14분", category: "mountain"),
                TripNearbySpot(name: "금능 해수욕장", distance: "도보 9분", category: "water")
            ],
            translations: [
                TripTranslation(original: "화장실 어디예요?", translated: "Where is the restroom?", category: "기본"),
                TripTranslation(original: "얼마예요?", translated: "How much is it?", category: "쇼핑"),
                TripTranslation(original: "도와주세요", translated: "Please help me", category: "긴급")
            ]
        )

        // ── Trips ──────────────────────────────────

        let trip1 = Trip(
            title: "한라산 등반",
            date: today,
            location: "제주도, 대한민국",
            thumbnailName: "mountain",
            memberAvatars: ["person.circle.fill", "person.circle.fill"]
        )
        let trip2 = Trip(
            title: "서울 타워 방문",
            date: dayAfter,
            location: "서울, 대한민국",
            thumbnailName: "building",
            memberAvatars: ["person.circle.fill"]
        )
        let trip3 = Trip(
            title: "부산 해운대 해변",
            date: calendar.date(byAdding: .day, value: 5, to: now) ?? now,
            location: "부산, 대한민국",
            thumbnailName: "beach",
            memberAvatars: ["person.circle.fill", "person.circle.fill", "person.circle.fill"]
        )

        trips = [trip1, trip2, trip3]

        // ── Todos ──────────────────────────────────

        todos = [
            // trip1 (한라산) — 오늘
            TripTodo(title: "오늘 일정 확인하기", section: .todayPrep, date: today, tripId: trip1.id),
            TripTodo(title: "다음 이동 경로 확인", section: .todayPrep, date: today, tripId: trip1.id),
            TripTodo(title: "아침 일정 완료", isCompleted: true, section: .todayPrep, date: today, tripId: trip1.id),
            TripTodo(title: "입장권 / 예약 확인", isCompleted: true, section: .todayPrep, date: today, tripId: trip1.id),
            TripTodo(title: "다음 장소까지 이동 준비", isCompleted: true, section: .todayPrep, date: today, tripId: trip1.id),
            TripTodo(title: "교통권 / 패스 챙기기", section: .travelPrep, date: today, tripId: trip1.id),
            TripTodo(title: "휴대폰 충전 상태 확인", section: .travelPrep, date: today, tripId: trip1.id),
            TripTodo(title: "현지 날씨 확인", isCompleted: true, section: .travelPrep, date: today, tripId: trip1.id),
            TripTodo(title: "내일 일정 미리 보기", isCompleted: true, section: .travelPrep, date: today, tripId: trip1.id),

            // trip1 (한라산) — 내일
            TripTodo(title: "체크아웃 준비", section: .todayPrep, date: tomorrow, tripId: trip1.id),
            TripTodo(title: "짐 정리", section: .travelPrep, date: tomorrow, tripId: trip1.id),

            // trip2 (서울 타워) — 내일
            TripTodo(title: "현지 날씨 확인", section: .travelPrep, date: tomorrow, tripId: trip2.id),

            // trip2 (서울 타워) — 모레
            TripTodo(title: "서울 타워 티켓 예매", section: .todayPrep, date: dayAfter, tripId: trip2.id),
            TripTodo(title: "카메라 충전", section: .travelPrep, date: dayAfter, tripId: trip2.id),
        ]

        // ── Events ─────────────────────────────────

        events = [
            // trip1 (한라산) — 오늘
            TripEvent(
                title: "한라산 등반 준비",
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? now,
                endTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? now,
                category: .destination,
                tripId: trip1.id
            ),
            TripEvent(
                title: "제주 올레길 걷기",
                startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today) ?? now,
                endTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today) ?? now,
                category: .schedule,
                tripId: trip1.id
            ),
            TripEvent(
                title: "제주 해변 산책",
                startTime: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today) ?? now,
                endTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? now,
                category: .etc,
                tripId: trip1.id
            ),

            // trip1 (한라산) — 내일
            TripEvent(
                title: "제주 시장 방문",
                startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? now,
                endTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow) ?? now,
                category: .list,
                tripId: trip1.id
            ),

            // trip2 (서울 타워) — 모레
            TripEvent(
                title: "서울 타워 관광",
                startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dayAfter) ?? now,
                endTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dayAfter) ?? now,
                category: .destination,
                tripId: trip2.id
            ),
            TripEvent(
                title: "숙소 체크인",
                startTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayAfter) ?? now,
                endTime: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dayAfter) ?? now,
                category: .list,
                tripId: trip2.id
            ),
        ]
    }
}
