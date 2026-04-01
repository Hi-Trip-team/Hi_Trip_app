import Foundation
import RxSwift
import CoreLocation

// MARK: - SpotViewModel
/// 관광지 검색 화면의 ViewModel
///
/// 이전 ViewModel들과 다른 점:
/// - CRUD가 아닌 검색 전용
/// - CLLocationManager로 현재 위치 가져오기
/// - 페이지네이션 (더보기 기능)
///
/// 동일한 @Published 패턴

final class SpotViewModel: NSObject, ObservableObject {

    // MARK: - 검색 상태

    /// 검색 결과 목록
    @Published var spots: [TourSpotItem] = []

    /// 검색어 입력 — TextField와 바인딩
    @Published var searchText: String = ""

    /// 검색 모드 (키워드 / 주변)
    @Published var searchMode: SearchMode = .keyword

    // MARK: - UI 상태

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// 더 불러올 데이터가 있는지
    @Published var hasMore: Bool = false

    // MARK: - 위치 상태

    /// 현재 위치
    @Published var currentLocation: CLLocation?

    /// 위치 권한 상태
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Dependencies

    private let spotUseCase: SpotUseCase
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()

    /// 현재 페이지 번호
    private var currentPage: Int = 1

    init(spotUseCase: SpotUseCase) {
        self.spotUseCase = spotUseCase
        super.init()
        setupLocationManager()
    }

    // MARK: - 검색 모드

    enum SearchMode: String, CaseIterable {
        case keyword = "키워드 검색"
        case nearby = "주변 검색"
    }

    // MARK: - 키워드 검색

    /// 키워드로 관광지 검색
    /// 새 검색 시 기존 결과 초기화
    func searchByKeyword() {
        currentPage = 1
        spots = []
        isLoading = true
        errorMessage = nil

        spotUseCase.searchByKeyword(keyword: searchText, pageNo: currentPage)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] items in
                    self?.isLoading = false
                    self?.spots = items
                    self?.hasMore = items.count >= 20
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    /// 다음 페이지 로드 (키워드)
    func loadMoreKeyword() {
        guard !isLoading, hasMore else { return }

        currentPage += 1
        isLoading = true

        spotUseCase.searchByKeyword(keyword: searchText, pageNo: currentPage)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] items in
                    self?.isLoading = false
                    self?.spots.append(contentsOf: items)
                    self?.hasMore = items.count >= 20
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 주변 검색

    /// 현재 위치 기반 주변 관광지 검색
    func searchNearby() {
        guard let location = currentLocation else {
            errorMessage = "위치 정보를 가져오는 중입니다..."
            requestLocation()
            return
        }

        currentPage = 1
        spots = []
        isLoading = true
        errorMessage = nil

        spotUseCase.searchNearby(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            pageNo: currentPage
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] items in
                self?.isLoading = false
                self?.spots = items
                self?.hasMore = items.count >= 20
            },
            onFailure: { [weak self] error in
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
            }
        )
        .disposed(by: disposeBag)
    }

    // MARK: - 위치 관리

    /// CLLocationManager 초기 설정
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// 위치 권한 요청
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate
/// 위치 업데이트 콜백
///
/// NSObject 상속 + CLLocationManagerDelegate 채택이 필요
/// → SpotViewModel이 class이고 NSObject를 상속하는 이유

extension SpotViewModel: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "위치를 가져올 수 없습니다: \(error.localizedDescription)"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
}
