import Foundation
import RxSwift

// MARK: - TravelerRepositoryProtocol
/// 여행객 전용 API(/api/traveler/*) 접근 인터페이스
///
/// 역할 범위:
///   - 프로필 / 여행 / 일정 / 공지 / 체크리스트 / 스팟 / 동의 / 인증
///
/// 메시지(채팅)는 스레드 기반의 별도 패턴이므로 ChatRepositoryProtocol로 분리.
/// 로컬 긴급 연락처는 EmergencyRepositoryProtocol로 분리.

protocol TravelerRepositoryProtocol {

    // MARK: - Auth
    func travelerLogin(phone: String, birthDate: String, inviteCode: String) -> Single<TravelerAuthResponseDTO>
    func logout() -> Single<TravelerLogoutResponseDTO>

    // MARK: - Profile
    func fetchMe() -> Single<TravelerMeDTO>
    func updateMe(_ request: TravelerProfileUpdateRequest) -> Single<TravelerPublicDTO>

    // MARK: - Agreements
    func fetchAgreements() -> Single<TravelerAgreementDTO>
    func updateAgreements(
        termsAccepted: Bool,
        locationAccepted: Bool?,
        notificationAccepted: Bool?
    ) -> Single<TravelerAgreementDTO>

    // MARK: - Trip & Home
    func fetchTrip() -> Single<TravelerTripDTO>
    func fetchHome() -> Single<TravelerHomeDTO>
    func fetchCalendar() -> Single<TravelerCalendarDTO>

    // MARK: - Schedules
    func fetchSchedules() -> Single<[TravelerScheduleDTO]>
    func fetchSchedule(id: Int) -> Single<TravelerScheduleDTO>

    // MARK: - Notices
    func fetchNotices() -> Single<[TravelerNoticeDTO]>
    func fetchNotice(id: Int) -> Single<TravelerNoticeDTO>

    // MARK: - Checklist
    func fetchChecklists() -> Single<[TravelerChecklistItemDTO]>
    func toggleChecklist(itemId: Int, isChecked: Bool) -> Single<TravelerChecklistItemDTO>

    // MARK: - Spots
    func fetchRecommendedSpots() -> Single<[TravelerSpotDTO]>
    func fetchPopularSpots() -> Single<[TravelerSpotDTO]>
    func fetchSpot(id: Int) -> Single<TravelerSpotDTO>

    // MARK: - Map & Manager
    func fetchMapPlaces() -> Single<[TravelerMapPlaceDTO]>
    func fetchManagerContact() -> Single<TravelerManagerContactDTO>
    func sendEmergencyRequest(
        message: String,
        latitude: String?,
        longitude: String?,
        accuracyM: String?
    ) -> Single<TravelerEmergencyRequestDTO>
}
