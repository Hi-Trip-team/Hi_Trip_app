import Foundation
import RxSwift

// MARK: - AlertCenterViewModel
/// 알림 센터 — Figma 12381:4544 (신규 화면)
///
/// - GET  /api/monitoring/trips/{id}/alerts/                        경고·위험·이탈 알림
/// - POST /api/monitoring/trips/{id}/incidents/{iid}/acknowledge/   위험 알림 [확인]
///
/// 읽음 상태는 서버 is_read(확인 처리 시 true)를 따르고, 탭한 카드는 앱에서도 바로 회색으로 바꿉니다.

@MainActor
final class AlertCenterViewModel: ObservableObject {

    /// 필터 칩 — 기획의 5종
    enum Kind: String, CaseIterable, Identifiable {
        case all, danger, warning, escaped, normal

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:     return "전체"
            case .danger:  return "위험"
            case .warning: return "경고"
            case .escaped: return "이탈"
            case .normal:  return "일반"
            }
        }
    }

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var alerts: [MonitoringAlertDTO] = []
    @Published var kind: Kind = .all

    /// 읽은 알림 id — 카드 배경을 회색으로 바꾸는 기준
    @Published private(set) var readIds: Set<Int> = []
    /// 확인 처리한 위험 알림 id — 재알림이 멈춥니다
    @Published private(set) var acknowledgedIds: Set<Int> = []

    private let repository: StaffRepositoryProtocol
    private let disposeBag = DisposeBag()
    private var tripId: Int?

    init(repository: StaffRepositoryProtocol = AppDIContainer.shared.staffRepositoryForGuide) {
        self.repository = repository
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
                        self.state = .loaded
                        return
                    }
                    self.tripId = trip.id
                    self.refresh()
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)
    }

    /// 이탈 알림 → 관광객 위치 확인 (서버 participant_id)
    func participantId(for alert: MonitoringAlertDTO) -> Int? {
        alert.participantId
    }

    func refresh() {
        guard let tripId else { return }
        repository.fetchAlerts(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] list in
                    self?.alerts = list.sorted { $0.createdAt > $1.createdAt }
                    self?.state = .loaded
                },
                onFailure: { [weak self] error in
                    if self?.alerts.isEmpty ?? true {
                        self?.state = .failed(Self.message(for: error))
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 목록

    var filtered: [MonitoringAlertDTO] { alerts.filter { matches($0) } }

    private func matches(_ alert: MonitoringAlertDTO) -> Bool {
        switch kind {
        case .all:     return true
        case .danger:  return alert.alertType != "location" && alert.severity == "danger"
        case .warning: return alert.alertType != "location" && alert.severity == "warning"
        case .escaped: return alert.alertType == "location"
        case .normal:  return alert.alertType != "location" && alert.alertType != "health"
        }
    }

    var isEmpty: Bool { filtered.isEmpty && state == .loaded }

    // MARK: - 카드 표시

    /// 뱃지 문구 — 이탈은 유형으로, 나머지는 심각도로 정합니다
    func badgeText(_ alert: MonitoringAlertDTO) -> String {
        if alert.alertType == "location" { return "이탈" }
        if alert.alertType != "health"   { return "일반" }
        return alert.severity == "danger" ? "위험" : "경고"
    }

    func isDangerous(_ alert: MonitoringAlertDTO) -> Bool {
        alert.alertType == "location" || alert.severity == "danger"
    }

    func isGeneral(_ alert: MonitoringAlertDTO) -> Bool {
        alert.alertType != "location" && alert.alertType != "health"
    }

    /// 카드 본문 — 서버 메시지에 이름이 없으면 앞에 붙입니다
    func messageText(_ alert: MonitoringAlertDTO) -> String {
        let name = alert.travelerName
        guard !name.isEmpty, !alert.message.contains(name) else { return alert.message }
        return "\(name)님 · \(alert.message)"
    }

    /// "10:24 · 탭하여 위치 확인"
    func metaText(_ alert: MonitoringAlertDTO) -> String {
        var parts = [AppDate.string(iso: alert.snapshotTime, "HH:mm")]
        if alert.alertType == "location" { parts.append("탭하여 위치 확인") }
        return parts.joined(separator: " · ")
    }

    func isRead(_ alert: MonitoringAlertDTO) -> Bool { alert.isRead == true || readIds.contains(alert.id) }

    /// 확인이 필요한 위험 알림인지 — [확인] 전까지 5분 주기로 다시 알립니다
    func needsAcknowledge(_ alert: MonitoringAlertDTO) -> Bool {
        alert.severity == "danger"
            && alert.incident != nil
            && !acknowledgedIds.contains(alert.id)
    }

    func markRead(_ alert: MonitoringAlertDTO) { readIds.insert(alert.id) }

    /// [확인] — 서버에 인지 처리를 남깁니다 (대응 이력)
    func acknowledge(_ alert: MonitoringAlertDTO) {
        guard let tripId, let incidentId = alert.incident else { return }
        acknowledgedIds.insert(alert.id)
        readIds.insert(alert.id)

        repository.acknowledgeIncident(tripId: tripId, incidentId: incidentId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] _ in self?.refresh() },
                       onFailure: { [weak self] _ in
                           self?.acknowledgedIds.remove(alert.id)
                       })
            .disposed(by: disposeBag)
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "연결을 확인해주세요"
            default:                        break
            }
        }
        return "알림을 불러오지 못했어요"
    }
}
