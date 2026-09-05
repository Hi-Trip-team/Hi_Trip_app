import Foundation
import RxSwift

// MARK: - StaffRepositoryProtocol

protocol StaffRepositoryProtocol {
    // Auth
    func fetchCSRFToken() -> Single<CSRFTokenDTO>
    func login(username: String, password: String) -> Single<StaffProfileDTO>
    func logout() -> Single<EmptyResponse>
    func fetchMe() -> Single<StaffProfileDTO>

    // 담당 여행
    func fetchTrips() -> Single<[StaffTripDTO]>
    func fetchTrip(id: Int) -> Single<StaffTripDTO>

    // 일정
    func fetchSchedules(tripId: Int) -> Single<[StaffScheduleDTO]>

    // 안전 관리
    func fetchSafetySummary(tripId: Int) -> Single<MonitoringSummaryDTO>
    func fetchParticipantsLatest(tripId: Int) -> Single<[ParticipantLatestDTO]>
    func fetchAlerts(tripId: Int) -> Single<[MonitoringAlertDTO]>
    func acknowledgeIncident(tripId: Int, incidentId: Int) -> Single<EmptyResponse>

    // 공지
    func fetchNotices() -> Single<[StaffNoticeDTO]>
    func createNotice(title: String, content: String, tripId: Int?) -> Single<StaffNoticeDTO>
    func publishNotice(id: Int) -> Single<StaffNoticeDTO>
    func archiveNotice(id: Int) -> Single<StaffNoticeDTO>

    // 안전 구역
    func fetchGeofences(tripId: Int) -> Single<[GeofenceDTO]>
    func updateGeofence(
        tripId: Int, id: Int,
        centerLat: String, centerLng: String, radiusKm: Int,
        expectedRevision: Int
    ) -> Single<GeofenceDTO>
}

// MARK: - StaffRepository
/// 관리자 API 구현체 — 세션 쿠키 + CSRF 인증
///
/// 호출 순서: fetchCSRFToken() → login() → 이후 모든 요청은 sessionid 쿠키로 인증

final class StaffRepository: StaffRepositoryProtocol {

    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    // MARK: - Auth

    func fetchCSRFToken() -> Single<CSRFTokenDTO> {
        networkService.request(.staffCSRF(), type: CSRFTokenDTO.self)
            .do(onSuccess: { NetworkService.csrfToken = $0.csrfToken })
    }

    /// CSRF 발급 → 로그인 순으로 체이닝
    func login(username: String, password: String) -> Single<StaffProfileDTO> {
        fetchCSRFToken()
            .flatMap { [networkService] _ in
                networkService.request(
                    .staffLogin(username: username, password: password),
                    type: StaffProfileDTO.self
                )
            }
    }

    func logout() -> Single<EmptyResponse> {
        networkService.request(.staffLogout(), type: EmptyResponse.self)
            .do(onSuccess: { _ in NetworkService.csrfToken = nil })
    }

    func fetchMe() -> Single<StaffProfileDTO> {
        networkService.request(.staffMe(), type: StaffProfileDTO.self)
    }

    // MARK: - 담당 여행

    func fetchTrips() -> Single<[StaffTripDTO]> {
        networkService.request(.staffTrips(), type: [StaffTripDTO].self)
    }

    func fetchTrip(id: Int) -> Single<StaffTripDTO> {
        networkService.request(.staffTrip(id: id), type: StaffTripDTO.self)
    }

    // MARK: - 일정

    func fetchSchedules(tripId: Int) -> Single<[StaffScheduleDTO]> {
        networkService.request(.staffSchedules(tripId: tripId), type: [StaffScheduleDTO].self)
    }

    // MARK: - 안전 관리

    func fetchSafetySummary(tripId: Int) -> Single<MonitoringSummaryDTO> {
        networkService.request(.monitoringSummary(tripId: tripId), type: MonitoringSummaryDTO.self)
    }

    func fetchParticipantsLatest(tripId: Int) -> Single<[ParticipantLatestDTO]> {
        networkService.request(.monitoringLatest(tripId: tripId), type: [ParticipantLatestDTO].self)
    }

    func fetchAlerts(tripId: Int) -> Single<[MonitoringAlertDTO]> {
        networkService.request(.monitoringAlerts(tripId: tripId), type: [MonitoringAlertDTO].self)
    }

    func acknowledgeIncident(tripId: Int, incidentId: Int) -> Single<EmptyResponse> {
        networkService.request(
            .monitoringIncidentAcknowledge(tripId: tripId, incidentId: incidentId),
            type: EmptyResponse.self
        )
    }

    // MARK: - 공지

    func fetchNotices() -> Single<[StaffNoticeDTO]> {
        networkService.request(.staffNotices(), type: [StaffNoticeDTO].self)
    }

    func createNotice(title: String, content: String, tripId: Int?) -> Single<StaffNoticeDTO> {
        var body: [String: Any] = ["title": title, "content": content]
        if let tripId {
            body["scope"] = "trip"
            body["trip"] = tripId
        } else {
            body["scope"] = "global"
        }
        return networkService.request(.staffNoticeCreate(body: body), type: StaffNoticeDTO.self)
    }

    func publishNotice(id: Int) -> Single<StaffNoticeDTO> {
        networkService.request(.staffNoticePublish(id: id), type: StaffNoticeDTO.self)
    }

    func archiveNotice(id: Int) -> Single<StaffNoticeDTO> {
        networkService.request(.staffNoticeArchive(id: id), type: StaffNoticeDTO.self)
    }

    // MARK: - 안전 구역

    func fetchGeofences(tripId: Int) -> Single<[GeofenceDTO]> {
        networkService.request(.staffGeofences(tripId: tripId), type: [GeofenceDTO].self)
    }

    /// expected_revision을 함께 보내 낙관적 잠금 충돌을 서버가 감지하게 합니다.
    func updateGeofence(
        tripId: Int, id: Int,
        centerLat: String, centerLng: String, radiusKm: Int,
        expectedRevision: Int
    ) -> Single<GeofenceDTO> {
        networkService.request(
            .staffGeofenceUpdate(tripId: tripId, id: id, body: [
                "center_lat": centerLat,
                "center_lng": centerLng,
                "radius_km": radiusKm,
                "expected_revision": expectedRevision,
            ]),
            type: GeofenceDTO.self
        )
    }
}
