import Foundation
import RxSwift

// MARK: - TourAPIService
/// 한국관광공사 TourAPI 전용 네트워크 서비스
///
/// 기존 NetworkService와 다른 점:
/// - baseURL이 TourAPI 전용 (apis.data.go.kr)
/// - 인증 방식이 다름 (Bearer Token이 아닌 serviceKey 쿼리 파라미터)
/// - 응답 구조가 다름 (TourAPI 고유의 JSON 래핑 구조)
///
/// TourAPI 응답 구조:
/// ```json
/// {
///   "response": {
///     "header": { "resultCode": "0000", "resultMsg": "OK" },
///     "body": {
///       "items": { "item": [...] },
///       "totalCount": 100,
///       "pageNo": 1
///     }
///   }
/// }
/// ```

final class TourAPIService {

    // MARK: - Singleton

    static let shared = TourAPIService()

    // MARK: - Properties

    private let baseURL = "https://apis.data.go.kr/B551011/KorService2"
    private let session: URLSession

    private init() {
        self.session = .shared
    }

    /// 테스트용
    init(session: URLSession) {
        self.session = session
    }

    // MARK: - 관광지 검색 (키워드)

    /// 키워드 기반 관광지 검색
    /// - TourAPI: /searchKeyword1
    /// - Parameters:
    ///   - keyword: 검색어 (예: "제주", "서울 궁궐")
    ///   - pageNo: 페이지 번호 (기본 1)
    ///   - numOfRows: 한 페이지 결과 수 (기본 20)
    func searchKeyword(
        keyword: String,
        pageNo: Int = 1,
        numOfRows: Int = 20
    ) -> Single<[TourSpotItem]> {
        let queryItems = [
            URLQueryItem(name: "MobileApp", value: "HiTrip"),
            URLQueryItem(name: "MobileOS", value: "IOS"),
            URLQueryItem(name: "_type", value: "json"),
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "pageNo", value: "\(pageNo)"),
            URLQueryItem(name: "numOfRows", value: "\(numOfRows)"),
            URLQueryItem(name: "arrange", value: "A"),  // A: 제목순
        ]

        return request(path: "/searchKeyword2", queryItems: queryItems)
    }

    // MARK: - 지역 기반 관광지 조회

    /// 위치 기반 주변 관광지 조회
    /// - TourAPI: /locationBasedList1
    /// - Parameters:
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - radius: 반경 (미터, 기본 5000m = 5km)
    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int = 5000,
        pageNo: Int = 1,
        numOfRows: Int = 20
    ) -> Single<[TourSpotItem]> {
        let queryItems = [
            URLQueryItem(name: "MobileApp", value: "HiTrip"),
            URLQueryItem(name: "MobileOS", value: "IOS"),
            URLQueryItem(name: "_type", value: "json"),
            URLQueryItem(name: "mapX", value: "\(longitude)"),
            URLQueryItem(name: "mapY", value: "\(latitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "pageNo", value: "\(pageNo)"),
            URLQueryItem(name: "numOfRows", value: "\(numOfRows)"),
            URLQueryItem(name: "arrange", value: "E"),  // E: 거리순
        ]

        return request(path: "/locationBasedList2", queryItems: queryItems)
    }

    // MARK: - 공통 요청 메서드

    /// TourAPI 공통 GET 요청
    ///
    /// ⚠️ serviceKey 인코딩 이슈:
    /// URLComponents.queryItems는 값을 자동 percent-encoding 합니다.
    /// TourAPI의 serviceKey에 포함된 특수문자(=, + 등)가 이중 인코딩되면
    /// 서버가 키를 인식하지 못해 HTTP 500 에러가 발생합니다.
    ///
    /// 해결: serviceKey는 queryItems에 넣지 않고,
    /// 완성된 URL 문자열에 직접 붙여서 인코딩을 우회합니다.
    private func request(
        path: String,
        queryItems: [URLQueryItem]
    ) -> Single<[TourSpotItem]> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(NetworkError.invalidURL))
                return Disposables.create()
            }

            // 1) serviceKey 제외한 나머지 파라미터로 URL 조합
            var components = URLComponents(string: self.baseURL + path)
            components?.queryItems = queryItems

            guard var urlString = components?.url?.absoluteString else {
                single(.failure(NetworkError.invalidURL))
                return Disposables.create()
            }

            // 2) serviceKey를 인코딩 없이 직접 붙임
            let separator = urlString.contains("?") ? "&" : "?"
            urlString += "\(separator)serviceKey=\(APIKeys.tourAPIKey)"

            guard let url = URL(string: urlString) else {
                single(.failure(NetworkError.invalidURL))
                return Disposables.create()
            }

            // 🔍 DEBUG: 실제 요청 URL 출력
            print("🌐 [TourAPI] 요청 URL: \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let task = self.session.dataTask(with: request) { data, response, error in
                // 네트워크 에러
                if let error {
                    print("❌ [TourAPI] 네트워크 에러: \(error.localizedDescription)")
                    single(.failure(NetworkError.requestFailed(error.localizedDescription)))
                    return
                }

                // HTTP 응답 확인
                guard let httpResponse = response as? HTTPURLResponse else {
                    single(.failure(NetworkError.invalidResponse))
                    return
                }

                print("📡 [TourAPI] HTTP 상태코드: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    // 🔍 DEBUG: 에러 응답 본문 출력
                    if let data, let body = String(data: data, encoding: .utf8) {
                        print("❌ [TourAPI] 에러 응답 본문: \(body)")
                    }
                    single(.failure(NetworkError.httpError(httpResponse.statusCode)))
                    return
                }

                guard let data else {
                    single(.failure(NetworkError.noData))
                    return
                }

                // TourAPI JSON 파싱
                do {
                    let tourResponse = try JSONDecoder().decode(
                        TourAPIResponse.self,
                        from: data
                    )
                    let items = tourResponse.response.body.items.item ?? []
                    single(.success(items))
                } catch {
                    single(.failure(NetworkError.decodingFailed(error.localizedDescription)))
                }
            }

            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
}

// MARK: - TourAPI 응답 모델

/// TourAPI의 고유한 JSON 래핑 구조를 파싱하기 위한 모델
///
/// 실제 데이터(item 배열)까지 3단계를 거쳐야 함:
/// response → body → items → item

struct TourAPIResponse: Decodable {
    let response: TourResponseBody
}

struct TourResponseBody: Decodable {
    let header: TourHeader
    let body: TourBody
}

struct TourHeader: Decodable {
    let resultCode: String
    let resultMsg: String
}

struct TourBody: Decodable {
    let items: TourItems
    let totalCount: Int
    let pageNo: Int
    let numOfRows: Int
}

struct TourItems: Decodable {
    let item: [TourSpotItem]?
}

// MARK: - TourSpotItem
/// TourAPI에서 반환하는 관광지 개별 항목
///
/// 주요 필드:
/// - contentid: 관광지 고유 ID
/// - title: 관광지 이름
/// - addr1: 주소
/// - mapx/mapy: 경도/위도 (KakaoMap에 마커 표시용)
/// - firstimage: 대표 이미지 URL
/// - tel: 전화번호
/// - contenttypeid: 관광지 유형 (12: 관광지, 14: 문화시설, 15: 축제, 25: 여행코스, 28: 레포츠, 32: 숙박, 38: 쇼핑, 39: 음식점)

struct TourSpotItem: Decodable, Identifiable, Equatable {
    let contentid: String
    let title: String
    let addr1: String?
    let addr2: String?
    let mapx: String?       // 경도 (longitude)
    let mapy: String?       // 위도 (latitude)
    let firstimage: String?
    let firstimage2: String?
    let tel: String?
    let contenttypeid: String?

    /// Identifiable 준수
    var id: String { contentid }

    /// 전체 주소
    var fullAddress: String {
        [addr1, addr2].compactMap { $0 }.joined(separator: " ")
    }

    /// 경도 (Double 변환)
    var longitude: Double? {
        guard let mapx else { return nil }
        return Double(mapx)
    }

    /// 위도 (Double 변환)
    var latitude: Double? {
        guard let mapy else { return nil }
        return Double(mapy)
    }

    /// 관광지 유형 이름
    var contentTypeName: String {
        switch contenttypeid {
        case "12": return "관광지"
        case "14": return "문화시설"
        case "15": return "축제/행사"
        case "25": return "여행코스"
        case "28": return "레포츠"
        case "32": return "숙박"
        case "38": return "쇼핑"
        case "39": return "음식점"
        default:   return "기타"
        }
    }
}
