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

    func travelerLogin(phone: String, birthDate: String, inviteCode: String) -> Single<TravelerAuthResponseDTO> {
        networkService.request(
            .travelerLogin(phone: phone, birthDate: birthDate, inviteCode: inviteCode),
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

    func updateMe(_ request: TravelerProfileUpdateRequest) -> Single<TravelerPublicDTO> {
        networkService.request(.travelerMeUpdate(body: request.asDictionary()), type: TravelerPublicDTO.self)
    }

    // MARK: - Agreements

    func fetchAgreements() -> Single<TravelerAgreementDTO> {
        networkService.request(.travelerAgreements(), type: TravelerAgreementDTO.self)
    }

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

    func fetchTrip() -> Single<TravelerTripDTO> {
        networkService.request(.travelerTrip(), type: TravelerTripDTO.self)
    }

    func fetchHome() -> Single<TravelerHomeDTO> {
        networkService.request(.travelerHome(), type: TravelerHomeDTO.self)
    }

    func fetchCalendar() -> Single<TravelerCalendarDTO> {
        networkService.request(.travelerCalendar(), type: TravelerCalendarDTO.self)
    }

    // MARK: - Schedules

    func fetchSchedules() -> Single<[TravelerScheduleDTO]> {
        networkService.request(.travelerSchedules(), type: [TravelerScheduleDTO].self)
    }

    func fetchSchedule(id: Int) -> Single<TravelerScheduleDTO> {
        networkService.request(.travelerSchedule(id: id), type: TravelerScheduleDTO.self)
    }

    // MARK: - Notices

    func fetchNotices() -> Single<[TravelerNoticeDTO]> {
        networkService.request(.travelerNotices(), type: [TravelerNoticeDTO].self)
    }

    func fetchNotice(id: Int) -> Single<TravelerNoticeDTO> {
        networkService.request(.travelerNotice(id: id), type: TravelerNoticeDTO.self)
    }

    // MARK: - Checklist

    func fetchChecklists() -> Single<[TravelerChecklistItemDTO]> {
        networkService.request(.travelerChecklists(), type: [TravelerChecklistItemDTO].self)
    }

    func toggleChecklist(itemId: Int, isChecked: Bool) -> Single<TravelerChecklistItemDTO> {
        networkService.request(
            .travelerChecklistUpdate(itemId: itemId, isChecked: isChecked),
            type: TravelerChecklistItemDTO.self
        )
    }

    // MARK: - Spots

    func fetchRecommendedSpots() -> Single<[TravelerSpotDTO]> {
        networkService.request(.travelerRecommendedSpots(), type: [TravelerSpotDTO].self)
    }

    func fetchPopularSpots() -> Single<[TravelerSpotDTO]> {
        networkService.request(.travelerPopularSpots(), type: [TravelerSpotDTO].self)
    }

    func fetchSpot(id: Int) -> Single<TravelerSpotDTO> {
        networkService.request(.travelerSpot(id: id), type: TravelerSpotDTO.self)
    }

    // MARK: - Map & Manager

    func fetchMapPlaces() -> Single<[TravelerMapPlaceDTO]> {
        networkService.request(.travelerMapPlaces(), type: [TravelerMapPlaceDTO].self)
    }

    func fetchManagerContact() -> Single<TravelerManagerContactDTO> {
        networkService.request(.travelerManagerContact(), type: TravelerManagerContactDTO.self)
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
