import Foundation

// MARK: - User Type
/// 사용자 유형: 안내사(guide) / 관광객(tourist)
/// 서버 JSON의 "userType" 필드와 1:1 매핑
enum UserType: String, Codable {
    case guide = "guide"
    case tourist = "tourist"
}

// MARK: - Login Models

/// 로그인 API 응답 모델
/// - 서버에서 accessToken, refreshToken, user 정보를 함께 반환
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserInfo
}

/// 사용자 상세 정보
/// - Login/SignUp 응답에 공통으로 포함되는 사용자 데이터
struct UserInfo: Codable {
    let id: String
    let name: String
    let userType: UserType
    let phone: String?       // 선택 정보
    let country: String?     // 관광객의 국적 (안내사는 nil)
}

/// 로그인 요청 모델 (내부 전용, Codable 불필요)
/// - View → ViewModel → UseCase → Repository 순으로 전달
struct LoginRequest {
    let id: String
    let password: String
}

// MARK: - Sign Up Models

/// 회원가입 요청 모델
struct SignUpRequest {
    let nickname: String
    let userId: String
    let password: String
}

/// 회원가입 API 응답 모델
struct SignUpResponse: Codable {
    let message: String
    let user: UserInfo
}

/// 닉네임 중복 확인 API 응답 모델
struct NicknameCheckResponse: Codable {
    let isAvailable: Bool
    let message: String?
}
