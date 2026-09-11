import Foundation

// MARK: - APIEndpoint
/// API 엔드포인트 정의 구조체
///
/// 설계 의도:
/// - Moya의 TargetType 역할을 struct로 직접 구현
/// - path, method, body, queryItems를 하나의 값 타입으로 캡슐화
/// - 각 도메인(Auth, Schedule, Map 등)은 extension으로 분리하여 관리
///
/// 면접 포인트:
/// "Moya 없이 어떻게 엔드포인트를 관리하셨나요?"
/// → "struct + static 팩토리 메서드 패턴으로 타입 안전하게 정의했습니다.
///    도메인별 extension 분리로 파일이 커지는 것도 방지했습니다."

struct APIEndpoint {

    let path: String
    let method: HTTPMethod
    let body: [String: Any]?
    let queryItems: [URLQueryItem]?

    // MARK: - HTTP Method

    enum HTTPMethod: String {
        case get    = "GET"
        case post   = "POST"
        case put    = "PUT"
        case patch  = "PATCH"
        case delete = "DELETE"
    }

    // MARK: - Init

    init(
        path: String,
        method: HTTPMethod = .get,
        body: [String: Any]? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.queryItems = queryItems
    }
}

// MARK: - Auth Endpoints

extension APIEndpoint {

    // MARK: - Staff Auth

    /// 스태프 로그인
    /// POST /api/v1/staff/auth/login/
    static func login(username: String, password: String, force: Bool = false) -> APIEndpoint {
        var body: [String: Any] = ["username": username, "password": password]
        if force { body[forceLoginKey] = true }
        return APIEndpoint(path: "/api/v1/staff/auth/login/", method: .post, body: body)
    }

    /// 동시 로그인 차단 후 강제 로그인 플래그
    ///
    /// ⚠️ 서버 스펙 미정 — 동시 로그인 감지(409)와 이 필드는 서버에 아직 없습니다.
    /// 서버가 확정되면 이 이름만 맞추면 됩니다.
    static let forceLoginKey = "force_login"

    /// 스태프 로그아웃
    /// POST /api/v1/staff/auth/logout/
    static func logout() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/auth/logout/", method: .post)
    }

    /// 스태프 내 프로필 조회
    /// GET /api/v1/staff/auth/me/
    static func profile() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/auth/me/")
    }

    // MARK: - Staff CRUD

    // MARK: - Tourists (매니저측 관광객 관리)

}

// MARK: - Phase별 Endpoint 확장 가이드
//
// Phase 2: APIEndpoint+Schedule.swift  (일정 CRUD)
// Phase 3: APIEndpoint+Chat.swift      (채팅/메시지)
// Phase 4: APIEndpoint+Map.swift       (지도/스팟추천)
//          APIEndpoint+Tour.swift      (TourAPI 연동)
// Phase 5: APIEndpoint+Health.swift    (건강데이터)
// Phase 6: APIEndpoint+Notice.swift    (공지사항/푸시)
