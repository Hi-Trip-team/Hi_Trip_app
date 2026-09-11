import Foundation
import RxSwift

// MARK: - TravelerRepository
/// TravelerRepositoryProtocol 구현체
///
/// 모든 /api/traveler/* 엔드포인트 호출을 NetworkService에 위임.
/// ViewModel/Store는 이 클래스를 직접 알 필요 없이 Protocol만 참조.

final class TravelerRepository: TravelerRepositoryProtocol {

    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    // MARK: - Auth

    func travelerLogin(username: String, password: String, tripId: Int? = nil) -> Single<TravelerAuthResponseDTO> {
        networkService.request(
            .travelerLogin(username: username, password: password, tripId: tripId),
            type: TravelerAuthResponseDTO.self
        )
    }

    func logout() -> Single<TravelerLogoutResponseDTO> {
        networkService.request(.travelerLogout(), type: TravelerLogoutResponseDTO.self)
    }

    // MARK: - Profile

    func fetchMe() -> Single<TravelerMeDTO> {
        networkService.request(.travelerMe(), type: TravelerMeDTO.self)
    }

    // MARK: - Agreements

    func updateAgreements(
        termsAccepted: Bool,
        locationAccepted: Bool?,
        notificationAccepted: Bool?
    ) -> Single<TravelerAgreementDTO> {
        networkService.request(
            .travelerAgreementsUpdate(
                termsAccepted: termsAccepted,
                locationPermissionAccepted: locationAccepted,
                notificationPermissionAccepted: notificationAccepted
            ),
            type: TravelerAgreementDTO.self
        )
    }

    // MARK: - Trip & Home

    func fetchHome() -> Single<TravelerHomeDTO> {
        networkService.request(.travelerHome(), type: TravelerHomeDTO.self)
    }

    // MARK: - Schedules

    // MARK: - 개인 일정

    func fetchPersonalSchedules() -> Single<[TravelerPersonalScheduleDTO]> {
        networkService.request(.travelerPersonalSchedules(), type: [TravelerPersonalScheduleDTO].self)
    }

    func createPersonalSchedule(_ request: TravelerPersonalScheduleRequest) -> Single<TravelerPersonalScheduleDTO> {
        networkService.request(
            .travelerPersonalScheduleCreate(body: request.asDictionary()),
            type: TravelerPersonalScheduleDTO.self
        )
    }

    func updatePersonalSchedule(id: Int, _ request: TravelerPersonalScheduleRequest) -> Single<TravelerPersonalScheduleDTO> {
        networkService.request(
            .travelerPersonalScheduleUpdate(id: id, body: request.asDictionary()),
            type: TravelerPersonalScheduleDTO.self
        )
    }

    func deletePersonalSchedule(id: Int) -> Single<Void> {
        networkService.request(.travelerPersonalScheduleDelete(id: id), type: EmptyResponse.self)
            .map { _ in () }
    }

    func fetchLocalPhrases() -> Single<TravelerLocalPhrasesDTO> {
        networkService.request(.travelerLocalPhrases(), type: TravelerLocalPhrasesDTO.self)
    }

    func fetchSchedules() -> Single<[TravelerScheduleDTO]> {
        networkService.request(.travelerSchedules(), type: [TravelerScheduleDTO].self)
    }

    // MARK: - Notices

    func fetchNotices() -> Single<[TravelerNoticeDTO]> {
        networkService.request(.travelerNotices(), type: [TravelerNoticeDTO].self)
    }

    func markNoticeRead(id: Int) -> Single<Void> {
        networkService.request(.travelerNoticeRead(id: id), type: EmptyResponse.self)
            .map { _ in () }
    }

    // MARK: - Checklist

    // MARK: - Spots

    func fetchPopularSpots() -> Single<[TravelerSpotDTO]> {
        networkService.request(.travelerPopularSpots(), type: [TravelerSpotDTO].self)
    }

    // MARK: - Map & Manager

    // MARK: - 주변 스팟 / 안전

    func fetchNearbySpots(
        category: String,
        lat: Double,
        lng: Double,
        radius: Int?
    ) -> Single<[TravelerNearbySpotDTO]> {
        networkService.request(
            .travelerNearbySpots(category: category, lat: lat, lng: lng, radius: radius),
            type: TravelerNearbySpotsResponseDTO.self
        )
        .map(\.results)
    }

    func fetchSafetySummary() -> Single<TravelerSafetySummaryDTO> {
        networkService.request(.travelerSafetySummary(), type: TravelerSafetySummaryDTO.self)
    }

    func sendLocationSnapshot(
        latitude: Double,
        longitude: Double,
        accuracyM: Double?
    ) -> Single<Void> {
        let iso = ISO8601DateFormatter()
        var body: [String: Any] = [
            "latitude": String(format: "%.6f", latitude),
            "longitude": String(format: "%.6f", longitude),
            "measured_at": iso.string(from: Date()),
        ]
        if let accuracyM { body["accuracy_m"] = String(format: "%.2f", accuracyM) }

        return networkService.request(.travelerSafetyLocation(body: body), type: EmptyResponse.self)
            .map { _ in () }
    }

    func sendEmergencyRequest(
        message: String,
        latitude: String?,
        longitude: String?,
        accuracyM: String?
    ) -> Single<TravelerEmergencyRequestDTO> {
        networkService.request(
            .travelerEmergencyRequest(
                message: message,
                latitude: latitude,
                longitude: longitude,
                accuracyM: accuracyM
            ),
            type: TravelerEmergencyRequestDTO.self
        )
    }
}
