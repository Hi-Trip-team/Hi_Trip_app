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
    /// 약관 동의가 필요한 계정인지 — 서버(관광객) 또는 로컬 기록(안내사) 기준
    var requiresAgreement: Bool = false
}

/// 스플래시에서 저장된 세션을 확인한 결과
struct SessionState {
    let userType: UserType
    let requiresAgreement: Bool
}

/// 사용자 상세 정보
/// - 로그인 응답에 포함되는 사용자 데이터
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
    /// 동시 로그인 차단 후 강제 로그인
    var force: Bool = false
    /// 관광객 계정에 여행이 여러 개일 때 선택한 여행
    var tripId: Int? = nil
}

