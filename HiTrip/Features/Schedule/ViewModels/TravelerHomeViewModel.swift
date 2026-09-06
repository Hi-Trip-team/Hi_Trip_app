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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

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

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden:  return "로그인이 필요합니다"
            case .noConnection:              return "네트워크에 연결되어 있지 않습니다"
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
    var unreadNoticeCount: Int { notices.filter { $0.isRead != true }.count }

    // MARK: - 여행 시작 전 / 진행 중

    /// 출발까지 남은 일수. 0 이하면 여행 중.
    var dDay: Int { home?.trip.dDay ?? 0 }

    var isBeforeTrip: Bool { dDay > 0 }

    /// "D-3 · 2025.04.24 출발"
    var departureText: String {
        guard let trip = home?.trip else { return "" }
        return "D-\(trip.dDay) · \(Self.displayDate(trip.startDate)) 출발"
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
        let now = Self.minutesNow()

        if let ongoing = todaySchedules.first(where: { s in
            guard let st = Self.minutes(s.startTime), let et = Self.minutes(s.endTime) else { return false }
            return st <= now && now < et
        }) {
            return .ongoing(ongoing)
        }

        // 진행 중인 게 없으면 아직 시작 안 한 것 중 가장 이른 것
        let upcoming = todaySchedules
            .filter { (Self.minutes($0.startTime) ?? 0) > now }
            .min { (Self.minutes($0.startTime) ?? 0) < (Self.minutes($1.startTime) ?? 0) }

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

    /// 여행 전체 진행률 (0...1)
    ///
    /// 서버가 준 오늘 일차(today_day_number)와 전체 일수(duration_days)로 계산합니다.
    var tripProgress: Double {
        guard let total = home?.trip.durationDays, total > 0,
              let today = home?.todayDayNumber else { return 0 }
        return min(max(Double(today) / Double(total), 0), 1)
    }

    /// "65% 완료"
    var tripProgressText: String {
        "\(Int((tripProgress * 100).rounded()))% 완료"
    }

    /// "여행 진행률 · 3일 남음"
    var tripProgressHeadline: String {
        guard let total = home?.trip.durationDays, let today = home?.todayDayNumber else {
            return "여행 진행률"
        }
        let remaining = total - today
        if remaining > 0  { return "여행 진행률 · \(remaining)일 남음" }
        if remaining == 0 { return "여행 진행률 · 오늘이 마지막 날" }
        return "여행 진행률 · 일정 종료"
    }

    /// 카드 오른쪽 목적지
    ///
    /// 디자인에는 "제주 / 맑음 22°C"처럼 날씨가 붙지만 서버가 주지 않습니다.
    /// 기상청 API는 개인 키가 필요해 배포용으로 쓸 수 없어, 서버가 내려줄 때까지 목적지만 표시합니다.
    var destinationText: String { home?.trip.destination ?? "" }

    /// 오늘 일정의 진행률 (0...1) — 진행률 바
    var progress: Double {
        let times = todaySchedules.compactMap { Self.minutes($0.startTime) }
        let ends  = todaySchedules.compactMap { Self.minutes($0.endTime) }
        guard let first = times.min(), let last = ends.max(), last > first else { return 0 }
        let now = Self.minutesNow()
        return min(max(Double(now - first) / Double(last - first), 0), 1)
    }

    // MARK: - 공지

    /// 홈에 표시할 대표 공지 — 가장 최근 게시분
    var representativeNotice: TravelerNoticeDTO? { notices.first }

    var hasUnreadNotice: Bool { unreadNoticeCount > 0 }

    // MARK: - 담당자

    var managerPhone: String? {
        home?.managerContact?["phone"] ?? home?.trip.managerContact?["phone"]
    }

    // MARK: - 표시 헬퍼

    /// "15:00:00" + "16:00:00" → "15:00 - 16:00"
    static func timeRange(_ start: String, _ end: String) -> String {
        "\(hhmm(start)) - \(hhmm(end))"
    }

    static func hhmm(_ time: String) -> String {
        time.split(separator: ":").prefix(2).joined(separator: ":")
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

    private static func minutes(_ time: String) -> Int? {
        let p = time.split(separator: ":").compactMap { Int($0) }
        guard p.count >= 2 else { return nil }
        return p[0] * 60 + p[1]
    }

    private static func minutesNow() -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
