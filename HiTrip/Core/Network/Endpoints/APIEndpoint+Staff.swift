import Foundation

// MARK: - Staff (관리자/안내사) Endpoints
/// 관리자 전용 API 엔드포인트
///
/// 인증: **세션 쿠키(sessionid) + CSRF**
/// - 여행객(Bearer token)과 인증 방식이 다릅니다.
/// - 로그인 전 GET /api/v1/staff/auth/csrf/ 로 csrfToken을 받아
///   이후 쓰기 요청에 X-CSRFToken 헤더로 전달합니다.
///
/// 베이스: /api/v1/staff/, /api/v1/trips/, /api/monitoring/, /api/v1/notices/

extension APIEndpoint {

    // MARK: - Auth

    /// CSRF 토큰 발급 (로그인 전 최초 1회)
    /// GET /api/v1/staff/auth/csrf/
    static func staffCSRF() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/auth/csrf/")
    }

    /// 관리자 로그인 — 성공 시 sessionid 쿠키 발급
    /// POST /api/v1/staff/auth/login/
    static func staffLogin(username: String, password: String) -> APIEndpoint {
        APIEndpoint(
            path: "/api/v1/staff/auth/login/",
            method: .post,
            body: ["username": username, "password": password]
        )
    }

    /// 관리자 로그아웃
    /// POST /api/v1/staff/auth/logout/
    static func staffLogout() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/auth/logout/", method: .post)
    }

    /// 내 프로필
    /// GET /api/v1/staff/auth/me/
    static func staffMe() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/staff/auth/me/")
    }

    // MARK: - Trips (담당 여행)

    /// 담당 여행 목록 — 홈 진입 시 현재 여행 선택
    /// GET /api/v1/trips/
    static func staffTrips() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/trips/")
    }

    /// 여행 단건 — 심박/SpO₂ 임계값, geofence 기본값 포함
    /// GET /api/v1/trips/{id}/
    static func staffTrip(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/trips/\(id)/")
    }

    /// 여행 참가자 목록
    /// GET /api/v1/trips/{trip_pk}/participants/
    static func staffTripParticipants(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/trips/\(tripId)/participants/")
    }

    // MARK: - Schedules (전체일정 확인·수정)

    /// 일정 목록
    /// GET /api/trips/{trip_pk}/schedules/
    static func staffSchedules(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/schedules/")
    }

    /// 일정 생성
    /// POST /api/trips/{trip_pk}/schedules/
    static func staffScheduleCreate(tripId: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/schedules/", method: .post, body: body)
    }

    /// 일정 수정
    /// PATCH /api/trips/{trip_pk}/schedules/{id}/
    static func staffScheduleUpdate(tripId: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/schedules/\(id)/", method: .patch, body: body)
    }

    /// 일정 삭제
    /// DELETE /api/trips/{trip_pk}/schedules/{id}/
    static func staffScheduleDelete(tripId: Int, id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/schedules/\(id)/", method: .delete)
    }

    // MARK: - Monitoring (안전 관리 / 위치 확인 / 알림)

    /// 안전 현황 요약 — total·safe·warning·danger·stale·offline·unknown
    /// GET /api/monitoring/trips/{id}/summary/
    static func monitoringSummary(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/trips/\(tripId)/summary/")
    }

    /// 참가자별 최신 건강·위치 상태 — 안전관리 테이블 본문
    /// GET /api/monitoring/trips/{id}/latest/
    static func monitoringLatest(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/trips/\(tripId)/latest/")
    }

    /// 경보 이력 — 알림 센터
    /// GET /api/monitoring/trips/{id}/alerts/
    static func monitoringAlerts(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/trips/\(tripId)/alerts/")
    }

    /// 사고 확인 처리 — 알림 센터 "확인" 버튼
    /// POST /api/monitoring/trips/{id}/incidents/{incident_id}/acknowledge/
    static func monitoringIncidentAcknowledge(tripId: Int, incidentId: Int) -> APIEndpoint {
        APIEndpoint(
            path: "/api/monitoring/trips/\(tripId)/incidents/\(incidentId)/acknowledge/",
            method: .post
        )
    }

    // MARK: - Notices (공지 설정)

    /// 공지 목록
    /// GET /api/v1/notices/
    static func staffNotices() -> APIEndpoint {
        APIEndpoint(path: "/api/v1/notices/")
    }

    /// 공지 생성
    /// POST /api/v1/notices/
    static func staffNoticeCreate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/notices/", method: .post, body: body)
    }

    /// 공지 수정
    /// PATCH /api/v1/notices/{id}/
    static func staffNoticeUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/notices/\(id)/", method: .patch, body: body)
    }

    /// 공지 삭제
    /// DELETE /api/v1/notices/{id}/
    static func staffNoticeDelete(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/notices/\(id)/", method: .delete)
    }

    /// 공지 게시 — 토글 ON
    /// POST /api/v1/notices/{id}/publish/
    static func staffNoticePublish(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/notices/\(id)/publish/", method: .post)
    }

    /// 공지 보관 — 토글 OFF
    /// POST /api/v1/notices/{id}/archive/
    static func staffNoticeArchive(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/v1/notices/\(id)/archive/", method: .post)
    }

    // MARK: - Geofences (지도 범위 설정)

    /// 일차별 안전 구역 목록
    /// GET /api/trips/{trip_pk}/geofences/
    static func staffGeofences(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/geofences/")
    }

    /// 안전 구역 생성
    /// POST /api/trips/{trip_pk}/geofences/
    static func staffGeofenceCreate(tripId: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/geofences/", method: .post, body: body)
    }

    /// 안전 구역 수정 — 낙관적 잠금: body에 expected_revision 필수
    /// PATCH /api/trips/{trip_pk}/geofences/{id}/
    static func staffGeofenceUpdate(tripId: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/geofences/\(id)/", method: .patch, body: body)
    }

    /// 전일차 설정 복사
    /// POST /api/trips/{trip_pk}/geofences/copy-previous/
    static func staffGeofenceCopyPrevious(tripId: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripId)/geofences/copy-previous/", method: .post, body: body)
    }

    // MARK: - 문의 스레드 (고객 관리)

    // MARK: - 긴급 요청

}
