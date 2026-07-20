import Foundation
import RxSwift

// MARK: - Kakao Local API DTOs

struct KakaoLocalPlace: Decodable, Identifiable {
    let id: String
    let placeName: String
    let categoryName: String
    let addressName: String
    let roadAddressName: String
    let x: String   // longitude
    let y: String   // latitude
    let placeUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case placeName        = "place_name"
        case categoryName     = "category_name"
        case addressName      = "address_name"
        case roadAddressName  = "road_address_name"
        case x, y
        case placeUrl         = "place_url"
    }
}

private struct KakaoLocalResponse: Decodable {
    let documents: [KakaoLocalPlace]
}

// MARK: - KakaoLocalAPIService

final class KakaoLocalAPIService {

    private let baseURL = "https://dapi.kakao.com/v2/local/search"
    private var authHeader: String { "KakaoAK \(APIKeys.kakaoRestAPIKey)" }

    /// 카테고리 코드 기반 검색 (편의점·마트·음식점 등)
    func searchByCategory(
        code: String,
        longitude: Double,
        latitude: Double,
        radiusMeters: Int = 1000
    ) -> Single<[KakaoLocalPlace]> {
        request(
            path: "category.json",
            params: [
                "category_group_code": code,
                "x": "\(longitude)",
                "y": "\(latitude)",
                "radius": "\(radiusMeters)",
                "size": "15"
            ]
        )
    }

    /// 키워드 기반 검색 (무장애·반려동물·할랄 등)
    func searchByKeyword(
        keyword: String,
        longitude: Double,
        latitude: Double,
        radiusMeters: Int = 1000
    ) -> Single<[KakaoLocalPlace]> {
        request(
            path: "keyword.json",
            params: [
                "query": keyword,
                "x": "\(longitude)",
                "y": "\(latitude)",
                "radius": "\(radiusMeters)",
                "size": "15"
            ]
        )
    }

    // MARK: - Private

    private func request(path: String, params: [String: String]) -> Single<[KakaoLocalPlace]> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(NSError(domain: "KakaoLocal", code: -1)))
                return Disposables.create()
            }

            var components = URLComponents(string: "\(self.baseURL)/\(path)")!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

            guard let url = components.url else {
                single(.failure(NSError(domain: "KakaoLocal", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
                return Disposables.create()
            }

            var req = URLRequest(url: url)
            req.setValue(self.authHeader, forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: req) { data, _, error in
                if let error = error {
                    single(.failure(error))
                    return
                }
                guard let data = data else {
                    single(.failure(NSError(domain: "KakaoLocal", code: -3)))
                    return
                }
                do {
                    let res = try JSONDecoder().decode(KakaoLocalResponse.self, from: data)
                    single(.success(res.documents))
                } catch {
                    single(.failure(error))
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
}
