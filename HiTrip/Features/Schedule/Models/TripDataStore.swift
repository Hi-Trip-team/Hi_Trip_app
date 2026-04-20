import Foundation
import Combine

// MARK: - TripDataStore
/// 여행 데이터 중앙 저장소 (싱글턴)
///
/// 모든 Trip, TripTodo, TripEvent를 한 곳에서 관리.
/// TripListViewModel, TripDetailViewModel 등 여러 ViewModel이
/// 이 Store를 공유하여 데이터 일관성을 보장한다.
///
/// 추후 API 연동 시 이 Store의 Mock 로직만 교체하면 된다.

final class TripDataStore: ObservableObject {

    // MARK: - Singleton

    static let shared = TripDataStore()

    // MARK: - Published Data

    @Published var trips: [Trip] = []
    @Published var todos: [TripTodo] = []
    @Published var events: [TripEvent] = []

    // MARK: - Init (Mock 데이터 생성)

    private init() {
        loadMockData()
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
    }

    func toggleTodo(_ todoId: UUID) {
        if let i = todos.firstIndex(where: { $0.id == todoId }) {
            todos[i].isCompleted.toggle()
        }
    }

    func updateTodo(_ todoId: UUID, newTitle: String) {
        if let i = todos.firstIndex(where: { $0.id == todoId }) {
            todos[i].title = newTitle
        }
    }

    func deleteTodo(_ todoId: UUID) {
        todos.removeAll { $0.id == todoId }
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
    }

    func updateEvent(_ eventId: UUID, title: String, startTime: Date, endTime: Date, category: TripEvent.Category) {
        if let i = events.firstIndex(where: { $0.id == eventId }) {
            events[i].title = title
            events[i].startTime = startTime
            events[i].endTime = endTime
            events[i].category = category
        }
    }

    func deleteEvent(_ eventId: UUID) {
        events.removeAll { $0.id == eventId }
    }

    // MARK: - Mock Data (한 곳에서 통합 관리)

    private func loadMockData() {
        let calendar = Calendar.current
        let now = Date()

        let today = now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let dayAfter = calendar.date(byAdding: .day, value: 2, to: now) ?? now

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
