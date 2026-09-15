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

    /// 여행 시각 판정 — 여행지 시간대 + 기기 시계 (여행객 홈과 같은 TripClock)
    var clock: TripClock? {
        trip.flatMap { TripClock(startDate: $0.startDate, endDate: $0.endDate, timeZoneID: $0.timezone) }
    }

    /// 지금 시각(분) — 여행지 기준
    private var nowMinutes: Int { clock?.minutesNow ?? AppDate.minutesNow }

    /// 오늘이 며칠째인지 — 여행지 날짜 기준, 여행 기간이 아니면 nil
    /// (서버 today_day_number는 UTC라 새벽에 하루 어긋남)
    var todayDayNumber: Int? { clock?.todayDayNumber }

    var todaySchedules: [StaffScheduleDTO] {
        guard let day = todayDayNumber else { return [] }
        return schedules.filter { $0.dayNumber == day }.sorted { $0.startTime < $1.startTime }
    }

    /// 진행률 — 당일 첫 일정 시작 ~ 마지막 일정 종료 대비 현재 시각 (여행객 홈과 같은 규칙)
    var todayProgress: Double {
        let starts = todaySchedules.compactMap { AppDate.minutes($0.startTime) }
        let ends   = todaySchedules.compactMap { AppDate.minutes($0.endTime) }
        guard let first = starts.min(), let last = ends.max(), last > first else { return 0 }
        return min(max(Double(nowMinutes - first) / Double(last - first), 0), 1)
    }

    /// 여행 전체 진행률 — 여행 기간(시작일 0시 ~ 종료일 24시) 중 지금 시각의 비율 (여행객 홈과 같은 규칙)
    var tripProgress: Double { clock?.progress ?? 0 }

    /// 여행 종료까지 남은 일수 — 여행객 진행률 카드와 같은 의미 (마지막 날 0, 끝나면 음수)
    var remainingDays: Int { clock?.remainingDays ?? 0 }

    /// 진행률 카드 오른쪽 목적지
    var destinationText: String { trip?.destination ?? "" }

    /// 지금 진행 중인 일정 — 예정 일정은 "다음 일정"에만 (여행객 홈과 같은 규칙)
    var currentSchedule: StaffScheduleDTO? {
        let now = nowMinutes
        return todaySchedules.first {
            guard let s = AppDate.minutes($0.startTime), let e = AppDate.minutes($0.endTime) else { return false }
            return s <= now && now < e
        }
    }

    /// 진행 중인 일정이 없을 때 "오늘의 일정" 칸 문구
    var noCurrentScheduleText: String {
        // 여행 기간 밖이면 "오늘 일정 없음" 대신 상태를 알려줍니다 (여행객 홈과 같은 기준)
        switch clock?.phase {
        case .before?:   return "여행 시작 전이에요 · D-\(clock?.daysUntilStart ?? 0)"
        case .finished?: return "여행 일정이 모두 끝났어요"
        default:         break
        }
        if todaySchedules.isEmpty { return "오늘은 등록된 일정이 없어요" }
        let now = nowMinutes
        let allEnded = todaySchedules.allSatisfy { (AppDate.minutes($0.endTime) ?? 0) <= now }
        return allEnded ? "오늘 일정이 모두 끝났어요" : "지금 진행 중인 일정이 없어요"
    }

    /// 다음 일정 — 지금 이후 가장 이른 일정 (내일 이후 포함, 여행지 시각 기준)
    var nextSchedule: StaffScheduleDTO? {
        guard let clock else { return nil }
        let next = schedules
            .filter { clock.isAfterNow(dayNumber: $0.dayNumber, startTime: $0.startTime) }
            .min { ($0.dayNumber, $0.startTime) < ($1.dayNumber, $1.startTime) }
        guard let next, next.id != currentSchedule?.id else { return nil }
        return next
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
        "\(AppDate.hhmm(start)) - \(AppDate.hhmm(end))"
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
