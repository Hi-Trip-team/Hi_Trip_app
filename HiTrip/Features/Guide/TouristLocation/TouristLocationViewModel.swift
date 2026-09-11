import Foundation
import CoreLocation
import RxSwift

// MARK: - TouristLocationViewModel
/// 관광객 위치 확인 — Figma 12381:4267
///
/// - GET /api/monitoring/trips/{id}/latest/   관광객 좌표 (10초 갱신)
/// - GET /api/v1/trips/{id}/geofences/        허용 범위 경계
///
/// 안내사 본인 위치는 기기 GPS를 씁니다. 주소는 좌표를 역지오코딩합니다.

@MainActor
final class TouristLocationViewModel: NSObject, ObservableObject {

    // MARK: - State

    @Published private(set) var participant: ParticipantLatestDTO?
    @Published private(set) var profile: TravelerDetailDTO?
    @Published private(set) var geofence: GeofenceDTO?
    @Published private(set) var address: String = ""
    @Published private(set) var measuredAt: Date?
    @Published private(set) var guideLocation: CLLocationCoordinate2D?

    /// 범위 밖에 있었다가 돌아오면 한 번 알립니다
    @Published var returnedNotice = false

    private let participantId: Int
    private let repository: StaffRepositoryProtocol
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var tripId: Int?
    private var pollingTask: Task<Void, Never>?
    private var wasOutside = false
    /// 역지오코딩을 좌표가 크게 바뀔 때만 다시 합니다
    private var lastGeocodedCoordinate: CLLocationCoordinate2D?

    init(
        participantId: Int,
        repository: StaffRepositoryProtocol = AppDIContainer.shared.staffRepositoryForGuide
    ) {
        self.participantId = participantId
        self.repository = repository
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - 표시값

    var touristName: String { participant?.travelerName ?? "" }

    var touristCoordinate: CLLocationCoordinate2D? {
        guard let lat = participant?.location?.latitude.flatMap(Double.init),
              let lng = participant?.location?.longitude.flatMap(Double.init) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var geofenceCenter: CLLocationCoordinate2D? {
        guard let g = geofence,
              let lat = Double(g.centerLat), let lng = Double(g.centerLng) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var geofenceRadiusM: Double? {
        geofence.map { Double($0.radiusKm) * 1000 }
    }

    /// GPS가 끊겼는지 — 마지막 수신이 2분을 넘으면 옛 위치로 봅니다
    var isStale: Bool {
        guard let measuredAt else { return true }
        return Date().timeIntervalSince(measuredAt) > 120
    }

    /// "10초 전 갱신" 또는 "마지막 수신 위치 · 5분 전"
    var updatedText: String {
        guard let measuredAt else { return "위치 수신 대기 중" }
        let seconds = Int(Date().timeIntervalSince(measuredAt))

        if isStale {
            let minutes = max(seconds / 60, 1)
            return "마지막 수신 위치 · \(minutes)분 전"
        }
        return seconds < 10 ? "방금 갱신" : "\(seconds)초 전 갱신"
    }

    var phoneNumber: String? { profile?.phone }

    // MARK: - Load

    func load() {
        repository.fetchTrips()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] trips in
                guard let self, let trip = trips.current else { return }
                self.tripId = trip.id
                self.loadGeofence(tripId: trip.id)
                self.loadProfile(tripId: trip.id)
                self.refresh()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)

        requestGuideLocation()
    }

    private func loadGeofence(tripId: Int) {
        repository.fetchGeofences(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                // 오늘 일차 것이 있으면 그것을, 없으면 가장 최근 것을 씁니다
                self?.geofence = list.last(where: { $0.isActive }) ?? list.last
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func loadProfile(tripId: Int) {
        repository.fetchParticipants(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                guard let self else { return }
                self.profile = list.first { $0.id == self.participantId }?.traveler
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    /// 관광객 좌표 — 10초마다 다시 받습니다
    func refresh() {
        guard let tripId else { return }

        repository.fetchParticipantsLatest(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                guard let self,
                      let target = list.first(where: { $0.participantId == self.participantId })
                else { return }

                self.participant = target
                self.measuredAt = Self.date(from: target.location?.measuredAt)
                self.updateGeocodeIfNeeded()
                self.checkReturned(target)
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        locationManager.stopUpdatingLocation()
    }

    /// 범위 밖 → 안으로 돌아오면 토스트를 띄웁니다
    private func checkReturned(_ target: ParticipantLatestDTO) {
        let isOutside = target.geofenceIncident != nil
        if wasOutside && !isOutside { returnedNotice = true }
        wasOutside = isOutside
    }

    // MARK: - 주소

    private func updateGeocodeIfNeeded() {
        guard let coordinate = touristCoordinate else { return }

        if let last = lastGeocodedCoordinate {
            let moved = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            // 30m 이내면 주소가 그대로일 가능성이 커서 다시 묻지 않습니다
            guard moved > 30 else { return }
        }
        lastGeocodedCoordinate = coordinate

        geocoder.reverseGeocodeLocation(
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        ) { [weak self] marks, _ in
            guard let mark = marks?.first else { return }
            let parts = [mark.locality, mark.subLocality, mark.thoroughfare, mark.subThoroughfare]
            let text = parts.compactMap { $0 }.joined(separator: " ")
            Task { @MainActor in
                self?.address = text.isEmpty ? "주소를 확인할 수 없어요" : "\(text) 인근"
            }
        }
    }

    // MARK: - 안내사 위치

    private func requestGuideLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted: break
        default: locationManager.startUpdatingLocation()
        }
    }

    private static func date(from iso: String?) -> Date? {
        guard let iso else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return parser.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
    }
}

// MARK: - CLLocationManagerDelegate

extension TouristLocationViewModel: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in self.guideLocation = coordinate }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
