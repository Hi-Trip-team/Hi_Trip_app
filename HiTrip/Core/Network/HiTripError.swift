import Foundation

// MARK: - HiTripError
/// 앱 전체에서 사용하는 통합 에러 타입
///
/// 설계 의도:
/// - Network/Domain/Presentation 모든 레이어에서 일관된 에러 처리
/// - 서버 에러 응답(body)을 파싱하여 구체적인 정보 보존
/// - HTTP 상태코드별 분류로 자동 로그인 만료, 권한 에러 등 대응
/// - 사용자에게 보여줄 한글 메시지와 개발자 디버그 정보 분리
///
/// 면접 포인트:
/// "에러 처리를 어떻게 설계하셨나요?"
/// → "계층적 에러 enum으로 네트워크/서버/클라이언트 에러를 분류하고,
///    서버 응답 body를 파싱하여 필드별 Validation 에러까지 전달합니다.
///    ViewModel에서는 ErrorHandler를 통해 사용자 친화적 메시지로 변환합니다."

enum HiTripError: Error, Equatable {

    // MARK: - Network (연결 자체의 문제)

    /// URL 조합 실패 (개발자 실수)
    case invalidURL

    /// 인터넷 연결 없음
    case noConnection

    /// 요청 타임아웃
    case timeout

    /// 기타 네트워크 에러 (URLSession 레벨)
    case networkFailure(String)

    // MARK: - Server (HTTP 응답은 왔으나 실패)

    /// 401 — 인증 실패 또는 토큰 만료
    case unauthorized(ServerErrorDetail)

    /// 403 — 권한 없음
    case forbidden(ServerErrorDetail)

    /// 404 — 리소스 없음
    case notFound(ServerErrorDetail)

    /// 409 — 충돌 (이미 존재하는 리소스 등)
    case conflict(ServerErrorDetail)

    /// 422 / 400 — Validation 실패 (필드별 에러 포함)
    case validationFailed(ServerErrorDetail)

    /// 429 — Too Many Requests
    case rateLimited

    /// 500+ — 서버 내부 오류
    case serverError(Int, ServerErrorDetail)

    /// 기타 HTTP 에러
    case httpError(Int, ServerErrorDetail)

    // MARK: - Client (앱 내부 문제)

    /// JSON 디코딩 실패
    case decodingFailed(String)

    /// 응답 데이터 없음
    case noData

    /// HTTPURLResponse 캐스팅 실패
    case invalidResponse

    // MARK: - Equatable

    static func == (lhs: HiTripError, rhs: HiTripError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noConnection, .noConnection),
             (.timeout, .timeout),
             (.rateLimited, .rateLimited),
             (.noData, .noData),
             (.invalidResponse, .invalidResponse):
            return true
        case (.networkFailure(let a), .networkFailure(let b)):
            return a == b
        case (.decodingFailed(let a), .decodingFailed(let b)):
            return a == b
        case (.unauthorized(let a), .unauthorized(let b)),
             (.forbidden(let a), .forbidden(let b)),
             (.notFound(let a), .notFound(let b)),
             (.conflict(let a), .conflict(let b)),
             (.validationFailed(let a), .validationFailed(let b)):
            return a == b
        case (.serverError(let c1, let d1), .serverError(let c2, let d2)),
             (.httpError(let c1, let d1), .httpError(let c2, let d2)):
            return c1 == c2 && d1 == d2
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension HiTripError: LocalizedError {

    /// 사용자에게 표시할 한글 메시지
    var errorDescription: String? {
        switch self {
        // Network
        case .invalidURL:
            return "잘못된 요청입니다."
        case .noConnection:
            return "인터넷 연결을 확인해주세요."
        case .timeout:
            return "서버 응답이 지연되고 있어요. 잠시 후 다시 시도해주세요."
        case .networkFailure:
            return "네트워크 오류가 발생했습니다. 다시 시도해주세요."

        // Server — 사용자 메시지
        case .unauthorized(let detail):
            return detail.userMessage ?? "로그인이 만료되었습니다. 다시 로그인해주세요."
        case .forbidden(let detail):
            return detail.userMessage ?? "접근 권한이 없습니다."
        case .notFound(let detail):
            return detail.userMessage ?? "요청한 정보를 찾을 수 없습니다."
        case .conflict(let detail):
            return detail.userMessage ?? "이미 존재하는 데이터입니다."
        case .validationFailed(let detail):
            return detail.userMessage ?? "입력 정보를 확인해주세요."
        case .rateLimited:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
        case .serverError(_, let detail):
            return detail.userMessage ?? "서버에 일시적인 문제가 발생했습니다."
        case .httpError(_, let detail):
            return detail.userMessage ?? "요청 처리 중 오류가 발생했습니다."

        // Client
        case .decodingFailed:
            return "데이터를 처리하는 중 오류가 발생했습니다."
        case .noData:
            return "서버에서 데이터를 받지 못했습니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        }
    }
}

// MARK: - 편의 프로퍼티

extension HiTripError {

    /// 토큰 만료로 재로그인이 필요한지 여부
    var requiresReauth: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    /// 재시도 가능한 에러인지 여부
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .rateLimited:
            return true
        case .serverError(let code, _):
            return code >= 500
        case .networkFailure:
            return true
        default:
            return false
        }
    }

    /// HTTP 상태 코드 (있는 경우)
    var statusCode: Int? {
        switch self {
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .conflict: return 409
        case .validationFailed: return 400
        case .rateLimited: return 429
        case .serverError(let code, _): return code
        case .httpError(let code, _): return code
        default: return nil
        }
    }

    /// 디버그용 상세 정보 (콘솔 로깅용)
    var debugDescription: String {
        switch self {
        case .invalidURL:
            return "[HiTripError] invalidURL"
        case .noConnection:
            return "[HiTripError] noConnection"
        case .timeout:
            return "[HiTripError] timeout"
        case .networkFailure(let msg):
            return "[HiTripError] networkFailure: \(msg)"
        case .unauthorized(let d):
            return "[HiTripError] 401 unauthorized: \(d)"
        case .forbidden(let d):
            return "[HiTripError] 403 forbidden: \(d)"
        case .notFound(let d):
            return "[HiTripError] 404 notFound: \(d)"
        case .conflict(let d):
            return "[HiTripError] 409 conflict: \(d)"
        case .validationFailed(let d):
            return "[HiTripError] 400/422 validation: \(d)"
        case .rateLimited:
            return "[HiTripError] 429 rateLimited"
        case .serverError(let code, let d):
            return "[HiTripError] \(code) serverError: \(d)"
        case .httpError(let code, let d):
            return "[HiTripError] \(code) httpError: \(d)"
        case .decodingFailed(let msg):
            return "[HiTripError] decodingFailed: \(msg)"
        case .noData:
            return "[HiTripError] noData"
        case .invalidResponse:
            return "[HiTripError] invalidResponse"
        }
    }
}

// MARK: - ServerErrorDetail
/// 서버 에러 응답의 파싱 결과
///
/// Django REST Framework 에러 포맷:
/// - 단일 메시지: {"detail": "Authentication credentials were not provided."}
/// - 필드 에러:   {"username": ["This field is required."], "password": ["Too short."]}
/// - 복합:        {"detail": "Validation failed", "errors": {...}}

struct ServerErrorDetail: Equatable, CustomStringConvertible {

    /// 서버가 보낸 대표 메시지 (detail 필드)
    let message: String?

    /// 필드별 에러 메시지 (Validation 에러 시)
    let fieldErrors: [String: [String]]

    /// 원본 응답 body (디버깅용)
    let rawBody: String?

    /// HTTP 상태 코드
    let statusCode: Int

    // MARK: - 사용자 표시용 메시지

    /// 사용자에게 보여줄 메시지 (우선순위: 필드에러 요약 → detail → nil)
    var userMessage: String? {
        // 필드별 에러가 있으면 첫 번째 에러를 보여줌
        if !fieldErrors.isEmpty {
            let firstField = fieldErrors.first
            if let fieldName = firstField?.key,
               let messages = firstField?.value,
               let firstMessage = messages.first {
                return fieldDisplayName(fieldName) + ": " + firstMessage
            }
        }
        return message
    }

    /// 모든 필드 에러를 줄바꿈으로 연결 (Alert에서 표시)
    var allFieldErrorMessages: String? {
        guard !fieldErrors.isEmpty else { return nil }
        return fieldErrors.map { field, messages in
            let name = fieldDisplayName(field)
            return messages.map { "\(name): \($0)" }.joined(separator: "\n")
        }.joined(separator: "\n")
    }

    var description: String {
        var parts: [String] = []
        if let message { parts.append("message=\(message)") }
        if !fieldErrors.isEmpty { parts.append("fields=\(fieldErrors)") }
        return "ServerErrorDetail(\(parts.joined(separator: ", ")))"
    }

    // MARK: - Private

    /// 서버 필드명 → 한글 표시명 변환
    private func fieldDisplayName(_ field: String) -> String {
        let map: [String: String] = [
            "username": "아이디",
            "password": "비밀번호",
            "email": "이메일",
            "phone": "전화번호",
            "title": "제목",
            "destination": "목적지",
            "start_date": "시작일",
            "end_date": "종료일",
            "birth_date": "생년월일",
            "invite_code": "초대코드",
            "name": "이름",
            "nickname": "닉네임",
            "non_field_errors": "입력 오류",
            "detail": "상세",
        ]
        return map[field] ?? field
    }
}

// MARK: - ServerErrorDetail 파싱

extension ServerErrorDetail {

    /// 서버 응답 Data를 파싱하여 ServerErrorDetail 생성
    ///
    /// Django REST Framework 에러 형식을 처리:
    /// 1. {"detail": "string"} — 단일 메시지
    /// 2. {"field": ["error1", "error2"]} — 필드별 Validation
    /// 3. {"detail": "msg", "field": [...]} — 혼합
    static func parse(data: Data?, statusCode: Int) -> ServerErrorDetail {
        let rawBody = data.flatMap { String(data: $0, encoding: .utf8) }

        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ServerErrorDetail(
                message: nil,
                fieldErrors: [:],
                rawBody: rawBody,
                statusCode: statusCode
            )
        }

        // detail 필드 추출
        var message: String?
        if let detail = json["detail"] as? String {
            message = detail
        } else if let detailArray = json["detail"] as? [String] {
            message = detailArray.joined(separator: " ")
        }

        // 필드별 에러 추출
        var fieldErrors: [String: [String]] = [:]
        for (key, value) in json {
            if key == "detail" { continue }
            if let messages = value as? [String] {
                fieldErrors[key] = messages
            } else if let singleMessage = value as? String {
                fieldErrors[key] = [singleMessage]
            }
        }

        // non_field_errors 처리
        if let nonFieldErrors = json["non_field_errors"] as? [String] {
            fieldErrors["non_field_errors"] = nonFieldErrors
            if message == nil {
                message = nonFieldErrors.first
            }
        }

        return ServerErrorDetail(
            message: message,
            fieldErrors: fieldErrors,
            rawBody: rawBody,
            statusCode: statusCode
        )
    }

    /// 빈 에러 디테일 생성 (서버 응답이 없을 때)
    static func empty(statusCode: Int) -> ServerErrorDetail {
        ServerErrorDetail(message: nil, fieldErrors: [:], rawBody: nil, statusCode: statusCode)
    }
}

// MARK: - HiTripError 팩토리

extension HiTripError {

    /// HTTP 상태코드 + 응답 Data로 적절한 HiTripError 생성
    static func from(statusCode: Int, data: Data?) -> HiTripError {
        let detail = ServerErrorDetail.parse(data: data, statusCode: statusCode)

        switch statusCode {
        case 400, 422:
            return .validationFailed(detail)
        case 401:
            return .unauthorized(detail)
        case 403:
            return .forbidden(detail)
        case 404:
            return .notFound(detail)
        case 409:
            return .conflict(detail)
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError(statusCode, detail)
        default:
            return .httpError(statusCode, detail)
        }
    }

    /// URLSession 에러를 HiTripError로 변환
    static func from(urlError: Error) -> HiTripError {
        let nsError = urlError as NSError

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDataNotAllowed:
            return .noConnection

        case NSURLErrorTimedOut:
            return .timeout

        case NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost,
             NSURLErrorDNSLookupFailed:
            return .networkFailure("서버에 연결할 수 없습니다.")

        case NSURLErrorSecureConnectionFailed,
             NSURLErrorServerCertificateUntrusted:
            return .networkFailure("보안 연결에 실패했습니다.")

        default:
            return .networkFailure(urlError.localizedDescription)
        }
    }
}

// MARK: - 기존 NetworkError → HiTripError 변환 (마이그레이션용)

extension NetworkError {

    /// 기존 NetworkError를 HiTripError로 변환
    var toHiTripError: HiTripError {
        switch self {
        case .invalidURL:
            return .invalidURL
        case .requestFailed(let msg):
            return .networkFailure(msg)
        case .invalidResponse:
            return .invalidResponse
        case .httpError(let code):
            return .from(statusCode: code, data: nil)
        case .noData:
            return .noData
        case .decodingFailed(let msg):
            return .decodingFailed(msg)
        }
    }
}
