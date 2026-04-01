import Foundation
import RxSwift

// MARK: - SpotRepository
/// 관광지 저장소 구현체 (TourAPI 연동)
///
/// 이전 Repository들과 다른 점:
/// - 메모리 저장이 아닌 **실제 외부 API 호출**
/// - TourAPIService를 통해 한국관광공사 서버에서 데이터를 가져옴
///
/// 이것이 Clean Architecture + DIP의 실전 적용:
/// - Schedule/Chat: 메모리 저장 → 나중에 서버로 교체
/// - Spot: 처음부터 실제 API 호출
/// - UseCase는 둘 다 동일한 방식으로 사용 (Protocol만 알면 됨)

final class SpotRepository: SpotRepositoryProtocol {

    // MARK: - Dependencies

    private let tourAPIService: TourAPIService

    init(tourAPIService: TourAPIService = .shared) {
        self.tourAPIService = tourAPIService
    }

    // MARK: - 키워드 검색

    /// TourAPIService.searchKeyword 호출
    func searchByKeyword(keyword: String, pageNo: Int) -> Single<[TourSpotItem]> {
        return tourAPIService.searchKeyword(keyword: keyword, pageNo: pageNo)
    }

    // MARK: - 위치 기반 검색

    /// TourAPIService.searchNearby 호출
    func searchNearby(latitude: Double, longitude: Double, pageNo: Int) -> Single<[TourSpotItem]> {
        return tourAPIService.searchNearby(
            latitude: latitude,
            longitude: longitude,
            pageNo: pageNo
        )
    }
}
