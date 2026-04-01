import Foundation
import RxSwift

// MARK: - SpotUseCase
/// 관광지 검색 비즈니스 로직
///
/// 이전 UseCase들과 다른 점:
/// - CRUD가 아닌 검색 전용
/// - 검증: 빈 키워드 방지, 좌표 유효성 확인
///
/// 동일한 패턴: Protocol에만 의존 (DIP)

final class SpotUseCase {

    private let repository: SpotRepositoryProtocol

    init(repository: SpotRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 키워드 검색

    /// 키워드로 관광지 검색
    ///
    /// 검증: 키워드가 비어있으면 에러
    func searchByKeyword(keyword: String, pageNo: Int = 1) -> Single<[TourSpotItem]> {
        guard !keyword.trimmed.isEmpty else {
            return .error(SpotError.emptyKeyword)
        }

        return repository.searchByKeyword(keyword: keyword, pageNo: pageNo)
    }

    // MARK: - 위치 기반 검색

    /// 현재 위치 주변 관광지 검색
    ///
    /// 검증: 좌표가 한국 범위 내인지 대략적 확인
    func searchNearby(
        latitude: Double,
        longitude: Double,
        pageNo: Int = 1
    ) -> Single<[TourSpotItem]> {
        // 한국 좌표 범위 대략적 검증 (위도 33~39, 경도 124~132)
        guard (33...39).contains(latitude),
              (124...132).contains(longitude) else {
            return .error(SpotError.invalidLocation)
        }

        return repository.searchNearby(
            latitude: latitude,
            longitude: longitude,
            pageNo: pageNo
        )
    }
}

// MARK: - SpotError
/// 관광지 검색 관련 에러
enum SpotError: LocalizedError, Equatable {
    case emptyKeyword
    case invalidLocation
    case noResults
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyKeyword:
            return "검색어를 입력해주세요."
        case .invalidLocation:
            return "현재 위치를 확인할 수 없습니다."
        case .noResults:
            return "검색 결과가 없습니다."
        case .serverError(let msg):
            return msg
        }
    }
}
