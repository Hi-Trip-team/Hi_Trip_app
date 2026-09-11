import Foundation
import RxSwift

// MARK: - StaffHomeViewModel
/// 안내사 홈 — Figma 12381:5370
///
/// - GET /api/v1/staff/trips/                     담당 여행
/// - GET /api/v1/trips/{id}/schedules/            오늘의 일정
/// - GET /api/monitoring/trips/{id}/summary/      안전 현황 (30초 갱신)
/// - GET /api/monitoring/trips/{id}/alerts/       알림 뱃지·안전 빨간 점
///
/// 여행이 배정되지 않았으면 화면 전체를 안내 문구로 대체합니다.

@MainActor
final class StaffHomeViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle, loading, loaded
        /// 배정된 여행이 없음
        case noTrip
        case failed(String)
    }

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var trip: StaffTripDTO?
    @Published private(set) var schedules: [StaffScheduleDTO] = []
    @Published private(set) var summary: MonitoringSummaryDTO?
    @Published private(set) var alerts: [MonitoringAlertDTO] = []
    @Published private(set) var unreadMessageCount: Int = 0

    private let repository: StaffRepositoryProtocol
    private let chatRepository: ChatRepositoryProtocol
    private let disposeBag = DisposeBag()

    /// 안전 현황 30초 폴링
    private var pollingTask: Task<Void, Never>?

    init(
        repository: StaffRepositoryProtocol = AppDIContainer.shared.staffRepositoryForGuide,
        chatRepository: ChatRepositoryProtocol = AppDIContainer.shared.chatRepositoryForHome
    ) {
        self.repository = repository
        self.chatRepository = chatRepository
    }

    // MARK: - Load

    func load() {
        guard state != .loading else { return }
        state = .loading

        repository.fetchTrips()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] trips in
                    guard let self else { return }
                    guard let trip = trips.current else {
                        self.state = .noTrip
                        return
                    }
                    self.trip = trip
                    self.state = .loaded
                    self.loadSecondary(tripId: trip.id)
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)
    }

    /// 일정·안전·메시지 — 하나가 실패해도 나머지는 그립니다
    private func loadSecondary(tripId: Int) {
        repository.fetchSchedules(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.schedules = $0 }, onFailure: { _ in })
            .disposed(by: disposeBag)

        refreshSafety()

        chatRepository.fetchAllRooms()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] rooms in
                self?.unreadMessageCount = rooms.reduce(0) { $0 + $1.unreadCount }
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    /// 안전 현황만 다시 — 30초 폴링과 당겨서 새로고침이 함께 씁니다
    func refreshSafety() {
        guard let tripId = trip?.id else { return }

        repository.fetchSafetySummary(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.summary = $0 }, onFailure: { _ in })
            .disposed(by: disposeBag)

        repository.fetchAlerts(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.alerts = $0 }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    /// 화면이 보이는 동안만 30초마다 안전 현황을 갱신합니다
    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.refreshSafety()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - 표시값

    var tripTitle: String { trip?.title ?? "" }

    /// "안내사 김안내"
    var managerText: String {
        guard let name = trip?.managerName, !name.isEmpty else { return "" }
        return "안내사 \(name)"
    }

    /// 오늘이 며칠째인지 — 서버 today_day_number (여행 기간이 아니면 nil)
    var todayDayNumber: Int? { trip?.todayDayNumber }

    var todaySchedules: [StaffScheduleDTO] {
        guard let day = todayDayNumber else { return [] }
        return schedules.filter { $0.dayNumber == day }.sorted { $0.startTime < $1.startTime }
    }

    /// 진행률 — 당일 첫 일정 시작 ~ 마지막 일정 종료 대비 현재 시각 (여행객 홈과 같은 규칙)
    var todayProgress: Double {
        let starts = todaySchedules.compactMap { Self.minutes($0.startTime) }
        let ends   = todaySchedules.compactMap { Self.minutes($0.endTime) }
        guard let first = starts.min(), let last = ends.max(), last > first else { return 0 }
        return min(max(Double(Self.minutesNow() - first) / Double(last - first), 0), 1)
    }

    /// 지금 진행 중이거나 다음에 올 일정
    var currentSchedule: StaffScheduleDTO? {
        let now = Self.minutesNow()
        if let ongoing = todaySchedules.first(where: {
            guard let s = Self.minutes($0.startTime), let e = Self.minutes($0.endTime) else { return false }
            return s <= now && now < e
        }) { return ongoing }
        return todaySchedules.first { (Self.minutes($0.startTime) ?? 0) > now }
    }

    /// 그다음 일정 — 현재와 같으면 숨깁니다
    var nextSchedule: StaffScheduleDTO? {
        guard let current = currentSchedule,
              let idx = todaySchedules.firstIndex(where: { $0.id == current.id }),
              idx + 1 < todaySchedules.count else { return nil }
        return todaySchedules[idx + 1]
    }

    // MARK: - 안전 현황

    /// "전체 12명 · 경고 2 · 위험 1 · 이탈 1"
    var safetySummaryText: String {
        guard let s = summary else { return "집계를 불러오는 중이에요" }
        return "전체 \(s.total)명 · 경고 \(s.warning) · 위험 \(s.danger) · 이탈 \(escapedCount)"
    }

    /// 이탈 인원 — 서버 요약(escaped)
    var escapedCount: Int { summary?.escaped ?? 0 }

    /// 안전 관리 메뉴의 빨간 점 — 경고·위험 인원이 있으면 표시
    var hasSafetyIssue: Bool {
        guard let s = summary else { return false }
        return s.warning > 0 || s.danger > 0 || escapedCount > 0
    }

    /// 알림 종 뱃지 — 서버 기준 미확인(is_read=false) 알림 수
    var unreadAlertCount: Int { alerts.filter { $0.isRead != true }.count }

    var unreadMessageBadgeText: String {
        unreadMessageCount > 99 ? "99+" : "\(unreadMessageCount)"
    }

    // MARK: - 헬퍼

    static func timeRange(_ start: String, _ end: String) -> String {
        "\(hhmm(start)) - \(hhmm(end))"
    }

    static func hhmm(_ time: String) -> String {
        String(time.prefix(5))
    }

    private static func minutes(_ time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }

    private static func minutesNow() -> Int {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (now.hour ?? 0) * 60 + (now.minute ?? 0)
    }

    private static func date(from string: String?) -> Date? {
        guard let string else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: string)
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "연결을 확인해주세요"
            case .timeout:                  return "서버 응답이 없습니다"
            default:                        break
            }
        }
        return "정보를 불러오지 못했어요"
    }
}
