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

    /// 로그인 API
    /// - POST /auth/login
    /// - Body: { "id": "...", "password": "..." }
    static func login(id: String, password: String) -> APIEndpoint {
        APIEndpoint(
            path: "/auth/login",
            method: .post,
            body: ["id": id, "password": password]
        )
    }

    /// 토큰 갱신 API
    /// - POST /auth/refresh
    /// - Body: { "refreshToken": "..." }
    static func refreshToken(token: String) -> APIEndpoint {
        APIEndpoint(
            path: "/auth/refresh",
            method: .post,
            body: ["refreshToken": token]
        )
    }
}

// MARK: - Sign Up Endpoints

extension APIEndpoint {

    /// 회원가입 API
    /// - POST /auth/signup
    static func signUp(nickname: String, userId: String, password: String) -> APIEndpoint {
        APIEndpoint(
            path: "/auth/signup",
            method: .post,
            body: [
                "nickname": nickname,
                "userId": userId,
                "password": password
            ]
        )
    }

    /// 닉네임 중복 확인 API
    /// - GET /auth/check-nickname?nickname=...
    static func checkNickname(_ nickname: String) -> APIEndpoint {
        APIEndpoint(
            path: "/auth/check-nickname",
            queryItems: [URLQueryItem(name: "nickname", value: nickname)]
        )
    }
}

// MARK: - Phase별 Endpoint 확장 가이드
//
// Phase 2: APIEndpoint+Schedule.swift  (일정 CRUD)
// Phase 3: APIEndpoint+Chat.swift      (채팅/메시지)
// Phase 4: APIEndpoint+Map.swift       (지도/스팟추천)
//          APIEndpoint+Tour.swift      (TourAPI 연동)
// Phase 5: APIEndpoint+Health.swift    (건강데이터)
// Phase 6: APIEndpoint+Notice.swift    (공지사항/푸시)
