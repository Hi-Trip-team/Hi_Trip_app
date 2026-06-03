import Foundation

// MARK: - Schedule Endpoints
/// 일정 관련 API 엔드포인트
///
/// 백엔드: /api/trips/:trip_pk/schedules/
/// 여행사가 등록한 공식 일정(타임라인) CRUD

extension APIEndpoint {

    // MARK: - Schedules CRUD

    /// 일정 목록 조회
    /// - GET /api/trips/:trip_pk/schedules/
    static func schedulesList(tripPk: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripPk)/schedules/")
    }

    /// 일정 생성
    /// - POST /api/trips/:trip_pk/schedules/
    static func schedulesCreate(tripPk: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(
            path: "/api/trips/\(tripPk)/schedules/",
            method: .post,
            body: body
        )
    }

    /// 일정 상세 조회
    /// - GET /api/trips/:trip_pk/schedules/:id/
    static func schedulesRetrieve(tripPk: Int, id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripPk)/schedules/\(id)/")
    }

    /// 일정 수정 (전체)
    /// - PUT /api/trips/:trip_pk/schedules/:id/
    static func schedulesUpdate(tripPk: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(
            path: "/api/trips/\(tripPk)/schedules/\(id)/",
            method: .put,
            body: body
        )
    }

    /// 일정 부분 수정
    /// - PATCH /api/trips/:trip_pk/schedules/:id/
    static func schedulesPartialUpdate(tripPk: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(
            path: "/api/trips/\(tripPk)/schedules/\(id)/",
            method: .patch,
            body: body
        )
    }

    /// 일정 삭제
    /// - DELETE /api/trips/:trip_pk/schedules/:id/
    static func schedulesDestroy(tripPk: Int, id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripPk)/schedules/\(id)/", method: .delete)
    }

    /// 일정 재조정 (AI)
    /// - POST /api/trips/:trip_pk/schedules/rebalance-day/
    static func schedulesRebalanceDay(tripPk: Int, day: Int) -> APIEndpoint {
        APIEndpoint(
            path: "/api/trips/\(tripPk)/schedules/rebalance-day/",
            method: .post,
            body: ["day": day]
        )
    }
}
