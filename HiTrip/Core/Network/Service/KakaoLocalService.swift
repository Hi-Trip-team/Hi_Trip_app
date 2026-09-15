import Foundation
import RxSwift

// MARK: - KakaoLocalService
/// 카카오 로컬 API — 카테고리로 주변 장소 검색
///
/// 서버 주변 스팟 API는 카테고리 5종(음식점·무장애·반려동물·편의점·마트)만 받습니다.
/// 그 밖의 카테고리(카페·관광명소·약국 등)는 카카오 로컬 API를 직접 부릅니다.
///
/// - GET https://dapi.kakao.com/v2/local/search/category.json
/// - 인증: `Authorization: KakaoAK {REST API 키}` (APIKeys.kakaoRestAPIKey, 커밋 제외 파일)
/// - 카카오 로컬 API는 장소 사진을 주지 않습니다. 사진은 카카오맵 장소 페이지(place_url)에서 봅니다.
///
/// 결과는 서버 스팟과 같은 `TravelerNearbySpotDTO`로 바꿔 화면이 출처를 신경 쓰지 않게 합니다.

enum KakaoLocalService {

    /// 카카오 카테고리 그룹 코드 — 서버 5종에 없는 것만 씁니다
    enum CategoryCode: String {
        case cafe          = "CE7"
        case attraction    = "AT4"
        case culture       = "CT1"
        case pharmacy      = "PM9"
        case hospital      = "HP8"
        case subway        = "SW8"
        case accommodation = "AD5"
    }

    /// 주변 장소 검색 — 거리순, 최대 15개
    /// - Parameter radius: 미터 (카카오 최대 20,000)
    static func searchCategory(
        _ code: CategoryCode,
        latitude: Double,
        longitude: Double,
        radius: Int = 2_000
    ) -> Single<[TravelerNearbySpotDTO]> {
        var components = URLComponents(string: "https://dapi.kakao.com/v2/local/search/category.json")
        components?.queryItems = [
            URLQueryItem(name: "category_group_code", value: code.rawValue),
            URLQueryItem(name: "x", value: String(longitude)),
            URLQueryItem(name: "y", value: String(latitude)),
            URLQueryItem(name: "radius", value: String(min(radius, 20_000))),
            URLQueryItem(name: "sort", value: "distance"),
        ]
        guard let url = components?.url, !APIKeys.kakaoRestAPIKey.isEmpty else {
            return .error(HiTripError.networkFailure("카카오 장소 검색을 쓸 수 없어요"))
        }

        var request = URLRequest(url: url)
        request.setValue("KakaoAK \(APIKeys.kakaoRestAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        return Single.create { single in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error { single(.failure(error)); return }
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard (200..<300).contains(code), let data else {
                    single(.failure(HiTripError.networkFailure("카카오 장소 검색에 실패했어요 (\(code))")))
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let result = try decoder.decode(CategorySearchResponse.self, from: data)
                    single(.success(result.documents.map(\.spot)))
                } catch {
                    single(.failure(error))
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }

    // MARK: - 응답

    private struct CategorySearchResponse: Decodable {
        let documents: [Document]
    }

    /// 카카오 장소 문서 — 좌표(x·y)와 거리는 문자열로 옵니다
    private struct Document: Decodable {
        let id: String
        let placeName: String
        let categoryName: String?
        let categoryGroupCode: String?
        let categoryGroupName: String?
        let phone: String?
        let addressName: String?
        let roadAddressName: String?
        let x: String
        let y: String
        let placeUrl: String?
        let distance: String?

        var spot: TravelerNearbySpotDTO {
            TravelerNearbySpotDTO(
                providerObjectId: id,
                name: placeName,
                categoryName: categoryName,
                categoryGroupCode: categoryGroupCode,
                categoryGroupName: categoryGroupName,
                phone: phone?.isEmpty == false ? phone : nil,
                address: addressName,
                roadAddress: roadAddressName?.isEmpty == false ? roadAddressName : nil,
                placeUrl: placeUrl,
                distanceM: distance.flatMap(Int.init),
                lat: Double(y).map(FlexibleDouble.init),
                lng: Double(x).map(FlexibleDouble.init),
                isSponsored: false,
                imageUrl: nil,
                description: nil
            )
        }
    }
}
