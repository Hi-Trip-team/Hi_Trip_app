import Foundation
import CoreLocation
import RxSwift

// MARK: - NearbySpotViewModel
/// 주변 인기 스팟 (지도)
///
/// - GET /api/v1/tourist/nearby-spots/?category=&lat=&lng=  상황별 검색
/// - GET /api/v1/tourist/safety/summary/                    지오펜스(허용 반경)
/// - POST /api/v1/tourist/safety/location/                  위치 스냅샷 전송
///
/// 이탈 판정은 앱이 직접 합니다. 경계 밖에 연속 60초 머무르면 배너를 띄우고,
/// 안내사 알림은 서버가 위치 스냅샷을 받아 처리합니다.

@MainActor
final class NearbySpotViewModel: NSObject, ObservableObject {

    // MARK: - 카테고리

    /// 서버 enum과 화면 문구를 짝지어 둡니다.
    /// 기획의 6종 중 "할랄"은 서버 enum에 없어 빠져 있습니다.
    enum Category: String, CaseIterable, Identifiable {
        case restaurant    = "restaurant"
        case accessibility = "accessibility"
        case pet           = "pet"
        case convenience   = "convenience"
        case mart          = "mart"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .restaurant:    return "음식점"
            case .accessibility: return "무장애"
            case .pet:           return "반려동물"
            case .convenience:   return "편의점"
            case .mart:          return "마트"
            }
        }
    }

    enum LoadState: Equatable {
        case idle, loading, loaded
        case failed(String)
    }

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var spots: [TravelerNearbySpotDTO] = []
    @Published var selectedCategory: Category = .restaurant
    @Published var focusedSpotId: String?

    /// 지오펜스(허용 반경) — 없으면 지도에 원을 그리지 않습니다
    @Published private(set) var geofence: TravelerGeofenceDTO?

    /// 현재 위치와 수평 오차(m)
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    @Published private(set) var accuracyM: Double?
    @Published private(set) var authorizationDenied = false

    /// 안전 구역을 벗어난 상태 — 상단 경고 배너
    @Published private(set) var isOutsideGeofence = false

    /// GPS 오차가 큰 상태 — "정확도 낮음" 칩
    var isAccuracyLow: Bool { (accuracyM ?? 0) > 50 }

    // MARK: - Dependencies

    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()

    /// 경계 밖에서 머물기 시작한 시각 — 연속 60초를 재기 위한 기준
    private var outsideSince: Date?
    /// 위치 스냅샷을 서버로 보낸 마지막 시각 (30초 간격)
    private var lastSnapshotAt: Date?

    private let outsideThreshold: TimeInterval = 60
    private let snapshotInterval: TimeInterval = 30

    init(repository: TravelerRepositoryProtocol = AppDIContainer.shared.travelerRepositoryForHome) {
        self.repository = repository
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }

    // MARK: - Load

    func onAppear() {
        requestLocationPermission()
        loadGeofence()
    }

    func onDisappear() {
        locationManager.stopUpdatingLocation()
    }

    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorizationDenied = true
        default:
            authorizationDenied = false
            locationManager.startUpdatingLocation()
        }
    }

    private func loadGeofence() {
        repository.fetchSafetySummary()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] summary in self?.geofence = summary.geofence },
                       onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    /// 선택한 카테고리로 주변 스팟을 불러옵니다.
    func loadSpots() {
        guard let center = currentLocation ?? geofenceCenter else { return }
        state = .loading

        repository.fetchNearbySpots(
            category: selectedCategory.rawValue,
            lat: center.latitude,
            lng: center.longitude,
            radius: nil
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] spots in
                guard let self else { return }
                // 안내사 설정(광고) 스팟이 1순위, 그다음 거리순입니다.
                self.spots = spots.sorted { a, b in
                    if (a.isSponsored == true) != (b.isSponsored == true) { return a.isSponsored == true }
                    return (a.distanceM ?? .max) < (b.distanceM ?? .max)
                }
                self.focusedSpotId = self.spots.first?.id
                self.state = .loaded
            },
            onFailure: { [weak self] error in
                self?.state = .failed(Self.message(for: error))
            }
        )
        .disposed(by: disposeBag)
    }

    /// 칩 재탭이면 해제 대신 같은 카테고리를 유지합니다.
    /// 서버가 category를 필수로 받아 "전체" 조회가 없기 때문입니다.
    func select(_ category: Category) {
        guard selectedCategory != category else { return }
        selectedCategory = category
        loadSpots()
    }

    // MARK: - 지오펜스

    private var geofenceCenter: CLLocationCoordinate2D? {
        guard let lat = geofence?.latitude, let lng = geofence?.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// 경계 밖에 연속 60초 이상 머물렀는지 판정합니다.
    /// GPS 오차만큼은 봐줍니다 (오차 버퍼 가산).
    private func evaluateGeofence(for location: CLLocation) {
        guard let center = geofenceCenter, let radius = geofence?.radiusM else {
            isOutsideGeofence = false
            outsideSince = nil
            return
        }

        let distance = location.distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
        let buffer = max(location.horizontalAccuracy, 0)

        if distance > radius + buffer {
            if let since = outsideSince {
                if Date().timeIntervalSince(since) >= outsideThreshold { isOutsideGeofence = true }
            } else {
                outsideSince = Date()
            }
        } else {
            // 복귀하면 바로 해제합니다
            outsideSince = nil
            isOutsideGeofence = false
        }
    }

    /// 서버에도 위치를 남깁니다 (안내사 알림·이탈 이력은 서버가 처리)
    private func sendSnapshotIfNeeded(_ location: CLLocation) {
        if let last = lastSnapshotAt, Date().timeIntervalSince(last) < snapshotInterval { return }
        lastSnapshotAt = Date()

        repository.sendLocationSnapshot(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracyM: location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil
        )
        .subscribe(onSuccess: { _ in }, onFailure: { _ in })
        .disposed(by: disposeBag)
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .noConnection: return "연결을 확인해주세요"
            case .timeout:      return "서버 응답이 없습니다"
            default:            break
            }
        }
        return "정보를 불러오지 못했어요"
    }
}

// MARK: - CLLocationManagerDelegate

extension NearbySpotViewModel: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            let isFirstFix = self.currentLocation == nil
            self.currentLocation = location.coordinate
            self.accuracyM = location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil
            self.evaluateGeofence(for: location)
            self.sendSnapshotIfNeeded(location)
            // 첫 위치를 잡은 뒤에 주변 스팟을 부릅니다
            if isFirstFix { self.loadSpots() }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.authorizationDenied = false
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.authorizationDenied = true
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
}
