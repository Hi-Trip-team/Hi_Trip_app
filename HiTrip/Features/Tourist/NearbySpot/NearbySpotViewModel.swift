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

    /// 칩 순서대로 선언합니다.
    ///
    /// - 서버 주변 스팟 API 5종: restaurant · accessibility · pet · convenience · mart (광고 스팟 포함)
    /// - 그 밖의 카테고리는 카카오 로컬 API로 직접 검색합니다 (`kakaoCode`)
    /// 기획의 "할랄"은 서버·카카오 모두 카테고리가 없어 빠져 있습니다.
    enum Category: String, CaseIterable, Identifiable {
        /// 안내사가 미리 정한 추천·인기 스팟 — 맨 앞, 지도를 열면 기본 선택
        case popular       = "popular"
        case restaurant    = "restaurant"
        case cafe          = "cafe"
        case convenience   = "convenience"
        case mart          = "mart"
        case attraction    = "attraction"
        case culture       = "culture"
        case pharmacy      = "pharmacy"
        case hospital      = "hospital"
        case subway        = "subway"
        case accommodation = "accommodation"
        case accessibility = "accessibility"
        case pet           = "pet"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .popular:       return "인기 스팟"
            case .restaurant:    return "음식점"
            case .cafe:          return "카페"
            case .convenience:   return "편의점"
            case .mart:          return "마트"
            case .attraction:    return "관광명소"
            case .culture:       return "문화시설"
            case .pharmacy:      return "약국"
            case .hospital:      return "병원"
            case .subway:        return "지하철역"
            case .accommodation: return "숙박"
            case .accessibility: return "무장애"
            case .pet:           return "반려동물"
            }
        }

        /// 서버가 받지 않는 카테고리 — 카카오 로컬 API로 검색합니다. nil이면 서버 API
        var kakaoCode: KakaoLocalService.CategoryCode? {
            switch self {
            case .cafe:          return .cafe
            case .attraction:    return .attraction
            case .culture:       return .culture
            case .pharmacy:      return .pharmacy
            case .hospital:      return .hospital
            case .subway:        return .subway
            case .accommodation: return .accommodation
            case .popular, .restaurant, .convenience, .mart, .accessibility, .pet: return nil
            }
        }
    }

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var spots: [TravelerNearbySpotDTO] = []
    @Published var selectedCategory: Category = .popular
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
    /// 안전 구역으로 한 번이라도 판정했는지 — 첫 판정에서 밖이면 바로 알립니다
    private var hasEvaluatedGeofence = false
    /// 마지막 위치 — 안전 구역이 위치보다 늦게 도착하면 이 위치로 다시 판정합니다
    private var lastLocation: CLLocation?
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

    /// 붉은 안전 구역 선은 **여행 기간 안에서만** 보여줍니다.
    ///
    /// 서버 today_day_number가 없으면(여행 시작 전·종료 후) 경계선을 요청하지 않고 지웁니다.
    /// 여행 중에는 오늘 일차로 요청합니다 — 비워 보내면 서버가 "오늘"을 다시 판단합니다.
    private func loadGeofence() {
        repository.fetchHome()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] home in
                guard let self else { return }
                // 오늘 일차는 여행지 날짜로 계산합니다 (서버 today_day_number는 UTC라 새벽에 하루 어긋남)
                let clock = TripClock(startDate: home.trip.startDate, endDate: home.trip.endDate, timeZoneID: home.trip.timezone)
                guard let today = clock?.todayDayNumber else {
                    self.geofence = nil
                    return
                }
                self.loadSafetySummary(dayNumber: today)
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func loadSafetySummary(dayNumber: Int) {
        repository.fetchSafetySummary(dayNumber: dayNumber)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] summary in
                guard let self else { return }
                self.geofence = summary.geofence
                // 위치를 먼저 받아 두었다면 지금 바로 이탈 여부를 판정합니다 (지도 진입 즉시 팝업)
                if let location = self.lastLocation { self.evaluateGeofence(for: location) }
                // 아직 현재 위치가 없으면(권한 대기·시뮬레이터 등) 허용 범위 중심으로 먼저 불러옵니다.
                // 위치를 받으면 그때 다시 불러옵니다.
                if self.currentLocation == nil, self.state == .idle { self.loadSpots() }
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    /// 선택한 카테고리로 주변 스팟을 불러옵니다.
    func loadSpots() {
        guard let center = currentLocation ?? geofenceCenter else { return }
        state = .loading

        // 인기 스팟은 안내사가 정한 목록, 서버 5종은 서버 API(광고 스팟 포함), 나머지는 카카오 로컬 API
        let request: Single<[TravelerNearbySpotDTO]>
        if selectedCategory == .popular {
            request = guideSpots(around: center)
        } else if let code = selectedCategory.kakaoCode {
            request = KakaoLocalService.searchCategory(code, latitude: center.latitude, longitude: center.longitude)
        } else {
            request = repository.fetchNearbySpots(
                category: selectedCategory.rawValue,
                lat: center.latitude,
                lng: center.longitude,
                radius: nil
            )
        }

        request
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] spots in
                guard let self else { return }
                if self.selectedCategory == .popular {
                    // 인기 스팟은 안내사가 정한 순서 그대로
                    self.spots = spots
                } else {
                    // 안내사 설정(광고) 스팟이 1순위, 그다음 거리순입니다.
                    self.spots = spots.sorted { a, b in
                        if (a.isSponsored == true) != (b.isSponsored == true) { return a.isSponsored == true }
                        return (a.distanceM ?? .max) < (b.distanceM ?? .max)
                    }
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

    /// 안내사가 정한 추천 + 인기 스팟 (홈 "주변 인기 스팟"과 같은 목록) — 지도 스팟 모양으로 바꿉니다
    ///
    /// 거리는 서버가 주지 않아 지금 기준점에서 직접 잽니다. 한쪽이 실패해도 다른 쪽은 보여줍니다.
    private func guideSpots(around center: CLLocationCoordinate2D) -> Single<[TravelerNearbySpotDTO]> {
        let here = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return Single.zip(
            repository.fetchRecommendedSpots().catchAndReturn([]),
            repository.fetchPopularSpots().catchAndReturn([])
        )
        .map { recommended, popular in
            var seen = Set<Int>()
            return (recommended + popular)
                .filter { seen.insert($0.id).inserted }
                // 좌표가 없는 스팟(장소 데이터를 찾지 못한 것)은 지도에 핀도 위치도 없어 뺍니다
                .compactMap { spot -> TravelerNearbySpotDTO? in
                    guard let lat = spot.place.latitude.flatMap(Double.init),
                          let lng = spot.place.longitude.flatMap(Double.init) else { return nil }
                    let distance = Int(here.distance(from: CLLocation(latitude: lat, longitude: lng)))
                    return TravelerNearbySpotDTO(
                        providerObjectId: "guide-\(spot.id)",
                        name: spot.title,
                        categoryName: spot.place.categoryName,
                        categoryGroupCode: nil,
                        categoryGroupName: nil,
                        phone: nil,
                        address: spot.place.address,
                        roadAddress: nil,
                        placeUrl: nil,
                        distanceM: distance,
                        lat: FlexibleDouble(lat),
                        lng: FlexibleDouble(lng),
                        isSponsored: spot.isSponsored,
                        imageUrl: spot.imageUrl.isEmpty ? nil : spot.imageUrl,
                        description: spot.description.isEmpty ? nil : spot.description
                    )
                }
        }
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
            // 지도에 들어왔을 때(첫 판정) 이미 밖이면 바로 알립니다.
            // 이후 경계를 오갈 때는 GPS 튐으로 잘못 알리지 않도록 연속 60초로 판정합니다.
            if !hasEvaluatedGeofence {
                isOutsideGeofence = true
            } else if let since = outsideSince {
                if Date().timeIntervalSince(since) >= outsideThreshold { isOutsideGeofence = true }
            } else {
                outsideSince = Date()
            }
        } else {
            // 복귀하면 바로 해제합니다
            outsideSince = nil
            isOutsideGeofence = false
        }
        hasEvaluatedGeofence = true
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

    /// 실패 사유를 서버 문구·상태 코드와 함께 보여줍니다 — "못 불러왔어요"만으로는 원인을 알 수 없습니다
    private static func message(for error: Error) -> String {
        guard let e = error as? HiTripError else { return "정보를 불러오지 못했어요" }
        switch e {
        case .noConnection: return "연결을 확인해주세요"
        case .timeout:      return "서버 응답이 없습니다"
        default:
            let reason = e.errorDescription ?? "정보를 불러오지 못했어요"
            return e.statusCode.map { "\(reason) (\($0))" } ?? reason
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension NearbySpotViewModel: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            let isFirstFix = self.currentLocation == nil
            self.currentLocation = location.coordinate
            self.lastLocation = location
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
