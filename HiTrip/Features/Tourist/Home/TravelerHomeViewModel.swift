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
    @Published private(set) var unreadMessageCount: Int = 0

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

        repository.fetchPopularSpots()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.popularSpots = $0 },
                       onFailure: { _ in })
            .disposed(by: disposeBag)

        // 하단 "메시지 및 문의" 뱃지 — 전체 채팅방의 안 읽음 합계
        chatRepository.fetchAllRooms()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] rooms in
                self?.unreadMessageCount = rooms.reduce(0) { $0 + $1.unreadCount }
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    var hasUnreadMessage: Bool { unreadMessageCount > 0 }

    /// 뱃지 표기 — 세 자리부터는 99+로 줄입니다
    var unreadMessageBadgeText: String {
        unreadMessageCount > 99 ? "99+" : "\(unreadMessageCount)"
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

    /// 상단 카드에 띄울 일정 — 끝났거나 없으면 nil
    var currentSchedule: TravelerScheduleDTO? {
        switch todayState {
        case .ongoing(let s), .upcoming(let s): return s
        case .finished, .none:                  return nil
        }
    }

    /// 다음 일정 — 서버가 계산해 준 값을 씁니다.
    ///
    /// 진행 중인 일정이 없으면 상단 카드가 이미 다음 예정 일정을 보여주므로,
    /// 같은 일정이면 "다음 일정" 줄을 숨겨 중복 표시를 막습니다.
    var nextSchedule: TravelerScheduleDTO? {
        guard let next = home?.nextSchedule else { return nil }
        if let current = currentSchedule, current.id == next.id { return nil }
        return next
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
