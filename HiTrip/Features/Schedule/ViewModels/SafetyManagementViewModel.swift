import Foundation
import RxSwift

// MARK: - SafetyManagementViewModel
/// 안전 관리 — Figma 12381:4446
///
/// - GET /api/monitoring/trips/{id}/summary/  상태별 집계
/// - GET /api/monitoring/trips/{id}/latest/   관광객별 최신 심박·SpO₂·위치
///
/// 30초마다 갱신합니다. 상태 판정(normal/warning/danger)은 서버 값을 그대로 씁니다.
/// 셀 단위 색(심박만 경고, SpO₂만 위험 등)은 서버가 지표별로 주지 않아
/// 여행 임계값(heart_rate_min/max)과 기획서의 SpO₂ 기준으로 계산합니다.

@MainActor
final class SafetyManagementViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle, loading, loaded
        case failed(String)
    }

    /// 칩 필터 — 재탭하면 해제됩니다
    enum Filter: Equatable {
        case warning, danger, escaped
    }

    /// 셀 색 단계
    enum Level {
        case normal, warning, danger
        /// 데이터 미수신 — 워치 미연동·배터리 방전·통신 두절
        case unknown
    }

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var summary: MonitoringSummaryDTO?
    @Published private(set) var participants: [ParticipantLatestDTO] = []
    /// 참가자 명부 — 연락처·국가·여권번호 (모니터링 응답에 없어 따로 받습니다)
    @Published private(set) var profiles: [Int: TravelerDetailDTO] = [:]
    @Published private(set) var updatedAt: Date?
    @Published var filter: Filter?

    private let repository: StaffRepositoryProtocol
    private let disposeBag = DisposeBag()
    private var pollingTask: Task<Void, Never>?

    private(set) var trip: StaffTripDTO?

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
                    guard let trip = trips.first else {
                        self.state = .loaded
                        return
                    }
                    self.trip = trip
                    self.loadProfiles(tripId: trip.id)
                    self.refresh()
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)
    }

    /// 참가자 명부는 자주 바뀌지 않아 진입 시 한 번만 받습니다
    private func loadProfiles(tripId: Int) {
        repository.fetchParticipants(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                self?.profiles = Dictionary(
                    uniqueKeysWithValues: list.compactMap { p in
                        p.traveler.map { (p.id, $0) }
                    }
                )
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    func profile(for p: ParticipantLatestDTO) -> TravelerDetailDTO? {
        profiles[p.participantId]
    }

    /// 팝업의 "위치보기" 활성 조건 — 이탈이거나 건강 경고·위험일 때만
    func canViewLocation(_ p: ParticipantLatestDTO) -> Bool {
        p.geofenceIncident != nil
            || p.healthStatus == .warning
            || p.healthStatus == .danger
    }

    /// "경계 밖 1.2km · 심박 110 · SpO₂ 95%"
    func statusLine(_ p: ParticipantLatestDTO) -> String {
        var parts: [String] = []
        if let distance = escapeDistanceText(p) { parts.append("경계 밖 \(distance)") }
        if let hr = p.health?.heartRate { parts.append("심박 \(hr)") }
        let spo2 = spo2Text(p)
        if spo2 != "—" { parts.append("SpO₂ \(spo2)%") }
        return parts.isEmpty ? "수신된 데이터가 없어요" : parts.joined(separator: " · ")
    }

    /// 집계와 명단을 다시 불러옵니다 — 폴링·당겨서 새로고침 공용
    func refresh() {
        guard let tripId = trip?.id else { return }

        repository.fetchSafetySummary(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in self?.summary = $0 }, onFailure: { _ in })
            .disposed(by: disposeBag)

        repository.fetchParticipantsLatest(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] list in
                    self?.participants = list
                    self?.updatedAt = Date()
                    self?.state = .loaded
                },
                onFailure: { [weak self] error in
                    if self?.participants.isEmpty ?? true {
                        self?.state = .failed(Self.message(for: error))
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - 목록

    /// 정렬: 위험 → 경고 → 정상, 동순위는 가나다
    var sortedParticipants: [ParticipantLatestDTO] {
        let filtered = participants.filter { matchesFilter($0) }
        return filtered.sorted { a, b in
            let ra = Self.rank(a.overallStatus), rb = Self.rank(b.overallStatus)
            if ra != rb { return ra < rb }
            return a.travelerName.localizedCompare(b.travelerName) == .orderedAscending
        }
    }

    private func matchesFilter(_ p: ParticipantLatestDTO) -> Bool {
        switch filter {
        case nil:        return true
        case .warning?:  return p.overallStatus == .warning
        case .danger?:   return p.overallStatus == .danger
        case .escaped?:  return p.geofenceIncident != nil
        }
    }

    private static func rank(_ status: MonitoringStatus) -> Int {
        switch status {
        case .danger:  return 0
        case .warning: return 1
        case .normal:  return 2
        default:       return 3
        }
    }

    /// 칩을 다시 누르면 해제합니다
    func toggle(_ target: Filter) {
        filter = (filter == target) ? nil : target
    }

    // MARK: - 집계

    var totalCount: Int { summary?.total ?? participants.count }
    var warningCount: Int { summary?.warning ?? participants.filter { $0.overallStatus == .warning }.count }
    var dangerCount: Int { summary?.danger ?? participants.filter { $0.overallStatus == .danger }.count }

    /// 이탈 인원 — 요약에 항목이 없어 열린 지오펜스 사고로 셉니다
    var escapedCount: Int { participants.filter { $0.geofenceIncident != nil }.count }

    var isEmpty: Bool { participants.isEmpty && state == .loaded }

    /// "10:24 기준 · 30초마다 갱신"
    var updatedText: String {
        guard let updatedAt else { return "갱신 대기 중 · 30초마다 갱신" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "HH:mm"
        return "\(f.string(from: updatedAt)) 기준 · 30초마다 갱신"
    }

    // MARK: - 셀 값

    /// 이탈 거리 — 사고 메시지에서 "1.2km"를 뽑습니다.
    /// 서버가 거리 필드를 따로 주지 않아 메시지를 파싱합니다.
    func escapeDistanceText(_ p: ParticipantLatestDTO) -> String? {
        guard let incident = p.geofenceIncident else { return nil }
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*(km|m)"#
        guard let match = incident.message.range(of: pattern, options: .regularExpression) else {
            return "이탈"
        }
        return String(incident.message[match]).replacingOccurrences(of: " ", with: "")
    }

    func heartRateText(_ p: ParticipantLatestDTO) -> String {
        p.health?.heartRate.map(String.init) ?? "—"
    }

    func spo2Text(_ p: ParticipantLatestDTO) -> String {
        guard let raw = p.health?.spo2, let value = Double(raw) else { return "—" }
        return String(Int(value.rounded()))
    }

    /// 심박 단계 — 여행 임계값(heart_rate_min/max) 밖이면 경고, 20bpm 이상 벗어나면 위험
    func heartRateLevel(_ p: ParticipantLatestDTO) -> Level {
        guard let hr = p.health?.heartRate else { return .unknown }
        let min = trip?.heartRateMin ?? 50
        let max = trip?.heartRateMax ?? 110

        if hr >= min && hr <= max { return .normal }
        let over = hr > max ? hr - max : min - hr
        return over > 20 ? .danger : .warning
    }

    /// SpO₂ — 기획서 기준: 정상 ≥95 · 경고 90~94 · 위험 <90
    func spo2Level(_ p: ParticipantLatestDTO) -> Level {
        guard let raw = p.health?.spo2, let value = Double(raw) else { return .unknown }
        if value < 90 { return .danger }
        if value < 95 { return .warning }
        return .normal
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "연결을 확인해주세요"
            default:                        break
            }
        }
        return "안전 정보를 불러오지 못했어요"
    }
}
