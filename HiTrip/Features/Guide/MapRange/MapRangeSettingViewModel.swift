import Foundation
import CoreLocation
import RxSwift

// MARK: - MapRangeSettingViewModel
/// 지도 범위 설정 (지오펜스) — Figma 12380:1051
///
/// - GET  /api/trips/{id}/geofences/                 일차별 설정
/// - POST /api/trips/{id}/geofences/                 미설정 일차 새로 만들기
/// - POST /api/trips/{id}/geofences/copy-previous/   전일 설정 복사
/// - PATCH /api/trips/{id}/geofences/{gid}/          수정 (expected_revision 낙관적 잠금)
///
/// 저장한 좌표는 고정입니다. 안내사가 이동해도 원이 따라오지 않습니다.

@MainActor
final class MapRangeSettingViewModel: NSObject, ObservableObject {

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var trip: StaffTripDTO?
    @Published private(set) var geofences: [GeofenceDTO] = []
    @Published var selectedDay: Int = 1

    /// 편집 중인 값 — 저장 전까지는 서버에 반영되지 않습니다
    @Published var centerCoordinate: CLLocationCoordinate2D?
    @Published var radiusKm: Int = 3
    @Published private(set) var centerAddress: String = ""

    @Published private(set) var isSaving = false
    @Published var saveError: String?
    @Published var toast: String?

    /// 내 위치 — "내 위치로 중심 설정"에 씁니다
    @Published private(set) var myLocation: CLLocationCoordinate2D?
    @Published private(set) var locationDenied = false

    private let repository: StaffRepositoryProtocol
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    /// 저장된 값 — 미저장 변경이 있는지 비교합니다
    private var savedCenter: CLLocationCoordinate2D?
    private var savedRadius: Int = 3

    init(repository: StaffRepositoryProtocol = AppDIContainer.shared.staffRepositoryForGuide) {
        self.repository = repository
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
                    self.trip = trip
                    self.selectedDay = self.todayDayNumber ?? 1
                    self.refresh()
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)

        requestLocation()
    }

    func refresh() {
        guard let tripId = trip?.id else { return }

        repository.fetchGeofences(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] list in
                    self?.geofences = list
                    self?.state = .loaded
                    self?.applyDay(self?.selectedDay ?? 1)
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 일차

    var totalDays: Int {
        guard let trip,
              let start = AppDate.day(trip.startDate),
              let end = AppDate.day(trip.endDate),
              let days = Calendar.current.dateComponents([.day], from: start, to: end).day
        else { return 1 }
        return max(days + 1, 1)
    }

    /// 스태프 API에 today_day_number가 없어 시작일로 계산합니다
    var todayDayNumber: Int? {
        guard let start = AppDate.day(trip?.startDate) else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let days = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
        return days >= 0 ? days + 1 : nil
    }

    func geofence(for day: Int) -> GeofenceDTO? {
        geofences.first { $0.dayNumber == day }
    }

    var currentGeofence: GeofenceDTO? { geofence(for: selectedDay) }

    /// 이 일차가 아직 설정되지 않았는지 — 전일 복사를 제안합니다
    var isUnset: Bool { currentGeofence == nil }

    func select(day: Int) {
        selectedDay = day
        applyDay(day)
    }

    /// 선택한 일차의 저장값을 편집 상태로 옮깁니다.
    /// 미설정 일차면 전일 값을 기본값으로 제안합니다.
    private func applyDay(_ day: Int) {
        if let fence = geofence(for: day) {
            centerCoordinate = Self.coordinate(fence)
            radiusKm = fence.radiusKm
            centerAddress = fence.centerAddress ?? ""
        } else if let previous = geofences.last(where: { $0.dayNumber < day }) {
            centerCoordinate = Self.coordinate(previous)
            radiusKm = previous.radiusKm
            centerAddress = previous.centerAddress ?? ""
        } else {
            centerCoordinate = myLocation
            radiusKm = 3
            centerAddress = ""
            reverseGeocode()
        }
        savedCenter = centerCoordinate
        savedRadius = radiusKm
    }

    /// 저장하지 않은 변경이 있는지 — 나가기 확인에 씁니다
    var hasUnsavedChanges: Bool {
        if radiusKm != savedRadius { return true }
        guard let current = centerCoordinate, let saved = savedCenter else {
            return centerCoordinate != nil
        }
        return abs(current.latitude - saved.latitude) > 0.000001
            || abs(current.longitude - saved.longitude) > 0.000001
    }

    // MARK: - 중심 지정

    /// 지도 롱프레스·주소 검색 결과로 중심을 옮깁니다
    func setCenter(_ coordinate: CLLocationCoordinate2D) {
        centerCoordinate = coordinate
        reverseGeocode()
    }

    func useMyLocation() {
        guard let myLocation else {
            if locationDenied { toast = "위치 권한을 허용해주세요" }
            return
        }
        setCenter(myLocation)
    }

    private func reverseGeocode() {
        guard let coordinate = centerCoordinate else { return }
        geocoder.reverseGeocodeLocation(
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        ) { [weak self] marks, _ in
            guard let mark = marks?.first else { return }
            let text = [mark.locality, mark.subLocality, mark.thoroughfare, mark.subThoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
            Task { @MainActor in
                self?.centerAddress = text.isEmpty ? "주소를 확인할 수 없어요" : text
            }
        }
    }

    // MARK: - 저장

    func save() {
        guard let tripId = trip?.id, let center = centerCoordinate else { return }
        isSaving = true

        let lat = String(format: "%.6f", center.latitude)
        let lng = String(format: "%.6f", center.longitude)

        let request: Single<GeofenceDTO>
        if let fence = currentGeofence {
            request = repository.updateGeofence(
                tripId: tripId, id: fence.id,
                centerLat: lat, centerLng: lng, radiusKm: radiusKm,
                expectedRevision: fence.revision
            )
        } else {
            request = repository.createGeofence(
                tripId: tripId, dayNumber: selectedDay,
                centerLat: lat, centerLng: lng,
                centerAddress: centerAddress, radiusKm: radiusKm
            )
        }

        request
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isSaving = false
                    self?.toast = "저장되었습니다"
                    self?.refresh()
                },
                onFailure: { [weak self] error in
                    self?.isSaving = false
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 위치 권한

    private func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted: locationDenied = true
        default: locationManager.startUpdatingLocation()
        }
    }

    func stop() { locationManager.stopUpdatingLocation() }

    // MARK: - 헬퍼

    private static func coordinate(_ fence: GeofenceDTO) -> CLLocationCoordinate2D? {
        guard let lat = Double(fence.centerLat), let lng = Double(fence.centerLng) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "연결을 확인해주세요"
            case .conflict:                 return "다른 기기에서 먼저 수정했어요. 새로고침 후 다시 시도해주세요"
            default:                        break
            }
        }
        return "저장하지 못했어요"
    }
}

// MARK: - CLLocationManagerDelegate

extension MapRangeSettingViewModel: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            let isFirst = self.myLocation == nil
            self.myLocation = coordinate
            // 아직 설정이 없는 일차면 현재 위치를 기본 중심으로 잡아 줍니다
            if isFirst, self.centerCoordinate == nil {
                self.setCenter(coordinate)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationDenied = false
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.locationDenied = true
            default:
                break
            }
        }
    }
}
