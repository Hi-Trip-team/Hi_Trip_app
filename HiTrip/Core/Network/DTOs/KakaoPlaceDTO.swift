import Foundation

// MARK: - 카카오 장소 (안내사 일정 장소 지정)
/// GET  /api/v1/publicdata/kakao/places/?q=      카카오 장소 검색 (서버 프록시)
/// POST /api/v1/publicdata/kakao/places/adopt/   고른 장소를 서버 장소로 등록 → place_id
///
/// 서버 일정은 장소를 place_id로만 받아서, 검색 결과를 먼저 adopt 해야 합니다.
/// SaaS 사이트의 장소 지정과 같은 흐름입니다.

struct KakaoPlaceSearchResponseDTO: Decodable {
    let results: [KakaoPlaceResultDTO]
}

struct KakaoPlaceResultDTO: Decodable, Equatable, Identifiable {
    let providerObjectId: String
    let placeName: String
    let categoryName: String?
    let addressName: String?
    let roadAddressName: String?

    var id: String { providerObjectId }

    /// 도로명 주소 우선, 없으면 지번
    var addressText: String {
        if let road = roadAddressName, !road.isEmpty { return road }
        return addressName ?? ""
    }
}

struct KakaoPlaceAdoptResponseDTO: Decodable {
    let placeId: Int
    let name: String?
}
