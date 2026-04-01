import Foundation
import RxSwift

// MARK: - SpotRepositoryProtocol
/// 관광지 데이터 접근 인터페이스 (Domain 레이어)
///
/// 이전 Repository들과 다른 점:
/// - CRUD가 아닌 **검색(Read only)** 위주
/// - 사용자가 데이터를 생성/수정/삭제하지 않고, TourAPI에서 조회만 함
///
/// 동일한 DIP 패턴:
/// - Domain은 Protocol만 알고, 구현체(TourAPI 호출)는 모름

protocol SpotRepositoryProtocol {

    /// 키워드 기반 관광지 검색
    /// - Parameter keyword: 검색어
    func searchByKeyword(keyword: String, pageNo: Int) -> Single<[TourSpotItem]>

    /// 위치 기반 주변 관광지 검색
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    func searchNearby(latitude: Double, longitude: Double, pageNo: Int) -> Single<[TourSpotItem]>
}
