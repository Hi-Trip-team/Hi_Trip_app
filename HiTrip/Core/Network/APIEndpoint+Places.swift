import Foundation

// MARK: - Places Endpoints
/// 장소 관련 API 엔드포인트
///
/// 백엔드: /api/places/, /api/recommendations/, /api/categories/

extension APIEndpoint {

    // MARK: - Places

    /// 장소 목록 조회
    /// - GET /api/places/
    static func placesList() -> APIEndpoint {
        APIEndpoint(path: "/api/places/")
    }

    /// 장소 상세 조회
    /// - GET /api/places/:id/
    static func placesRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(id)/")
    }

    /// 장소 생성
    /// - POST /api/places/
    static func placesCreate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/", method: .post, body: body)
    }

    /// 장소 수정
    /// - PUT /api/places/:id/
    static func placesUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(id)/", method: .put, body: body)
    }

    /// 장소 부분 수정
    /// - PATCH /api/places/:id/
    static func placesPartialUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(id)/", method: .patch, body: body)
    }

    /// 장소 삭제
    /// - DELETE /api/places/:id/
    static func placesDestroy(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(id)/", method: .delete)
    }

    // MARK: - Place Coordinators

    /// 장소 담당자 목록 조회
    /// - GET /api/places/:place_pk/coordinators/
    static func coordinatorsList(placePk: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/coordinators/")
    }

    /// 장소 담당자 생성
    /// - POST /api/places/:place_pk/coordinators/
    static func coordinatorsCreate(placePk: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/coordinators/", method: .post, body: body)
    }

    /// 장소 담당자 상세 조회
    /// - GET /api/places/:place_pk/coordinators/:id/
    static func coordinatorsRetrieve(placePk: Int, id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/coordinators/\(id)/")
    }

    /// 장소 담당자 수정
    /// - PUT /api/places/:place_pk/coordinators/:id/
    static func coordinatorsUpdate(placePk: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/coordinators/\(id)/", method: .put, body: body)
    }

    /// 장소 담당자 부분 수정
    /// - PATCH /api/places/:place_pk/coordinators/:id/
    static func coordinatorsPartialUpdate(placePk: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/coordinators/\(id)/", method: .patch, body: body)
    }

    /// 장소 담당자 삭제
    /// - DELETE /api/places/:place_pk/coordinators/:id/
    static func coordinatorsDestroy(placePk: Int, id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/coordinators/\(id)/", method: .delete)
    }

    // MARK: - Place Expenses (선택 경비)

    /// 선택 경비 목록 조회
    /// - GET /api/places/:place_pk/expenses/
    static func expensesList(placePk: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/expenses/")
    }

    /// 선택 경비 생성
    /// - POST /api/places/:place_pk/expenses/
    static func expensesCreate(placePk: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/expenses/", method: .post, body: body)
    }

    /// 선택 경비 상세 조회
    /// - GET /api/places/:place_pk/expenses/:id/
    static func expensesRetrieve(placePk: Int, id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/expenses/\(id)/")
    }

    /// 선택 경비 수정
    /// - PUT /api/places/:place_pk/expenses/:id/
    static func expensesUpdate(placePk: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/expenses/\(id)/", method: .put, body: body)
    }

    /// 선택 경비 부분 수정
    /// - PATCH /api/places/:place_pk/expenses/:id/
    static func expensesPartialUpdate(placePk: Int, id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/expenses/\(id)/", method: .patch, body: body)
    }

    /// 선택 경비 삭제
    /// - DELETE /api/places/:place_pk/expenses/:id/
    static func expensesDestroy(placePk: Int, id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/places/\(placePk)/expenses/\(id)/", method: .delete)
    }

    /// 선택 경비 합계 계산
    /// - POST /api/places/:place_pk/expenses/calculate/
    static func expensesCalculate(placePk: Int, selectedIds: [Int]) -> APIEndpoint {
        APIEndpoint(
            path: "/api/places/\(placePk)/expenses/calculate/",
            method: .post,
            body: ["selected_expense_ids": selectedIds]
        )
    }

    // MARK: - Recommendations

    /// AI 추천 장소 목록
    /// - GET /api/recommendations/
    static func recommendationsList() -> APIEndpoint {
        APIEndpoint(path: "/api/recommendations/")
    }

    // MARK: - Categories

    /// 카테고리 목록 조회
    /// - GET /api/categories/
    static func categoriesList() -> APIEndpoint {
        APIEndpoint(path: "/api/categories/")
    }

    /// 카테고리 상세 조회
    /// - GET /api/categories/:id/
    static func categoriesRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/categories/\(id)/")
    }

    // MARK: - Locations

    /// 장소 위치 데이터
    /// - GET /api/locations/places/
    static func locationPlaces() -> APIEndpoint {
        APIEndpoint(path: "/api/locations/places/")
    }

    /// 카테고리 위치 데이터
    /// - GET /api/locations/categories/
    static func locationCategories() -> APIEndpoint {
        APIEndpoint(path: "/api/locations/categories/")
    }

    // MARK: - Place Recommendations

    /// 고정 카테고리 추천 장소
    /// - POST /api/place-recommendations/fixed-top/
    static func placeRecommendationsFixedTop(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/place-recommendations/fixed-top/", method: .post, body: body)
    }

    /// 대안 추천 장소
    /// - POST /api/place-recommendations/alternatives/
    static func placeRecommendationsAlternatives(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/place-recommendations/alternatives/", method: .post, body: body)
    }

    // MARK: - Locations CRUD

    /// 위치 장소 생성
    /// - POST /api/locations/places/
    static func locationPlacesCreate(body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/locations/places/", method: .post, body: body)
    }

    /// 위치 장소 상세 조회
    /// - GET /api/locations/places/:id/
    static func locationPlacesRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/locations/places/\(id)/")
    }

    /// 위치 장소 수정
    /// - PUT /api/locations/places/:id/
    static func locationPlacesUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/locations/places/\(id)/", method: .put, body: body)
    }

    /// 위치 장소 부분 수정
    /// - PATCH /api/locations/places/:id/
    static func locationPlacesPartialUpdate(id: Int, body: [String: Any]) -> APIEndpoint {
        APIEndpoint(path: "/api/locations/places/\(id)/", method: .patch, body: body)
    }

    /// 위치 장소 삭제
    /// - DELETE /api/locations/places/:id/
    static func locationPlacesDestroy(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/locations/places/\(id)/", method: .delete)
    }

    /// 카테고리 위치 상세 조회
    /// - GET /api/locations/categories/:id/
    static func locationCategoriesRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/locations/categories/\(id)/")
    }

    // MARK: - Coordinator Roles

    /// 담당자 역할 목록 조회
    /// - GET /api/coordinator-roles/
    static func coordinatorRolesList() -> APIEndpoint {
        APIEndpoint(path: "/api/coordinator-roles/")
    }

    /// 담당자 역할 상세 조회
    /// - GET /api/coordinator-roles/:id/
    static func coordinatorRolesRetrieve(id: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/coordinator-roles/\(id)/")
    }

    // MARK: - Monitoring

    /// 모니터링 알림 (전체)
    /// - GET /api/monitoring/alerts/
    static func monitoringAlerts() -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/alerts/")
    }

    /// 여행별 모니터링 알림
    /// - GET /api/monitoring/trips/:id/alerts/
    static func monitoringTripAlerts(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/trips/\(tripId)/alerts/")
    }

    /// 데모 모니터링 데이터 생성
    /// - POST /api/monitoring/trips/:id/generate-demo/
    static func monitoringGenerateDemo(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/trips/\(tripId)/generate-demo/", method: .post)
    }

    /// 최신 참가자 건강/위치 스냅샷
    /// - GET /api/monitoring/trips/:id/latest/
    static func monitoringLatest(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/trips/\(tripId)/latest/")
    }

    /// 여행 모니터링 요약 (전체, 안전, 위험 카운트)
    /// - GET /api/monitoring/trips/:id/summary/
    static func monitoringSummary(tripId: Int) -> APIEndpoint {
        APIEndpoint(path: "/api/monitoring/trips/\(tripId)/summary/")
    }

    // MARK: - Health Check

    /// 서비스 헬스 체크
    /// - GET /api/health/
    static func healthCheck() -> APIEndpoint {
        APIEndpoint(path: "/api/health/")
    }
}
