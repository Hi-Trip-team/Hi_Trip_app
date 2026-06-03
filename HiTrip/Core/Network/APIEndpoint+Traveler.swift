import Foundation

// MARK: - Traveler Endpoints
/// 여행객(참가자) 전용 API 엔드포인트
///
/// 백엔드: /api/traveler/
/// 관광객이 초대코드로 로그인하여 자신의 여행/일정을 조회하는 API

extension APIEndpoint {

    // MARK: - Traveler Auth

    /// 여행객 로그인 (초대코드 기반)
    /// - POST /api/traveler/login/
    static func travelerLogin(phone: String, birthDate: String, inviteCode: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/traveler/login/",
            method: .post,
            body: [
                "phone": phone,
                "birth_date": birthDate,
                "invite_code": inviteCode
            ]
        )
    }

    /// 여행객 로그아웃
    /// - POST /api/traveler/logout/
    static func travelerLogout() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/logout/", method: .post)
    }

    // MARK: - Traveler Profile

    /// 현재 여행객 프로필 조회
    /// - GET /api/traveler/me/
    static func travelerMe() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/me/")
    }

    // MARK: - Traveler Trip & Schedule

    /// 현재 여행객의 여행 정보 조회
    /// - GET /api/traveler/trip/
    static func travelerTrip() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/trip/")
    }

    /// 현재 여행객의 일정 목록 조회
    /// - GET /api/traveler/schedules/
    static func travelerSchedules() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/schedules/")
    }
}
