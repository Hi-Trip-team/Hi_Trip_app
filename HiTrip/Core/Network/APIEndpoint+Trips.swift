import Foundation

// MARK: - Trip Endpoints
/// 여행 관련 API 엔드포인트
///
/// 백엔드: /api/trips/
/// Fern Docs 기준 request/response 매핑

extension APIEndpoint {

    // MARK: - Trips CRUD

    /// 여행 목록 조회
    /// - GET /api/trips/
    static func tripsList() -> APIEndpoint {
        APIEndpoint(path: "/api/trips/")
    }

    /// 여행 생성
    /// - POST /api/trips/
    static func tripsCreate(
        title: String,
        startDate: String,
        endDate: String,
        destination: String,
        participantCount: Int? = nil
    ) -> APIEndpoint {
        var body: [String: Any] = [
            "title": title,
            "start_date": startDate,
            "end_date": endDate,
            "destination": destination
        ]
        if let count = participantCount {
            body["participant_count"] = count
        }
        return APIEndpoint(path: "/api/trips/", method: .post, body: body)
    }

    /// 여행 상세 조회
    /// - GET /api/trips/:id/
    static func tripsRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(id)/")
    }

    /// 여행 수정 (전체)
    /// - PUT /api/trips/:id/
    static func tripsUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(id)/", method: .put, body: body)
    }

    /// 여행 부분 수정
    /// - PATCH /api/trips/:id/
    static func tripsPartialUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(id)/", method: .patch, body: body)
    }

    /// 여행 삭제
    /// - DELETE /api/trips/:id/
    static func tripsDestroy(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(id)/", method: .delete)
    }

    /// 매니저 배정
    /// - POST /api/trips/:id/assign-manager/
    static func tripsAssignManager(tripId: Int, managerId: Int) -> APIEndpoint {
        APIEndpoint(
            path: "/api/trips/\(tripId)/assign-manager/",
            method: .post,
            body: ["manager_id": managerId]
        )
    }

    // MARK: - Participants

    /// 참여자 목록 조회
    /// - GET /api/trips/:trip_pk/participants/
    static func participantsList(tripPk: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/trips/\(tripPk)/participants/")
    }

    /// 참여자 추가
    /// - POST /api/trips/:trip_pk/participants/
    static func participantsAdd(tripPk: Int, travelerId: Int) -> APIEndpoint {
        APIEndpoint(
            path: "/api/trips/\(tripPk)/participants/",
            method: .post,
            body: ["traveler_id": travelerId]
        )
    }

    /// 참여자 삭제
    /// - DELETE /api/trips/:trip_pk/participants/:id/
    static func participantsDestroy(tripPk: Int, id: Int) -> APIEndpoint {
        APIEndpoint(
            path: "/api/trips/\(tripPk)/participants/\(id)/",
            method: .delete
        )
    }
}
