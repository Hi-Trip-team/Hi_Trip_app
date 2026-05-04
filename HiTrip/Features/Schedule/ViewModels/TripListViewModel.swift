import Foundation
import Combine

// MARK: - TripListViewModel
/// 홈 화면: 여행 대시보드 관리
///
/// TripDataStore.shared.currentPackage(여행사 등록 패키지)를 기반으로
/// 대시보드 UI에 필요한 데이터를 계산하여 제공.
///
/// 데이터 흐름:
/// 여행사 등록 → 서버 → Repository → TripDataStore.currentPackage → ViewModel → View
///
/// 하드코딩 없이 Store에서 모든 데이터를 가져오므로,
/// API 연동 시 MockTripRepository → RemoteTripRepository 교체만 하면 된다.

final class TripListViewModel: ObservableObject {

    // MARK: - Store Reference

    private let store = TripDataStore.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false

    // MARK: - Init

    init() {
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - 패키지 존재 여부

    /// 현재 배정된 패키지가 있는지
    var hasPackage: Bool {
        store.currentPackage != nil
    }

    // MARK: - 현재 여행 정보 (Store 기반)

    /// 현재 진행 중인 여행 이름
    var currentTripName: String {
        store.currentPackage?.name ?? "여행 없음"
    }

    /// 현재 여행 일차 텍스트
    var currentDayText: String {
        guard let pkg = store.currentPackage else { return "" }
        return "\(pkg.currentDay())일차"
    }

    /// 여행 진행률 (0.0 ~ 1.0)
    var progressRate: Double {
        store.currentPackage?.progressRate() ?? 0
    }

    /// 진행률 텍스트
    var progressText: String {
        let percent = Int(progressRate * 100)
        return "\(percent)% 완료"
    }

    /// 남은 일수 텍스트
    var daysRemainingText: String {
        guard let pkg = store.currentPackage else { return "" }
        let remaining = pkg.daysRemaining()
        return "여행 진행률 · \(remaining)일 남음"
    }

    // MARK: - 날씨 (Store 기반)

    /// 현재 목적지
    var weatherLocation: String {
        store.currentPackage?.destination ?? ""
    }

    /// 날씨 설명
    var weatherDescription: String {
        store.currentPackage?.weatherDescription ?? ""
    }

    // MARK: - 참여자 (Store 기반)

    var participantsText: String {
        guard let pkg = store.currentPackage else { return "" }
        return "참여자 \(pkg.currentParticipants) / \(pkg.totalParticipants)명"
    }

    // MARK: - 공지사항 (Store 기반 — 대표 공지)

    /// 홈에 표시할 대표 공지 내용
    var noticeText: String {
        store.representativeNotice?.content ?? "등록된 공지사항이 없습니다"
    }

    /// 전체 공지사항 목록 (리스트 화면용)
    var allNotices: [TripNotice] {
        store.allNotices
    }

    // MARK: - 오늘의 미션 (Store 기반)

    var missionText: String {
        let missions = store.todayMissions()
        return missions.first?.content ?? "등록된 미션이 없습니다"
    }

    // MARK: - 오늘의 일정 (Store 기반 — 여행사 공식 일정)

    var todaySchedules: [TripOfficialSchedule] {
        store.todayOfficialSchedules()
    }

    // MARK: - 지금 갈만한 곳 (Store 기반)

    var nearbySpots: [TripNearbySpot] {
        store.currentPackage?.nearbySpots ?? []
    }

    // MARK: - 여행 필수 번역 (Store 기반)

    var translationPreview: String {
        guard let pkg = store.currentPackage else { return "" }
        let preview = pkg.translations.prefix(2).map { $0.original }
        return preview.joined(separator: " / ")
    }

    // MARK: - Trips (기존 유지)

    var filteredTrips: [Trip] {
        store.sortedTrips
    }

    func trip(for tripId: UUID) -> Trip? {
        store.trip(for: tripId)
    }

    // MARK: - Todo / Event (기존 유지)

    var todosForSelectedDate: [TripTodo] {
        store.todos(for: selectedDate)
    }

    var eventsForSelectedDate: [TripEvent] {
        store.events(for: selectedDate)
    }

    var hasScheduleForSelectedDate: Bool {
        !todosForSelectedDate.isEmpty || !eventsForSelectedDate.isEmpty
    }

    func toggleTodo(_ todoId: UUID) {
        store.toggleTodo(todoId)
    }
}
