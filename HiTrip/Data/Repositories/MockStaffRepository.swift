import Foundation
import RxSwift

// MARK: - MockStaffRepository
/// 서버 없이 안내사 화면을 확인하기 위한 목 구현체
///
/// 여행객 목과 같은 기준으로 오늘 날짜에 맞춰 값을 만듭니다.
/// 안전 상태는 화면에서 위험·경고·이탈·정상이 모두 보이도록 섞어 둡니다.

final class MockStaffRepository: StaffRepositoryProtocol {

    // MARK: - 기준 날짜

    /// 여행 시작일 — 어제 (오늘이 2일차)
    private static var startDate: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86_400)
    }

    private static func ymd(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func isoNow(minutesAgo: Int = 0) -> String {
        let f = ISO8601DateFormatter()
        return f.string(from: Date().addingTimeInterval(-Double(minutesAgo) * 60))
    }

    // MARK: - Auth

    func fetchCSRFToken() -> Single<CSRFTokenDTO> { .just(CSRFTokenDTO(csrfToken: "mock")) }

    func login(username: String, password: String) -> Single<StaffProfileDTO> { fetchMe() }

    func logout() -> Single<EmptyResponse> { .just(EmptyResponse()) }

    func fetchMe() -> Single<StaffProfileDTO> {
        .just(StaffProfileDTO(
            id: 1, username: "demo_manager1", email: "guide@hitrip.kr", phone: "010-1234-5678",
            travelAgencyName: "하이트립 투어", fullNameKr: "김안내", fullNameEn: "Kim Annae",
            roleDisplay: "안내사", isActive: true, isApproved: true
        ))
    }

    // MARK: - 담당 여행

    func fetchTrips() -> Single<[StaffTripDTO]> { .just([Self.mockTrip]) }

    func fetchTrip(id: Int) -> Single<StaffTripDTO> { .just(Self.mockTrip) }

    private static var mockTrip: StaffTripDTO {
        StaffTripDTO(
            id: 1,
            title: "뉴진스 바다여행",
            destination: "제주",
            startDate: ymd(startDate),
            endDate: ymd(startDate.addingTimeInterval(86_400 * 3)),
            managerName: "김안내",
            participantCount: 12,
            heartRateMin: 50, heartRateMax: 110, spo2Min: "95",
            geofenceCenterLat: "33.499621", geofenceCenterLng: "126.531188", geofenceRadiusKm: "3"
        )
    }

    func fetchParticipants(tripId: Int) -> Single<[TripParticipantDTO]> {
        .just([
            participantProfile(1, "김여행", "010-1111-2222", "대한민국", "M12345678"),
            participantProfile(2, "이관광", "010-3333-4444", "대한민국", "M23456789"),
            participantProfile(3, "박구경", nil, "일본", "TK9988776"),
            participantProfile(4, "최유람", "010-5555-6666", "대한민국", "M34567890"),
            participantProfile(5, "정나들", "010-7777-8888", "미국", "US4455667"),
        ])
    }

    private func participantProfile(
        _ id: Int, _ name: String, _ phone: String?, _ country: String, _ passport: String
    ) -> TripParticipantDTO {
        TripParticipantDTO(
            id: id, trip: 1,
            traveler: TravelerDetailDTO(
                id: id, fullNameKr: name, phone: phone,
                country: country, passportNumber: passport
            ),
            joinedDate: Self.isoNow(minutesAgo: 3000)
        )
    }

    // MARK: - 일정

    func fetchSchedules(tripId: Int) -> Single<[StaffScheduleDTO]> {
        .just([
            schedule(id: 1, day: 1, "09:00", "10:30", "공항 집결", "미팅 및 이동"),
            schedule(id: 2, day: 1, "12:00", "13:30", "흑돼지 명가", "점심 식사"),
            schedule(id: 3, day: 2, "08:00", "09:00", "호텔 식당", "조식"),
            schedule(id: 4, day: 2, "15:00", "16:00", "숙소로 이동", "버스 이동"),
            schedule(id: 5, day: 2, "16:00", "23:00", "자유시간", nil),
            schedule(id: 6, day: 3, "10:00", "12:00", "성산일출봉", "트래킹"),
        ])
    }

    private func schedule(
        id: Int, day: Int, _ start: String, _ end: String,
        _ place: String, _ content: String?
    ) -> StaffScheduleDTO {
        StaffScheduleDTO(
            id: id, trip: 1, dayNumber: day,
            startTime: start + ":00", endTime: end + ":00",
            durationMinutes: 60, placeName: place, durationDisplay: "1시간",
            transport: "bus", mainContent: content, meetingPoint: nil, order: id
        )
    }

    // MARK: - 안전 관리

    func fetchSafetySummary(tripId: Int) -> Single<MonitoringSummaryDTO> {
        .just(MonitoringSummaryDTO(total: 12, safe: 8, warning: 2, danger: 1, stale: 0, offline: 1, unknown: 0))
    }

    func fetchParticipantsLatest(tripId: Int) -> Single<[ParticipantLatestDTO]> {
        .just([
            participant(1, "김여행", hr: 132, spo2: "88", health: .danger, location: .normal),
            participant(2, "이관광", hr: 105, spo2: "93", health: .warning, location: .normal),
            participant(3, "박구경", hr: nil, spo2: nil, health: .offline, location: .offline),
            participant(4, "최유람", hr: 88, spo2: "97", health: .normal, location: .danger, escaped: true),
            participant(5, "정나들", hr: 76, spo2: "98", health: .normal, location: .normal),
        ])
    }

    private func participant(
        _ id: Int, _ name: String, hr: Int?, spo2: String?,
        health: MonitoringStatus, location: MonitoringStatus, escaped: Bool = false
    ) -> ParticipantLatestDTO {
        let overall: MonitoringStatus = [health, location].contains(.danger) ? .danger
            : ([health, location].contains(.warning) ? .warning : health)

        return ParticipantLatestDTO(
            participantId: id,
            travelerName: name,
            tripId: 1,
            health: HealthSnapshotDTO(heartRate: hr, spo2: spo2, measuredAt: Self.isoNow(minutesAgo: 1)),
            location: LocationSnapshotDTO(
                latitude: "33.4996", longitude: "126.5312",
                accuracyM: "12.0", measuredAt: Self.isoNow(minutesAgo: 1)
            ),
            healthStatus: health,
            locationStatus: location,
            overallStatus: overall,
            activeIncidents: escaped ? [IncidentSummaryDTO(
                id: 90 + id, travelerName: name, incidentType: "geofence",
                severity: "danger", status: "open", reasonCode: "out_of_geofence",
                message: "안전 구역에서 1.2km 벗어남",
                openedAt: Self.isoNow(minutesAgo: 6), acknowledgedAt: nil
            )] : []
        )
    }

    func fetchAlerts(tripId: Int) -> Single<[MonitoringAlertDTO]> {
        .just([
            MonitoringAlertDTO(
                id: 1, travelerName: "김여행", tripId: 1, alertType: "health",
                severity: "danger", reasonCode: "spo2_low", incident: 91,
                message: "산소포화도 88% — 위험",
                snapshotTime: Self.isoNow(minutesAgo: 2), createdAt: Self.isoNow(minutesAgo: 2)
            ),
            MonitoringAlertDTO(
                id: 2, travelerName: "최유람", tripId: 1, alertType: "location",
                severity: "danger", reasonCode: "out_of_geofence", incident: 94,
                message: "안전 구역에서 1.2km 벗어남",
                snapshotTime: Self.isoNow(minutesAgo: 6), createdAt: Self.isoNow(minutesAgo: 6)
            ),
            MonitoringAlertDTO(
                id: 3, travelerName: "이관광", tripId: 1, alertType: "health",
                severity: "warning", reasonCode: "heart_rate_high", incident: 92,
                message: "심박수 105bpm — 경고",
                snapshotTime: Self.isoNow(minutesAgo: 12), createdAt: Self.isoNow(minutesAgo: 12)
            ),
        ])
    }

    func acknowledgeIncident(tripId: Int, incidentId: Int) -> Single<EmptyResponse> {
        .just(EmptyResponse())
    }

    // MARK: - 공지

    private static var notices: [StaffNoticeDTO] = [
        notice(id: 1, "한라산 등반 안전 수칙",
               "내일 한라산 등반 시 반드시 등산화를 착용해 주세요. 기상 변화가 심하므로 방수 재킷도 필수입니다.",
               active: true, minutesAgo: 60),
        notice(id: 2, "조식 시간 변경",
               "조식이 08:00으로 변경되었습니다. 시간을 엄수해 주세요.",
               active: false, minutesAgo: 600),
    ]

    private static func notice(
        id: Int, _ title: String, _ content: String, active: Bool, minutesAgo: Int
    ) -> StaffNoticeDTO {
        StaffNoticeDTO(
            id: id, scope: "trip", trip: 1, tripTitle: "뉴진스 바다여행",
            authorName: "김안내", title: title, content: content, priority: "normal",
            publishedAt: active ? isoNow(minutesAgo: minutesAgo) : nil,
            isActive: active, readCount: 7, audienceCount: 12, unreadCount: 5,
            createdAt: isoNow(minutesAgo: minutesAgo)
        )
    }

    func fetchNotices() -> Single<[StaffNoticeDTO]> { .just(Self.notices) }

    func createNotice(title: String, content: String, tripId: Int?) -> Single<StaffNoticeDTO> {
        let created = Self.notice(
            id: (Self.notices.map(\.id).max() ?? 0) + 1,
            title, content, active: false, minutesAgo: 0
        )
        Self.notices.insert(created, at: 0)
        return .just(created)
    }

    /// 활성 공지는 항상 1건 — 다른 공지를 활성화하면 기존 것은 자동으로 내려갑니다
    func publishNotice(id: Int) -> Single<StaffNoticeDTO> {
        Self.notices = Self.notices.map { Self.setActive($0, $0.id == id) }
        return .just(Self.notices.first { $0.id == id } ?? Self.notices[0])
    }

    func archiveNotice(id: Int) -> Single<StaffNoticeDTO> {
        Self.notices = Self.notices.map { $0.id == id ? Self.setActive($0, false) : $0 }
        return .just(Self.notices.first { $0.id == id } ?? Self.notices[0])
    }

    private static func setActive(_ n: StaffNoticeDTO, _ active: Bool) -> StaffNoticeDTO {
        StaffNoticeDTO(
            id: n.id, scope: n.scope, trip: n.trip, tripTitle: n.tripTitle,
            authorName: n.authorName, title: n.title, content: n.content, priority: n.priority,
            publishedAt: active ? isoNow() : n.publishedAt, isActive: active,
            readCount: n.readCount, audienceCount: n.audienceCount, unreadCount: n.unreadCount,
            createdAt: n.createdAt
        )
    }

    // MARK: - 안전 구역

    private static var geofences: [GeofenceDTO] = [
        GeofenceDTO(
            id: 1, trip: 1, dayNumber: 1, revision: 1, isActive: true,
            centerLat: "33.499621", centerLng: "126.531188",
            centerAddress: "제주특별자치도 제주시 이도이동", radiusKm: 3,
            updatedByName: "김안내", updatedAt: isoNow(minutesAgo: 600)
        ),
        GeofenceDTO(
            id: 2, trip: 1, dayNumber: 2, revision: 2, isActive: true,
            centerLat: "33.450701", centerLng: "126.570667",
            centerAddress: "제주특별자치도 제주시 연동", radiusKm: 5,
            updatedByName: "김안내", updatedAt: isoNow(minutesAgo: 120)
        ),
    ]

    func fetchGeofences(tripId: Int) -> Single<[GeofenceDTO]> { .just(Self.geofences) }

    func updateGeofence(
        tripId: Int, id: Int,
        centerLat: String, centerLng: String, radiusKm: Int,
        expectedRevision: Int
    ) -> Single<GeofenceDTO> {
        guard let idx = Self.geofences.firstIndex(where: { $0.id == id }) else {
            return .error(HiTripError.notFound(.empty(statusCode: 404)))
        }
        let old = Self.geofences[idx]
        let updated = GeofenceDTO(
            id: old.id, trip: old.trip, dayNumber: old.dayNumber,
            revision: old.revision + 1, isActive: true,
            centerLat: centerLat, centerLng: centerLng,
            centerAddress: old.centerAddress, radiusKm: radiusKm,
            updatedByName: "김안내", updatedAt: Self.isoNow()
        )
        Self.geofences[idx] = updated
        return .just(updated)
    }
}
