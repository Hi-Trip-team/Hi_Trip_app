import Foundation
import CoreLocation
import RxSwift

// MARK: - WeatherService
/// 기상청 단기예보 API — 초단기예보(getUltraSrtFcst)
///
/// 서버가 날씨를 내려주지 않아 앱에서 직접 호출합니다.
/// 발급: https://www.data.go.kr → "기상청_단기예보 ((구)_동네예보) 조회서비스" 활용신청
/// 키는 APIKeys.kmaServiceKey (gitignore 대상 파일)
///
/// 좌표는 목적지 이름을 CLGeocoder로 변환한 뒤 기상청 격자(nx, ny)로 바꿉니다.

struct WeatherSnapshot: Equatable {
    /// "맑음", "흐림" 등
    let condition: String
    /// 섭씨
    let temperature: Int

    /// "맑음 22°C"
    var text: String { "\(condition) \(temperature)°C" }
}

enum WeatherError: Error {
    case noKey
    case placeNotFound
    case badResponse(String)
}

final class WeatherService {

    static let shared = WeatherService()

    private let session: URLSession
    private let geocoder = CLGeocoder()

    /// 같은 지역을 반복 호출하지 않도록 10분간 캐시
    private var cache: [String: (snapshot: WeatherSnapshot, at: Date)] = [:]
    private let cacheTTL: TimeInterval = 600

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - 조회

    /// 지역 이름(예: "제주")으로 현재 날씨를 가져옵니다.
    func fetch(placeName: String) -> Single<WeatherSnapshot> {
        if let hit = cache[placeName], Date().timeIntervalSince(hit.at) < cacheTTL {
            return .just(hit.snapshot)
        }

        return coordinate(of: placeName)
            .flatMap { [weak self] coord -> Single<WeatherSnapshot> in
                guard let self else { return .error(WeatherError.placeNotFound) }
                return self.fetch(coordinate: coord)
            }
            .do(onSuccess: { [weak self] snapshot in
                self?.cache[placeName] = (snapshot, Date())
            })
    }

    func fetch(coordinate: CLLocationCoordinate2D) -> Single<WeatherSnapshot> {
        guard !APIKeys.kmaServiceKey.isEmpty else { return .error(WeatherError.noKey) }

        let grid = Self.grid(lat: coordinate.latitude, lon: coordinate.longitude)
        let base = Self.baseDateTime()

        var comps = URLComponents(string: "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtFcst")!
        comps.queryItems = [
            URLQueryItem(name: "pageNo", value: "1"),
            URLQueryItem(name: "numOfRows", value: "60"),
            URLQueryItem(name: "dataType", value: "JSON"),
            URLQueryItem(name: "base_date", value: base.date),
            URLQueryItem(name: "base_time", value: base.time),
            URLQueryItem(name: "nx", value: String(grid.nx)),
            URLQueryItem(name: "ny", value: String(grid.ny)),
        ]
        // serviceKey는 이미 인코딩된 값이라 percentEncodedQuery에 직접 붙입니다.
        // URLQueryItem으로 넣으면 '+', '=' 가 다시 인코딩돼 인증에 실패합니다.
        comps.percentEncodedQuery = "serviceKey=\(APIKeys.kmaServiceKey)&" + (comps.percentEncodedQuery ?? "")

        guard let url = comps.url else { return .error(WeatherError.badResponse("URL 생성 실패")) }

        return Single.create { single in
            let task = self.session.dataTask(with: url) { data, _, error in
                if let error { single(.failure(error)); return }
                guard let data else {
                    single(.failure(WeatherError.badResponse("빈 응답")))
                    return
                }
                do {
                    single(.success(try Self.parse(data)))
                } catch {
                    single(.failure(error))
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }

    // MARK: - 파싱

    private struct Response: Decodable {
        struct Body: Decodable { let items: Items }
        struct Items: Decodable { let item: [Item] }
        struct Item: Decodable {
            let category: String
            let fcstTime: String
            let fcstValue: String
        }
        struct Header: Decodable { let resultCode: String; let resultMsg: String }
        struct Wrapper: Decodable { let header: Header; let body: Body? }
        let response: Wrapper
    }

    private static func parse(_ data: Data) throws -> WeatherSnapshot {
        guard let decoded = try? JSONDecoder().decode(Response.self, from: data) else {
            // 인증 실패 등은 JSON 구조 자체가 달라서 원문을 그대로 올립니다.
            let raw = String(data: data, encoding: .utf8) ?? "알 수 없는 응답"
            throw WeatherError.badResponse(String(raw.prefix(200)))
        }
        guard decoded.response.header.resultCode == "00",
              let items = decoded.response.body?.items.item, !items.isEmpty else {
            throw WeatherError.badResponse(decoded.response.header.resultMsg)
        }

        // 가장 이른 예보 시각의 값만 사용합니다 = 지금에 가장 가까운 예보
        let firstTime = items.map(\.fcstTime).min() ?? ""
        let now = items.filter { $0.fcstTime == firstTime }

        let temp = now.first { $0.category == "T1H" }.flatMap { Int(Double($0.fcstValue) ?? 0) }
        let sky  = now.first { $0.category == "SKY" }?.fcstValue
        let pty  = now.first { $0.category == "PTY" }?.fcstValue

        guard let temp else { throw WeatherError.badResponse("기온 없음") }
        return WeatherSnapshot(condition: condition(sky: sky, pty: pty), temperature: temp)
    }

    /// 강수형태(PTY)가 있으면 그쪽이 우선입니다. 없을 때만 하늘상태(SKY)를 씁니다.
    private static func condition(sky: String?, pty: String?) -> String {
        switch pty {
        case "1": return "비"
        case "2": return "비/눈"
        case "3": return "눈"
        case "4": return "소나기"
        default: break
        }
        switch sky {
        case "1": return "맑음"
        case "3": return "구름많음"
        case "4": return "흐림"
        default:  return "―"
        }
    }

    // MARK: - 좌표

    private func coordinate(of placeName: String) -> Single<CLLocationCoordinate2D> {
        Single.create { single in
            self.geocoder.geocodeAddressString(placeName) { marks, error in
                if let coord = marks?.first?.location?.coordinate {
                    single(.success(coord))
                } else {
                    single(.failure(error ?? WeatherError.placeNotFound))
                }
            }
            return Disposables.create()
        }
    }

    /// 위경도 → 기상청 격자 (Lambert Conformal Conic, 기상청 dfs_xy_conv와 동일)
    static func grid(lat: Double, lon: Double) -> (nx: Int, ny: Int) {
        let RE = 6371.00877, GRID = 5.0
        let SLAT1 = 30.0, SLAT2 = 60.0, OLON = 126.0, OLAT = 38.0
        let XO = 43.0, YO = 136.0
        let DEGRAD = Double.pi / 180.0

        let re = RE / GRID
        let slat1 = SLAT1 * DEGRAD, slat2 = SLAT2 * DEGRAD
        let olon = OLON * DEGRAD, olat = OLAT * DEGRAD

        var sn = tan(.pi * 0.25 + slat2 * 0.5) / tan(.pi * 0.25 + slat1 * 0.5)
        sn = log(cos(slat1) / cos(slat2)) / log(sn)
        var sf = tan(.pi * 0.25 + slat1 * 0.5)
        sf = pow(sf, sn) * cos(slat1) / sn
        var ro = tan(.pi * 0.25 + olat * 0.5)
        ro = re * sf / pow(ro, sn)

        var ra = tan(.pi * 0.25 + lat * DEGRAD * 0.5)
        ra = re * sf / pow(ra, sn)
        var theta = lon * DEGRAD - olon
        if theta > .pi  { theta -= 2 * .pi }
        if theta < -.pi { theta += 2 * .pi }
        theta *= sn

        return (Int(ra * sin(theta) + XO + 0.5), Int(ro - ra * cos(theta) + YO + 0.5))
    }

    /// 초단기예보 발표 시각 — 매시 30분 발표, 약 15분 뒤 조회 가능
    static func baseDateTime(now: Date = Date()) -> (date: String, time: String) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

        // 발표 45분 뒤를 기준으로 삼아 아직 안 올라온 회차를 피합니다.
        let target = now.addingTimeInterval(-45 * 60)
        let hour = cal.component(.hour, from: target)
        let base = cal.date(bySettingHour: hour, minute: 30, second: 0, of: target) ?? target

        let df = DateFormatter()
        df.timeZone = cal.timeZone
        df.dateFormat = "yyyyMMdd"
        let dateStr = df.string(from: base)
        df.dateFormat = "HHmm"
        return (dateStr, df.string(from: base))
    }
}
