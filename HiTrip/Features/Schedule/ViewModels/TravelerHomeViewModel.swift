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

    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()

    init(repository: TravelerRepositoryProtocol = AppDIContainer.shared.travelerRepositoryForHome) {
        self.repository = repository
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
    }

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

    /// 현재 진행 중인 일정 — 지금 시각이 걸쳐 있는 것, 없으면 첫 일정
    var currentSchedule: TravelerScheduleDTO? {
        let now = Self.minutesNow()
        return todaySchedules.first { s in
            guard let st = Self.minutes(s.startTime), let et = Self.minutes(s.endTime) else { return false }
            return st <= now && now < et
        } ?? todaySchedules.first
    }

    /// 다음 일정 — 서버가 준 것을 우선 사용
    var nextSchedule: TravelerScheduleDTO? {
        if let n = home?.nextSchedule { return n }
        guard let current = currentSchedule,
              let idx = todaySchedules.firstIndex(where: { $0.id == current.id }) else { return nil }
        return todaySchedules.indices.contains(idx + 1) ? todaySchedules[idx + 1] : nil
    }

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
