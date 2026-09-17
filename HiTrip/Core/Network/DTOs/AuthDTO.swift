import Foundation

// MARK: - AuthLoginRequest
/// POST /api/auth/login/ 요청 바디

// MARK: - AuthLoginResponse
/// POST /api/auth/login/ 응답
///
/// 서버는 UserDetail을 반환:
/// { "id": 1, "username": "...", "email": "...", "full_name_kr": "...", "role": "...", ... }
/// 세션 기반 인증이므로 토큰은 Set-Cookie 헤더로 전달됨
///
/// 하위 호환을 위해 token/key 필드도 유지 (다른 인증 방식 대응)

struct AuthLoginResponse: Decodable {
    // 토큰 기반 인증 (있는 경우)
    let token: String?
    let key: String?
    let sessionid: String?

    // UserDetail 필드 (서버 실제 응답)
    let id: Int?
    let username: String?
    let email: String?
    let phone: String?
    let firstName: String?
    let lastName: String?
    let firstNameKr: String?
    let lastNameKr: String?
    let fullNameKr: String?
    let fullNameEn: String?
    let role: String?
    let roleDisplay: String?
    let isApproved: Bool?

    /// 표시용 이름 (한글 이름 우선, 없으면 username)
    var displayName: String {
        if let kr = fullNameKr, !kr.isEmpty { return kr }
        if let first = firstNameKr, let last = lastNameKr, !first.isEmpty {
            return last + first
        }
        if let en = fullNameEn, !en.isEmpty { return en }
        return username ?? "사용자"
    }

    /// 표시용 이메일
    var displayEmail: String {
        email ?? ""
    }
}

// MARK: - AuthRegisterRequest
/// POST /api/auth/register/ 요청 바디

// MARK: - StaffDTO
/// GET /api/auth/staff/ 응답 모델

// MARK: - ProfileDTO
/// GET /api/auth/profile/ 응답 모델

struct ProfileDTO: Decodable {
    let id: Int?
    let username: String?
    let email: String?
    let firstName: String?
    let lastName: String?
    let phone: String?
    let role: String?
    let fullNameKr: String?
    let firstNameKr: String?
    let lastNameKr: String?
}

// MARK: - ProfileDTO → User 변환

extension ProfileDTO {

}

// MARK: - TravelerDTO
/// GET /api/auth/travelers/ 응답 모델

