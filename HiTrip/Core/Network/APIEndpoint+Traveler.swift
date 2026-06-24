import Foundation

// MARK: - Traveler Endpoints
/// 여행객(참가자) 전용 API 엔드포인트
///
/// 인증: TravelerTokenAuth (Bearer token)
/// 모든 엔드포인트는 /api/traveler/ 하위에 있으며,
/// 로그인 후 발급된 token을 Authorization: Bearer <token>으로 전달

extension APIEndpoint {

    // MARK: - Auth

    /// 여행객 로그인 (전화번호 + 생년월일 + 초대코드)
    /// POST /api/traveler/login/
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
    /// POST /api/traveler/logout/
    static func travelerLogout() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/logout/", method: .post)
    }

    // MARK: - Profile

    /// 현재 여행객 프로필 + 여행 정보 조회
    /// GET /api/traveler/me/
    static func travelerMe() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/me/")
    }

    /// 현재 여행객 프로필 수정
    /// PATCH /api/traveler/me/
    static func travelerMeUpdate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/me/", method: .patch, body: body)
    }

    // MARK: - Home

    /// 홈 요약 (여행 정보 + 오늘 일정 + 다음 일정 + 담당자 연락처)
    /// GET /api/traveler/home/
    static func travelerHome() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/home/")
    }

    // MARK: - Trip

    /// 현재 여행객의 여행 정보
    /// GET /api/traveler/trip/
    static func travelerTrip() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/trip/")
    }

    // MARK: - Schedule

    /// 여행 일정 목록
    /// GET /api/traveler/schedules/
    static func travelerSchedules() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/schedules/")
    }

    /// 여행 일정 단건 조회
    /// GET /api/traveler/schedules/{schedule_id}/
    static func travelerSchedule(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/schedules/\(id)/")
    }

    // MARK: - Calendar

    /// 날짜별 그룹화된 캘린더 (trip + days[date, schedules])
    /// GET /api/traveler/calendar/
    static func travelerCalendar() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/calendar/")
    }

    // MARK: - Checklist

    /// 체크리스트 항목 목록
    /// GET /api/traveler/checklists/
    static func travelerChecklists() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/checklists/")
    }

    /// 체크리스트 항목 완료/미완료 업데이트
    /// PATCH /api/traveler/checklists/{item_id}/
    static func travelerChecklistUpdate(itemId: Int, isChecked: Bool) -> APIEndpoint {
        APIEndpoint(
            path: "/api/traveler/checklists/\(itemId)/",
            method: .patch,
            body: ["is_checked": isChecked]
        )
    }

    // MARK: - Notices

    /// 공지사항 목록
    /// GET /api/traveler/notices/
    static func travelerNotices() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/notices/")
    }

    /// 공지사항 단건 조회
    /// GET /api/traveler/notices/{notice_id}/
    static func travelerNotice(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/notices/\(id)/")
    }

    // MARK: - Messages (Thread 기반)

    /// 메시지 스레드 목록
    /// GET /api/traveler/messages/threads/
    static func travelerMessageThreads() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/messages/threads/")
    }

    /// 메시지 스레드 생성 (새 문의)
    /// POST /api/traveler/messages/threads/
    static func travelerMessageThreadCreate(subject: String, body: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/traveler/messages/threads/",
            method: .post,
            body: ["subject": subject, "body": body]
        )
    }

    /// 스레드 내 메시지 목록
    /// GET /api/traveler/messages/threads/{thread_id}/messages/
    static func travelerMessages(threadId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/messages/threads/\(threadId)/messages/")
    }

    /// 스레드에 메시지 전송
    /// POST /api/traveler/messages/threads/{thread_id}/messages/
    static func travelerMessageCreate(threadId: Int, body: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/traveler/messages/threads/\(threadId)/messages/",
            method: .post,
            body: ["body": body]
        )
    }

    // MARK: - Spots

    /// 인기 여행지 목록 (spot_type: popular)
    /// GET /api/traveler/popular-spots/
    static func travelerPopularSpots() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/popular-spots/")
    }

    /// 추천 여행지 목록 (spot_type: recommended)
    /// GET /api/traveler/recommended-spots/
    static func travelerRecommendedSpots() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/recommended-spots/")
    }

    /// 여행지 단건 조회
    /// GET /api/traveler/spots/{spot_id}/
    static func travelerSpot(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/spots/\(id)/")
    }

    // MARK: - Map

    /// 지도에 표시할 장소 목록
    /// GET /api/traveler/map/places/
    static func travelerMapPlaces() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/map/places/")
    }

    // MARK: - Manager Contact

    /// 현재 여행 담당자 연락처
    /// GET /api/traveler/contacts/manager/
    static func travelerManagerContact() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/contacts/manager/")
    }

    // MARK: - Emergency

    /// 긴급 도움 요청
    /// POST /api/traveler/emergency-requests/
    static func travelerEmergencyRequest(
        message: String,
        latitude: String? = nil,
        longitude: String? = nil,
        accuracyM: String? = nil
    ) -> APIEndpoint {
        var body: [String: Any] = ["message": message]
        if let lat = latitude  { body["latitude"]   = lat }
        if let lng = longitude { body["longitude"]  = lng }
        if let acc = accuracyM { body["accuracy_m"] = acc }
        return APIEndpoint(path: "/api/traveler/emergency-requests/", method: .post, body: body)
    }

    // MARK: - Agreements

    /// 동의 상태 조회
    /// GET /api/traveler/agreements/
    static func travelerAgreements() -> APIEndpoint {
        APIEndpoint(path: "/api/traveler/agreements/")
    }

    /// 동의 상태 저장/업데이트
    /// POST /api/traveler/agreements/
    static func travelerAgreementsUpdate(
        termsAccepted: Bool,
        locationPermissionAccepted: Bool? = nil,
        notificationPermissionAccepted: Bool? = nil
    ) -> APIEndpoint {
        var body: [String: Any] = ["terms_accepted": termsAccepted]
        if let loc = locationPermissionAccepted      { body["location_permission_accepted"]     = loc }
        if let notif = notificationPermissionAccepted { body["notification_permission_accepted"] = notif }
        return APIEndpoint(path: "/api/traveler/agreements/", method: .post, body: body)
    }
}
