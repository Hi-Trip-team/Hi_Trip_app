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
    func travelerLogin(username: String, password: String, tripId: Int?) -> Single<TravelerAuthResponseDTO>
    func logout() -> Single<TravelerLogoutResponseDTO>

    // MARK: - Profile
    func fetchMe() -> Single<TravelerMeDTO>

    func updateAgreements(
        termsAccepted: Bool,
        locationAccepted: Bool?,
        notificationAccepted: Bool?
    ) -> Single<TravelerAgreementDTO>

    func fetchHome() -> Single<TravelerHomeDTO>

    // MARK: - Schedules
    // MARK: - 개인 일정

    /// 개인 일정 목록
    func fetchPersonalSchedules() -> Single<[TravelerPersonalScheduleDTO]>

    /// 개인 일정 생성 — 응답의 overlapWarning으로 공용 일정 겹침을 알 수 있습니다.
    func createPersonalSchedule(_ request: TravelerPersonalScheduleRequest) -> Single<TravelerPersonalScheduleDTO>

    /// 개인 일정 수정
    func updatePersonalSchedule(id: Int, _ request: TravelerPersonalScheduleRequest) -> Single<TravelerPersonalScheduleDTO>

    /// 개인 일정 삭제
    func deletePersonalSchedule(id: Int) -> Single<Void>

    /// 현지 표현 — 여행 목적지 언어의 회화 목록
    func fetchLocalPhrases() -> Single<TravelerLocalPhrasesDTO>

    func fetchSchedules() -> Single<[TravelerScheduleDTO]>

    // MARK: - Notices
    func fetchNotices() -> Single<[TravelerNoticeDTO]>

    /// 공지 읽음 처리 — 홈의 빨간 점을 없애는 기준
    func markNoticeRead(id: Int) -> Single<Void>

    func fetchPopularSpots() -> Single<[TravelerSpotDTO]>

    // MARK: - 주변 스팟 / 안전

    /// 상황별 검색 — 카테고리는 서버 enum (restaurant/accessibility/pet/convenience/mart)
    func fetchNearbySpots(
        category: String,
        lat: Double,
        lng: Double,
        radius: Int?
    ) -> Single<[TravelerNearbySpotDTO]>

    /// 안전 요약 — 지도에 그릴 지오펜스(허용 반경)를 포함합니다
    func fetchSafetySummary() -> Single<TravelerSafetySummaryDTO>

    /// 위치 스냅샷 전송 — 이탈 판정은 서버가 합니다
    func sendLocationSnapshot(
        latitude: Double,
        longitude: Double,
        accuracyM: Double?
    ) -> Single<Void>

    func sendEmergencyRequest(
        message: String,
        latitude: String?,
        longitude: String?,
        accuracyM: String?
    ) -> Single<TravelerEmergencyRequestDTO>
}
