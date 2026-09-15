import Foundation
import RxSwift

// MARK: - TravelerHomeViewModel
/// 여행객 홈 — 서버 연동
///
/// 홈 화면은 3개 엔드포인트를 합쳐서 그립니다.
/// - GET /api/v1/tourist/home/           여행 정보 · D-day · 오늘/다음 일정 · 담당자
/// - GET /api/v1/tourist/notices/        공지 카드 · 안 읽음 뱃지
/// - GET /api/v1/tourist/popular-spots/  주변 인기 스팟
///
/// 셋 중 일부만 실패해도 나머지는 그리도록 개별로 상태를 둡니다.
/// 홈 본문(trip/일정)이 없으면 화면 자체가 성립하지 않으므로 그때만 전체 에러로 취급합니다.

@MainActor
final class TravelerHomeViewModel: ObservableObject {

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var home: TravelerHomeDTO?
    @Published private(set) var notices: [TravelerNoticeDTO] = []
    @Published private(set) var popularSpots: [TravelerSpotDTO] = []
    /// 스팟 요청이 한 번이라도 끝났는지 — 로딩 중(자리 표시)과 결과 없음(안내 문구)을 구분합니다
    @Published private(set) var isSpotsLoaded = false
    @Published private(set) var unreadMessageCount: Int = 0
    /// 내가 추가한 개인 일정 — 홈 API(today_schedules·next_schedule)에 없어 따로 불러옵니다
    @Published private(set) var personalSchedules: [TravelerPersonalScheduleDTO] = []

    private let repository: TravelerRepositoryProtocol
    private let chatRepository: ChatRepositoryProtocol
    private let disposeBag = DisposeBag()

    init(
        repository: TravelerRepositoryProtocol = AppDIContainer.shared.travelerRepositoryForHome,
        chatRepository: ChatRepositoryProtocol = AppDIContainer.shared.chatRepositoryForHome
    ) {
        self.repository = repository
        self.chatRepository = chatRepository
    }

    // MARK: - Load

    /// 당겨서 새로고침 — 로딩 화면으로 되돌아가지 않고 값만 갱신합니다
    func refresh() {
        repository.fetchHome()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] dto in
                self?.home = dto
                self?.state = .loaded
                self?.loadSecondary()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    func load() {
        guard state != .loading else { return }
        state = .loading

        repository.fetchHome()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dto in
                    self?.home = dto
                    self?.state = .loaded
                    self?.loadSecondary()
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)
    }

    /// 공지·인기 스팟 — 실패해도 홈은 그대로 둡니다.
    private func loadSecondary() {
        repository.fetchNotices()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.notices = $0 },
                       onFailure: { _ in })
            .disposed(by: disposeBag)

        // 안내사가 등록한 추천 스팟을 앞에, 외부 데이터 인기 스팟을 뒤에 붙입니다.
        // 현재 서버 여행 데이터는 추천(recommended)만 있고 인기(popular)는 비어 있습니다.
        // 한쪽이 실패해도 다른 쪽은 보여주도록 각각 빈 목록으로 대체합니다.
        Single.zip(
            repository.fetchRecommendedSpots().catchAndReturn([]),
            repository.fetchPopularSpots().catchAndReturn([])
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] recommended, popular in
            var seen = Set<Int>()
            // 장소 데이터를 찾지 못한 스팟(좌표·주소 모두 없음)은 상세에 보여줄 게 없어 뺍니다
            self?.popularSpots = (recommended + popular)
                .filter { seen.insert($0.id).inserted }
                .filter { Self.hasPlaceData($0.place) }
            self?.isSpotsLoaded = true
        })
        .disposed(by: disposeBag)

        reloadPersonalSchedules()

        // 하단 "메시지 및 문의" 뱃지 — 전체 채팅방의 안 읽음 합계
        chatRepository.fetchAllRooms()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] rooms in
                self?.unreadMessageCount = rooms.reduce(0) { $0 + $1.unreadCount }
            }, onFailure: { _ in })
            .disposed(by: disposeBag)

        listenForNotices()
    }

    /// 개인 일정 다시 불러오기 — 일정 화면에서 추가·수정·삭제하고 돌아왔을 때도 부릅니다
    func reloadPersonalSchedules() {
        repository.fetchPersonalSchedules()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.personalSchedules = $0 }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    /// 공지 실시간 수신 — 안내사가 공지를 올리거나 바꾸면 목록·뱃지를 다시 불러옵니다.
    /// 홈이 살아 있는 동안 한 번만 연결합니다 (disposeBag과 함께 해제).
    private var isListeningNotices = false

    private func listenForNotices() {
        guard !isListeningNotices else { return }
        isListeningNotices = true
        repository.observeNoticeEvents()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.reloadNotices() })
            .disposed(by: disposeBag)
    }

    var hasUnreadMessage: Bool { unreadMessageCount > 0 }

    /// 뱃지 표기 — 세 자리부터는 99+로 줄입니다
    var unreadMessageBadgeText: String {
        unreadMessageCount > 99 ? "99+" : "\(unreadMessageCount)"
    }

    /// 장소 데이터가 있는지 — 좌표나 주소 중 하나라도 있어야 상세·지도에 보여줄 수 있습니다
    private static func hasPlaceData(_ place: TripSpotPlaceDTO) -> Bool {
        let hasCoordinate = place.latitude.flatMap(Double.init) != nil && place.longitude.flatMap(Double.init) != nil
        let hasAddress = !(place.address ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        return hasCoordinate || hasAddress
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden:  return "로그인이 필요합니다"
            case .noConnection:              return "연결을 확인해주세요"
            case .timeout:                   return "서버 응답이 없습니다"
            case .notFound:                  return "배정된 여행이 없습니다"
            default:                         break
            }
        }
        return "여행 정보를 불러오지 못했습니다"
    }

    // MARK: - 헤더

    var tripTitle: String { home?.trip.title ?? "" }

    /// 안 읽은 공지 수 — 0이면 뱃지를 숨깁니다.
    var unreadNoticeCount: Int { activeNotices.filter { $0.isRead != true }.count }

    // MARK: - 여행 단계

    /// 홈이 어떤 형태로 보일지 결정합니다.
    enum TripPhase: Equatable {
        /// 출발 전 — D-day 카드만, 진행바·일정 카드 비노출
        case before
        /// 여행 중
        case during
        /// 종료 후 — 종료 안내와 계정 파기 예정일
        case finished
    }

    /// 출발까지 남은 일수. 0 이하면 여행이 시작된 상태.
    var dDay: Int { home?.trip.dDay ?? 0 }

    var phase: TripPhase {
        if dDay > 0 { return .before }
        if let end = AppDate.day(home?.trip.endDate),
           Calendar.current.startOfDay(for: Date()) > end {
            return .finished
        }
        return .during
    }

    var isBeforeTrip: Bool { phase == .before }

    /// "D-3 · 2025.04.24 출발"
    var departureText: String {
        guard let trip = home?.trip else { return "" }
        return "D-\(trip.dDay) · \(Self.displayDate(trip.startDate)) 출발"
    }

    /// 여행 종료 후 계정이 파기되는 날 (종료일 + 3일)
    var dataPurgeDateText: String {
        guard let end = AppDate.day(home?.trip.endDate),
              let purge = Calendar.current.date(byAdding: .day, value: 3, to: end) else { return "" }
        return AppDate.string(purge, "yyyy.MM.dd")
    }

    // MARK: - 오늘의 일정

    var todaySchedules: [TravelerScheduleDTO] { home?.todaySchedules ?? [] }

    /// 오늘 일정의 진행 상태 — 화면 상단 카드가 무엇을 보여줄지 결정
    enum TodayState: Equatable {
        /// 지금 진행 중
        case ongoing(TravelerScheduleDTO)
        /// 아직 시작 전 — 가장 이른 예정 일정
        case upcoming(TravelerScheduleDTO)
        /// 오늘 일정이 모두 끝남
        case finished
        /// 오늘 배정된 일정이 없음
        case none

        static func == (l: TodayState, r: TodayState) -> Bool {
            switch (l, r) {
            case (.finished, .finished), (.none, .none): return true
            case let (.ongoing(a), .ongoing(b)):   return a.id == b.id
            case let (.upcoming(a), .upcoming(b)): return a.id == b.id
            default: return false
            }
        }
    }

    var todayState: TodayState {
        guard !todaySchedules.isEmpty else { return .none }
        let now = AppDate.minutesNow

        if let ongoing = todaySchedules.first(where: { s in
            guard let st = AppDate.minutes(s.startTime), let et = AppDate.minutes(s.endTime) else { return false }
            return st <= now && now < et
        }) {
            return .ongoing(ongoing)
        }

        // 진행 중인 게 없으면 아직 시작 안 한 것 중 가장 이른 것
        let upcoming = todaySchedules
            .filter { (AppDate.minutes($0.startTime) ?? 0) > now }
            .min { (AppDate.minutes($0.startTime) ?? 0) < (AppDate.minutes($1.startTime) ?? 0) }

        return upcoming.map { .upcoming($0) } ?? .finished
    }

    // MARK: - 홈 일정 칸 (정규 + 개인)

    /// 홈 일정 칸의 한 줄 — 정규(공용) 일정과 내가 추가한 개인 일정을 같은 모양으로 다룹니다
    struct HomeScheduleItem: Equatable {
        let id: String
        let title: String
        let startTime: String
        let endTime: String
        let dayNumber: Int
        let isPersonal: Bool

        /// 일차 → 시작 시각 순서로 비교하는 키
        var sortKey: String { String(format: "%03d ", dayNumber) + startTime }
    }

    private static func item(_ s: TravelerScheduleDTO) -> HomeScheduleItem {
        HomeScheduleItem(
            id: "s\(s.id)", title: title(of: s),
            startTime: s.startTime, endTime: s.endTime,
            dayNumber: s.dayNumber, isPersonal: false
        )
    }

    private static func item(_ p: TravelerPersonalScheduleDTO) -> HomeScheduleItem {
        HomeScheduleItem(
            id: "p\(p.id)", title: p.title,
            startTime: p.startTime, endTime: p.endTime,
            dayNumber: p.dayNumber, isPersonal: true
        )
    }

    private var todaySharedItems: [HomeScheduleItem] {
        todaySchedules.map { Self.item($0) }
    }

    /// 오늘의 개인 일정 — 정규 일정과 겹치는 것(서버 overlap_warning)은 빼서 정규 일정을 우선합니다
    private var todayPersonalItems: [HomeScheduleItem] {
        guard let today = home?.todayDayNumber else { return [] }
        return personalSchedules
            .filter { $0.dayNumber == today && !$0.overlapWarning }
            .map { Self.item($0) }
    }

    private static func isOngoing(_ item: HomeScheduleItem, now: Int) -> Bool {
        guard let start = AppDate.minutes(item.startTime), let end = AppDate.minutes(item.endTime) else { return false }
        return start <= now && now < end
    }

    /// 지금 진행 중인 일정 — 정규 일정 우선, 없으면 개인 일정
    ///
    /// 예정 일정은 여기 넣지 않습니다. 넣으면 "오늘의 일정"과 "다음 일정"에 같은 일정이 두 번 뜹니다.
    var currentItem: HomeScheduleItem? {
        let now = AppDate.minutesNow
        return todaySharedItems.first { Self.isOngoing($0, now: now) }
            ?? todayPersonalItems.first { Self.isOngoing($0, now: now) }
    }

    /// 진행 중인 일정이 없을 때 "오늘의 일정" 칸 문구 (정규 + 개인 기준)
    var noCurrentScheduleText: String {
        let all = todaySharedItems + todayPersonalItems
        if all.isEmpty { return "오늘은 등록된 일정이 없어요" }
        let now = AppDate.minutesNow
        let allEnded = all.allSatisfy { (AppDate.minutes($0.endTime) ?? 0) <= now }
        return allEnded ? "오늘 일정이 모두 끝났어요" : "지금 진행 중인 일정이 없어요"
    }

    /// 다음 일정 — 서버가 계산한 다음 정규 일정과 오늘 남은 개인 일정 중 더 이른 것
    var nextItem: HomeScheduleItem? {
        let now = AppDate.minutesNow
        let upcomingPersonal = todayPersonalItems
            .filter { (AppDate.minutes($0.startTime) ?? 0) > now }
            .min { $0.sortKey < $1.sortKey }
        let serverNext = home?.nextSchedule.map { Self.item($0) }
        guard let next = [serverNext, upcomingPersonal].compactMap({ $0 }).min(by: { $0.sortKey < $1.sortKey }) else {
            return nil
        }
        return next.id == currentItem?.id ? nil : next
    }

    /// "2025.04.24 출발"
    var departureDateText: String {
        guard let trip = home?.trip else { return "" }
        return "\(Self.displayDate(trip.startDate)) 출발"
    }

    /// 진행률 카드 제목 — 여행 중에는 카드가 남은 일수로 만듭니다
    var progressHeadline: String? {
        switch phase {
        case .before:   return "여행 시작까지 D-\(dDay)"
        case .finished: return "여행 진행률 · 일정 종료"
        case .during:   return nil
        }
    }

    /// 진행률 카드의 퍼센트 자리 문구 — 시작 전·종료 후
    var progressStatus: String? {
        switch phase {
        case .before:   return "출발 준비 중이에요"
        case .finished: return "여행 완료 · 수고하셨어요!"
        case .during:   return nil
        }
    }

    // MARK: - 여행 진행률 카드
    //
    // 서버가 준 값만 그대로 넘기고, 진행률·남은 일수·퍼센트 문구는 카드가 만듭니다.

    /// 오늘이 며칠째인지 — 서버 today_day_number
    var todayDayNumber: Int { home?.todayDayNumber ?? 0 }

    /// 여행 전체 일수 — 서버 duration_days
    var tripTotalDays: Int { home?.trip.durationDays ?? 0 }

    /// 카드 오른쪽 목적지
    ///
    /// 디자인에는 "제주 / 맑음 22°C"처럼 날씨가 붙지만 서버가 주지 않습니다.
    /// 기상청 API는 개인 키가 필요해 배포용으로 쓸 수 없어, 서버가 내려줄 때까지 목적지만 표시합니다.
    var destinationText: String { home?.trip.destination ?? "" }

    /// 오늘 일정의 진행률 (0...1) — 진행 인디케이터
    ///
    /// 기획: 당일 첫 일정 시작 ~ 마지막 일정 종료 시각 대비 현재 시각 비율.
    /// 시작 전 0%, 종료 후 100%로 고정합니다.
    ///
    /// 여행지 현지 시각이 기준이어야 하지만 API가 여행의 시간대를 주지 않아
    /// 기기 시각으로 계산합니다 (국내 여행은 동일).
    var todayProgress: Double {
        let starts = todaySchedules.compactMap { AppDate.minutes($0.startTime) }
        let ends   = todaySchedules.compactMap { AppDate.minutes($0.endTime) }
        guard let first = starts.min(), let last = ends.max(), last > first else { return 0 }
        let now = AppDate.minutesNow
        return min(max(Double(now - first) / Double(last - first), 0), 1)
    }

    /// 여행 전체 진행률 (0...1) — 진행률 카드
    ///
    /// 여행 기간(시작일 0시 ~ 종료일 24시) 중 지금 시각의 비율입니다. 시작 전 0, 종료 후 1.
    /// 오늘 일정 기준으로 계산하면 일정 전·일정 없는 날에는 0%로 멈춰 있어서 전체 기간 기준으로 바꿨습니다.
    /// 화면을 그릴 때 계산하므로 홈에 들어올 때마다 갱신됩니다.
    var tripProgress: Double {
        guard let trip = home?.trip,
              let start = AppDate.day(trip.startDate),
              let lastDay = AppDate.day(trip.endDate),
              let end = Calendar.current.date(byAdding: .day, value: 1, to: lastDay) else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(max(Date().timeIntervalSince(start) / total, 0), 1)
    }

    // MARK: - 공지

    /// 홈에 표시할 대표 공지 — 활성 공지 중 가장 최근 게시분
    var representativeNotice: TravelerNoticeDTO? {
        activeNotices.first
    }

    /// 지난 공지 — 팝업의 "이전 공지 보기"
    ///
    /// 기획상 "비활성(과거) 공지 최신순"입니다. 활성 공지는 대표 1건으로만 보여줍니다.
    var previousNotices: [TravelerNoticeDTO] {
        notices.filter { $0.isActive == false }
    }

    /// 활성 공지만 — 홈 미리보기와 안 읽음 뱃지의 기준
    private var activeNotices: [TravelerNoticeDTO] {
        notices.filter { $0.isActive != false }
    }

    /// 공지를 열어봤을 때 — 서버에 읽음을 보내고 빨간 점을 지웁니다
    func markNoticeRead(_ notice: TravelerNoticeDTO) {
        guard notice.isRead != true else { return }
        repository.markNoticeRead(id: notice.id)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.reloadNotices() },
                       onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func reloadNotices() {
        repository.fetchNotices()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.notices = $0 },
                       onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    var hasUnreadNotice: Bool { unreadNoticeCount > 0 }

    // MARK: - 담당자

    var managerPhone: String? {
        home?.managerContact?["phone"] ?? home?.trip.managerContact?["phone"]
    }

    // MARK: - 표시 헬퍼

    /// "15:00:00" + "16:00:00" → "15:00 - 16:00"
    static func timeRange(_ start: String, _ end: String) -> String {
        "\(AppDate.hhmm(start)) - \(AppDate.hhmm(end))"
    }

    /// 일정 제목 — 장소명 우선, 없으면 주요 내용
    static func title(of s: TravelerScheduleDTO) -> String {
        if let p = s.placeName, !p.isEmpty { return p }
        if let m = s.mainContent, !m.isEmpty { return m }
        return "일정"
    }

    /// "2025-04-24" → "2025.04.24"
    private static func displayDate(_ ymd: String) -> String {
        ymd.replacingOccurrences(of: "-", with: ".")
    }

}
