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
    static func login(username: String, password: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/staff/auth/login/",
            method: .post,
            body: ["username": username, "password": password]
        )
    }

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

    /// 스태프 프로필 수정
    /// PATCH /api/v1/staff/auth/me/
    static func profileUpdate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/auth/me/", method: .patch, body: body)
    }

    // MARK: - Staff CRUD

    /// 스태프 목록 조회
    /// GET /api/v1/staff/
    static func staffList() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/")
    }

    /// 스태프 계정 생성
    /// POST /api/v1/staff/
    static func staffCreate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/", method: .post, body: body)
    }

    /// 스태프 상세 조회
    /// GET /api/v1/staff/{id}/
    static func staffRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/\(id)/")
    }

    /// 스태프 전체 수정
    /// PUT /api/v1/staff/{id}/
    static func staffUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/\(id)/", method: .put, body: body)
    }

    /// 스태프 일부 수정
    /// PATCH /api/v1/staff/{id}/
    static func staffPartialUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/\(id)/", method: .patch, body: body)
    }

    /// 스태프 삭제
    /// DELETE /api/v1/staff/{id}/
    static func staffDestroy(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/\(id)/", method: .delete)
    }

    /// 스태프 승인
    /// POST /api/v1/staff/{id}/approve/
    static func staffApprove(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/\(id)/approve/", method: .post)
    }

    // MARK: - Tourists (매니저측 관광객 관리)

    /// 여행객 목록 조회
    /// GET /api/auth/travelers/
    static func travelersList() -> APIEndpoint {
        APIEndpoint(path: "/api/auth/travelers/")
    }

    /// 여행객 상세 조회
    /// GET /api/auth/travelers/{id}/
    static func travelersRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/auth/travelers/\(id)/")
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
