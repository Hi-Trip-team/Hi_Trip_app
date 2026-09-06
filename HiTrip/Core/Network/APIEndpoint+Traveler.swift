import Foundation

// MARK: - Tourist (여행객) Endpoints
/// 여행객 전용 API 엔드포인트
///
/// 인증: Token (Bearer)
/// 베이스: /api/v1/tourist/
/// 로그인 후 발급된 token → Authorization: Bearer <token>

extension APIEndpoint {

    // MARK: - Auth

    /// 여행객 로그인 (발급 계정 username + password)
    /// POST /api/v1/tourist/auth/login/
    static func travelerLogin(username: String, password: String, tripId: Int? = nil) -> APIEndpoint {
        var body: [String: Any] = ["username": username, "password": password]
        if let id = tripId { body["trip_id"] = id }
        return APIEndpoint(path: "/api/v1/tourist/auth/login/", method: .post, body: body)
    }

    /// 여행객 최초 비밀번호 변경
    /// POST /api/v1/tourist/auth/change-initial-password/
    static func travelerChangeInitialPassword(newPassword: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/tourist/auth/change-initial-password/",
            method: .post,
            body: ["new_password": newPassword]
        )
    }

    /// 여행객 로그아웃
    /// POST /api/v1/tourist/logout/
    static func travelerLogout() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/logout/", method: .post)
    }

    // MARK: - Profile

    /// 현재 여행객 프로필
    /// GET /api/v1/tourist/me/
    static func travelerMe() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/me/")
    }

    /// 현재 여행객 프로필 수정
    /// PATCH /api/v1/tourist/me/
    static func travelerMeUpdate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/me/", method: .patch, body: body)
    }

    // MARK: - Home

    /// 홈 요약 (여행 정보 + 오늘 일정 + 담당자 연락처)
    /// GET /api/v1/tourist/home/
    static func travelerHome() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/home/")
    }

    // MARK: - Trip

    /// 현재 여행 정보
    /// GET /api/v1/tourist/trip/
    static func travelerTrip() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/trip/")
    }

    /// 내 여행 목록
    /// GET /api/v1/tourist/trips/
    static func travelerTrips() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/trips/")
    }

    // MARK: - Schedule

    /// 여행 일정 목록
    /// GET /api/v1/tourist/schedules/
    static func travelerSchedules() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/schedules/")
    }

    /// 여행 일정 단건 조회
    /// GET /api/v1/tourist/schedules/{schedule_id}/
    static func travelerSchedule(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/schedules/\(id)/")
    }

    // MARK: - Personal Schedules

    /// 개인 일정 목록
    /// GET /api/v1/tourist/personal-schedules/
    static func travelerPersonalSchedules() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/personal-schedules/")
    }

    /// 개인 일정 생성
    /// POST /api/v1/tourist/personal-schedules/
    static func travelerPersonalScheduleCreate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/personal-schedules/", method: .post, body: body)
    }

    /// 개인 일정 단건 조회
    /// GET /api/v1/tourist/personal-schedules/{personal_schedule_id}/
    static func travelerPersonalSchedule(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/personal-schedules/\(id)/")
    }

    /// 개인 일정 수정
    /// PATCH /api/v1/tourist/personal-schedules/{personal_schedule_id}/
    static func travelerPersonalScheduleUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/personal-schedules/\(id)/", method: .patch, body: body)
    }

    /// 개인 일정 삭제
    /// DELETE /api/v1/tourist/personal-schedules/{personal_schedule_id}/
    static func travelerPersonalScheduleDelete(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/personal-schedules/\(id)/", method: .delete)
    }

    // MARK: - Calendar

    /// 날짜별 캘린더
    /// GET /api/v1/tourist/calendar/
    static func travelerCalendar() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/calendar/")
    }

    // MARK: - Checklist

    /// 체크리스트 항목 목록
    /// GET /api/v1/tourist/checklists/
    static func travelerChecklists() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/checklists/")
    }

    /// 체크리스트 항목 완료/미완료
    /// PATCH /api/v1/tourist/checklists/{item_id}/
    static func travelerChecklistUpdate(itemId: Int, isChecked: Bool) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/tourist/checklists/\(itemId)/",
            method: .patch,
            body: ["is_checked": isChecked]
        )
    }

    // MARK: - Notices

    /// 공지사항 목록
    /// GET /api/v1/tourist/notices/
    static func travelerNotices() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/notices/")
    }

    /// 공지사항 단건 조회
    /// GET /api/v1/tourist/notices/{notice_id}/
    static func travelerNotice(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/notices/\(id)/")
    }

    /// 공지사항 읽음 처리
    /// POST /api/v1/tourist/notices/{notice_id}/read/
    static func travelerNoticeRead(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/notices/\(id)/read/", method: .post)
    }

    // MARK: - Messages (스레드 기반 문의)

    /// 문의 스레드 목록
    /// GET /api/v1/tourist/messages/threads/
    static func travelerMessageThreads() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/messages/threads/")
    }

    /// 문의 스레드 생성
    /// POST /api/v1/tourist/messages/threads/
    static func travelerMessageThreadCreate(subject: String, body: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/tourist/messages/threads/",
            method: .post,
            body: ["subject": subject, "body": body]
        )
    }

    /// 스레드 내 메시지 목록
    /// GET /api/v1/tourist/messages/threads/{thread_id}/messages/
    static func travelerMessages(threadId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/messages/threads/\(threadId)/messages/")
    }

    /// 스레드에 메시지 전송
    /// POST /api/v1/tourist/messages/threads/{thread_id}/messages/
    static func travelerMessageCreate(threadId: Int, body: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/tourist/messages/threads/\(threadId)/messages/",
            method: .post,
            body: ["body": body]
        )
    }

    // MARK: - Spots

    /// 인기 여행지
    /// GET /api/v1/tourist/popular-spots/
    static func travelerPopularSpots() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/popular-spots/")
    }

    /// 추천 여행지
    /// GET /api/v1/tourist/recommended-spots/
    static func travelerRecommendedSpots() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/recommended-spots/")
    }

    /// 여행지 단건 조회
    /// GET /api/v1/tourist/spots/{spot_id}/
    static func travelerSpot(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/spots/\(id)/")
    }

    // MARK: - Map

    /// 지도 장소 목록
    /// GET /api/v1/tourist/map/places/
    static func travelerMapPlaces() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/map/places/")
    }

    // MARK: - Manager Contact

    /// 담당 매니저 연락처
    /// GET /api/v1/tourist/contacts/manager/
    static func travelerManagerContact() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/contacts/manager/")
    }

    // MARK: - Emergency

    /// 긴급 도움 요청
    /// POST /api/v1/tourist/emergency-requests/
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
        return APIEndpoint(path: "/api/v1/tourist/emergency-requests/", method: .post, body: body)
    }

    // MARK: - Safety

    /// 위치 전송
    /// POST /api/v1/tourist/safety/location/
    static func travelerSafetyLocation(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/safety/location/", method: .post, body: body)
    }

    /// 안전 확인 요청 목록
    /// GET /api/v1/tourist/safety/prompts/active/
    static func travelerSafetyPromptsActive() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/safety/prompts/active/")
    }

    /// 안전 확인 응답
    /// POST /api/v1/tourist/safety/prompts/{incident_id}/respond/
    static func travelerSafetyPromptRespond(incidentId: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/safety/prompts/\(incidentId)/respond/", method: .post, body: body)
    }

    /// 안전 요약 조회
    /// GET /api/v1/tourist/safety/summary/
    static func travelerSafetySummary() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/safety/summary/")
    }

    // MARK: - Agreements

    /// 동의 상태 조회
    /// GET /api/v1/tourist/agreements/
    static func travelerAgreements() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/agreements/")
    }

    /// 동의 상태 저장
    /// POST /api/v1/tourist/agreements/
    static func travelerAgreementsUpdate(
        termsAccepted: Bool,
        locationPermissionAccepted: Bool? = nil,
        notificationPermissionAccepted: Bool? = nil
    ) -> APIEndpoint {
        var body: [String: Any] = ["terms_accepted": termsAccepted]
        if let loc  = locationPermissionAccepted       { body["location_permission_accepted"]     = loc }
        if let notif = notificationPermissionAccepted  { body["notification_permission_accepted"] = notif }
        return APIEndpoint(path: "/api/v1/tourist/agreements/", method: .post, body: body)
    }

    // MARK: - Local Phrases

    /// 현지 표현 목록
    /// GET /api/v1/tourist/local-phrases/
    static func travelerLocalPhrases() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/local-phrases/")
    }

    // MARK: - Audio Guides

    /// 오디오 가이드 목록
    /// GET /api/v1/tourist/audio-guides/
    static func travelerAudioGuides() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/audio-guides/")
    }

    // MARK: - Feedback

    /// 만족도 조회
    /// GET /api/v1/tourist/feedback/
    static func travelerFeedback() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/feedback/")
    }

    /// 만족도 제출
    /// POST /api/v1/tourist/feedback/
    static func travelerFeedbackCreate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/feedback/", method: .post, body: body)
    }

    // MARK: - Nearby Tours

    /// 주변 관광지
    /// GET /api/v1/tourist/nearby-tours/
    static func travelerNearbyTours() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/tourist/nearby-tours/")
    }
}

// MARK: - Chat Endpoints (v1)
/// 실시간 채팅 API (WebSocket 연동)
///
/// REST: 방 목록·메시지 이력 조회 / 메시지 전송
/// WebSocket: ws://<host>/ws/chat/<room_id>/

extension APIEndpoint {

    /// 채팅방 목록
    /// GET /api/v1/chat/rooms/
    static func chatRooms() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/chat/rooms/")
    }

    /// 1:1 채팅방 열기
    /// POST /api/v1/chat/rooms/direct/
    static func chatRoomDirect(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/chat/rooms/direct/", method: .post, body: body)
    }

    /// 채팅방 단건 조회
    /// GET /api/v1/chat/rooms/{id}/
    static func chatRoom(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/chat/rooms/\(id)/")
    }

    /// 채팅방 마지막 읽은 메시지 저장
    /// POST /api/v1/chat/rooms/{id}/read/
    static func chatRoomRead(id: String, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/chat/rooms/\(id)/read/", method: .post, body: body)
    }

    /// 채팅방 메시지 이력 (cursor 기반)
    /// GET /api/v1/chat/rooms/{room_id}/messages/
    /// - Parameter cursor: 이 id보다 작은 메시지를 불러옵니다 (서버 파라미터명은 `before`)
    static func chatMessages(roomId: String, cursor: String? = nil) -> APIEndpoint {
        var queryItems: [URLQueryItem]? = nil
        if let cursor { queryItems = [URLQueryItem(name: "before", value: cursor)] }
        return APIEndpoint(path: "/api/v1/chat/rooms/\(roomId)/messages/", queryItems: queryItems)
    }

    /// 메시지 전송
    /// POST /api/v1/chat/rooms/{room_id}/messages/
    static func chatMessageSend(roomId: String, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/chat/rooms/\(roomId)/messages/", method: .post, body: body)
    }

    /// 메시지 삭제
    /// DELETE /api/v1/chat/rooms/{room_id}/messages/{message_id}/
    static func chatMessageDelete(roomId: String, messageId: String) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/chat/rooms/\(roomId)/messages/\(messageId)/", method: .delete)
    }
}
