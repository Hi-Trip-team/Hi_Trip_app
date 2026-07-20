import Foundation
import Combine
import CoreLocation
import RxSwift

// MARK: - MapViewModel

final class MapViewModel: NSObject, ObservableObject {

    // MARK: - Map State

    /// 지도 중심 좌표 (트립 목적지 기준 초기화, GPS 이동 시 변경)
    @Published var mapCenter: CLLocationCoordinate2D
    /// 실제 기기 위치
    @Published var currentLocation: CLLocationCoordinate2D?
    /// KakaoMapView draw 바인딩
    @Published var drawMap = false

    // MARK: - Places

    /// 서버 공식 스팟 (안내사 등록)
    @Published var officialSpots: [MapPlaceItem] = []
    /// 카테고리/키워드 검색 결과
    @Published var searchResults: [MapPlaceItem] = []
    /// 카드 탭 → 상세 Sheet 표시용
    @Published var selectedPlace: MapPlaceItem?

    // MARK: - Category

    @Published var selectedCategory: MapCategory?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Camera Signal

    /// GPS 버튼 탭 시 값이 바뀌어 KakaoMapView가 카메라를 이동시킴
    @Published var cameraTarget: CameraTarget?
    /// 줌 인/아웃 신호
    @Published var zoomTrigger: ZoomTrigger?

    struct CameraTarget: Equatable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        static func == (l: CameraTarget, r: CameraTarget) -> Bool { l.id == r.id }
    }

    struct ZoomTrigger: Equatable {
        let id = UUID()
        let delta: Int  // +1 = 줌인, -1 = 줌아웃
        static func == (l: ZoomTrigger, r: ZoomTrigger) -> Bool { l.id == r.id }
    }

    // MARK: - Radius (Mock: 1km)

    let allowedRadiusMeters: Double = 1000

    // MARK: - Dependencies

    private let store = TripDataStore.shared
    private let localAPI = KakaoLocalAPIService()
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    override init() {
        // 트립 목적지 좌표가 없으면 서울 시청 기본값
        mapCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        super.init()
        setupLocation()
        loadOfficialSpots()
        observeStore()
    }

    // MARK: - Official Spots

    private func observeStore() {
        store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.loadOfficialSpots() }
            .store(in: &cancellables)
    }

    private func loadOfficialSpots() {
        // TravelerRepository.fetchMapPlaces() 결과를 Store에 추가하면 여기서 읽음
        // 현재는 Mock: TripDataStore의 officialSchedules 위치를 활용
        // 실 서버 연동 시: store.mapPlaces.map { $0.toMapPlaceItem() }
        officialSpots = []
    }

    // MARK: - Category Search

    func selectCategory(_ category: MapCategory) {
        if selectedCategory == category {
            selectedCategory = nil
            searchResults = []
            return
        }

        selectedCategory = category
        searchResults = []
        errorMessage = nil

        let center = currentLocation ?? mapCenter
        isLoading = true

        let search: Single<[KakaoLocalPlace]>

        if let code = category.kakaoCode {
            search = localAPI.searchByCategory(
                code: code,
                longitude: center.longitude,
                latitude: center.latitude,
                radiusMeters: Int(allowedRadiusMeters)
            )
        } else if let keyword = category.keyword {
            search = localAPI.searchByKeyword(
                keyword: keyword,
                longitude: center.longitude,
                latitude: center.latitude,
                radiusMeters: Int(allowedRadiusMeters)
            )
        } else {
            isLoading = false
            return
        }

        search
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] places in
                    self?.isLoading = false
                    self?.searchResults = places.map { $0.toMapPlaceItem() }
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = "검색에 실패했습니다."
                    print("⚠️ [MapViewModel] 카테고리 검색 실패: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Display Places

    /// 카드 스크롤 + 마커에 표시할 전체 장소
    /// 공식 스팟 우선 → 검색 결과
    var displayPlaces: [MapPlaceItem] {
        officialSpots + searchResults
    }

    // MARK: - GPS

    func moveToCurrentLocation() {
        locationManager.requestLocation()
        if let loc = currentLocation {
            cameraTarget = CameraTarget(coordinate: loc)
        }
    }

    func zoomIn()  { zoomTrigger = ZoomTrigger(delta: +1) }
    func zoomOut() { zoomTrigger = ZoomTrigger(delta: -1) }

    // MARK: - Location Setup

    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewModel: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentLocation = loc.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ [MapViewModel] 위치 오류: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }
}
