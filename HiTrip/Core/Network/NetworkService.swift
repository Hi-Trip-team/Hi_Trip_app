import Foundation
import RxSwift

// MARK: - NetworkService
/// URLSession 기반 네트워크 서비스
///
/// 설계 의도:
/// - Moya/Alamofire 없이 URLSession을 직접 래핑하여 네트워크 통신 구현
/// - RxSwift Single과 async/await 두 가지 인터페이스 제공
/// - 테스트 시 URLSession을 교체할 수 있도록 생성자 주입 지원
///
/// 면접 포인트:
/// "왜 Moya를 안 쓰셨나요?"
/// → "URLSession의 동작 원리(Request 빌드, Response 파싱, 에러 핸들링)를
///    직접 구현하여 네트워크 레이어의 기본기를 이해하고자 했습니다."

final class NetworkService {

    // MARK: - Singleton (프로덕션용)

    static let shared = NetworkService()

    // MARK: - Properties

    private let baseURL: String
    private let session: URLSession

    // MARK: - Init

    /// 프로덕션 전용 싱글턴 초기화
    /// - private으로 외부에서 직접 생성 방지
    private init() {
        self.baseURL = APIEnvironment.current.baseURL
        self.session = .shared
    }

    /// 테스트용 초기화 — Mock URLSession 주입 가능
    /// - Parameters:
    ///   - baseURL: 테스트 서버 URL
    ///   - session: URLProtocol을 등록한 테스트용 URLSession
    init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - RxSwift 요청 (메인 API)

    /// Single<T>로 API 호출 결과를 반환
    ///
    /// 동작 흐름:
    /// 1. APIEndpoint → URLRequest 변환
    /// 2. URLSession.dataTask 실행
    /// 3. HTTP 상태코드 검증 (200~299)
    /// 4. JSON → T 디코딩
    /// 5. Single.success 또는 Single.failure 반환
    ///
    /// - Parameters:
    ///   - endpoint: 요청할 API 엔드포인트
    ///   - type: 디코딩할 응답 타입
    /// - Returns: 디코딩된 응답을 담은 Single
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        type: T.Type
    ) -> Single<T> {
        return Single.create { [weak self] single in
            guard let self,
                  let request = self.buildRequest(endpoint) else {
                print("❌ [Network] URL 생성 실패 | path: \(endpoint.path)")
                single(.failure(HiTripError.invalidURL))
                return Disposables.create()
            }

            // 디버그: 모든 API 요청 로깅
            let method = endpoint.method.rawValue
            let url = request.url?.absoluteString ?? ""
            print("🌐 [Network] \(method) \(url)")
            if let body = endpoint.body {
                print("   📦 Body: \(body)")
            }

            let task = self.session.dataTask(with: request) { data, response, error in
                // 1) 네트워크 에러 (인터넷 끊김, 타임아웃 등)
                if let error {
                    let hiTripError = HiTripError.from(urlError: error)
                    print("❌ [Network] \(hiTripError.debugDescription) | \(url)")
                    single(.failure(hiTripError))
                    return
                }

                // 2) HTTPURLResponse 캐스팅 확인
                guard let httpResponse = response as? HTTPURLResponse else {
                    single(.failure(HiTripError.invalidResponse))
                    return
                }

                // 3) HTTP 상태코드 검증 — 서버 에러 body를 파싱하여 구체적인 에러 생성
                guard (200...299).contains(httpResponse.statusCode) else {
                    let hiTripError = HiTripError.from(statusCode: httpResponse.statusCode, data: data)
                    print("❌ [Network] \(hiTripError.debugDescription) | URL: \(url)")

                    // 401 토큰 만료 시 자동 로그아웃 알림 (NotificationCenter)
                    if hiTripError.requiresReauth {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: .hiTripTokenExpired,
                                object: nil,
                                userInfo: ["error": hiTripError]
                            )
                        }
                    }

                    single(.failure(hiTripError))
                    return
                }

                // 4) 데이터 존재 확인
                guard let data else {
                    single(.failure(HiTripError.noData))
                    return
                }

                // 디버그: 성공 응답 본문 출력
                if let body = String(data: data, encoding: .utf8) {
                    print("✅ [Network] HTTP \(httpResponse.statusCode) | URL: \(url) | Body: \(body.prefix(500))")
                }

                // 5) JSON 디코딩
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .custom(NetworkService.flexibleDateDecoder)
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decoded = try decoder.decode(T.self, from: data)
                    single(.success(decoded))
                } catch {
                    print("❌ [Network] 디코딩 실패 | Type: \(T.self) | Error: \(error)")
                    single(.failure(HiTripError.decodingFailed(error.localizedDescription)))
                }
            }

            task.resume()

            // Disposable: 구독 해제 시 네트워크 요청 취소
            return Disposables.create { task.cancel() }
        }
    }

    // MARK: - async/await 요청 (Swift Concurrency)

    /// async/await 방식의 API 호출
    /// - RxSwift와 병행하여 Swift Concurrency도 지원
    /// - 향후 Combine이나 순수 async 코드에서 활용 가능
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        type: T.Type
    ) async throws -> T {
        guard let request = buildRequest(endpoint) else {
            throw HiTripError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw HiTripError.from(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HiTripError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let hiTripError = HiTripError.from(statusCode: httpResponse.statusCode, data: data)
            if hiTripError.requiresReauth {
                await MainActor.run {
                    NotificationCenter.default.post(name: .hiTripTokenExpired, object: nil)
                }
            }
            throw hiTripError
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom(NetworkService.flexibleDateDecoder)
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HiTripError.decodingFailed(error.localizedDescription)
        }
    }

    // MARK: - Date Decoder

    /// 백엔드에서 오는 다양한 날짜 포맷을 유연하게 파싱
    /// - ISO 8601 datetime: "2025-03-08T02:46:56.037Z"
    /// - Date only: "2025-03-08"
    static func flexibleDateDecoder(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        // ISO 8601 with fractional seconds
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // ISO 8601 without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Date only (yyyy-MM-dd)
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        if let date = dateOnly.date(from: dateString) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot decode date: \(dateString)"
        )
    }

    // MARK: - Private: URLRequest 빌드

    /// APIEndpoint 정보를 URLRequest로 변환
    ///
    /// 구성 요소:
    /// - baseURL + endpoint.path → URL
    /// - queryItems → URL 쿼리 파라미터
    /// - method → HTTP 메서드
    /// - body → JSON 직렬화된 HTTP Body
    /// - Authorization → Keychain에서 토큰 자동 주입
    private func buildRequest(_ endpoint: APIEndpoint) -> URLRequest? {
        // URL 조합
        var components = URLComponents(string: baseURL + endpoint.path)
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else { return nil }

        // URLRequest 설정
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Bearer Token 자동 주입
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // HTTP Body 직렬화
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        return request
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// 토큰 만료 시 발송 — AppDelegate/SceneDelegate에서 수신하여 로그인 화면으로 전환
    static let hiTripTokenExpired = Notification.Name("hiTripTokenExpired")
}

// MARK: - NetworkError (Deprecated — 호환용)

/// 기존 네트워크 에러 타입 (HiTripError로 마이그레이션 권장)
/// @available(*, deprecated, message: "Use HiTripError instead")
enum NetworkError: LocalizedError {
    /// URL 조합 실패
    case invalidURL
    /// 네트워크 요청 실패 (인터넷 끊김, 타임아웃 등)
    case requestFailed(String)
    /// HTTPURLResponse 캐스팅 실패
    case invalidResponse
    /// 2xx 외의 HTTP 상태코드
    case httpError(Int)
    /// 응답 데이터 없음
    case noData
    /// JSON 디코딩 실패
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .requestFailed(let msg):
            return "요청 실패: \(msg)"
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .httpError(let code):
            return "서버 오류 (HTTP \(code))"
        case .noData:
            return "데이터가 없습니다."
        case .decodingFailed(let msg):
            return "데이터 파싱 실패: \(msg)"
        }
    }
}
