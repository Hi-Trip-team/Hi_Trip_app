import Foundation
import RxSwift

// MARK: - MockTravelerRepository
/// 서버 없이 UI를 검증하기 위한 목 데이터 구현체
///
/// 사용법:
///   APIEnvironment.swift에서 `static let current: APIEnvironment = .mock` 으로 변경하면
///   관광객 화면 ViewModel이 모두 이 Mock을 사용.
///
/// 데이터 기준:
///   - 현재 날짜 기준 3박 4일 제주 여행 (어제 출발 → 오늘이 2일차)
///   - 날짜를 고정하지 않고 매번 오늘 기준으로 만들어, 시간이 지나도
///     "오늘의 일정"이 사라지지 않습니다.
///   - API 응답 구조(DTO)를 실제 서버와 동일하게 맞춤

final class MockTravelerRepository: TravelerRepositoryProtocol {

    // MARK: - Auth

    func travelerLogin(username: String, password: String, tripId: Int?) -> Single<TravelerAuthResponseDTO> {
        .just(TravelerAuthResponseDTO(
            token: "mock-token-abc123",
            expiresAt: nil,
            traveler: mockTravelerPublic,
            trip: mockTravelerTrip,
            agreementStatus: mockAgreement,
            requiresAgreement: false
        ))
    }

    func logout() -> Single<TravelerLogoutResponseDTO> {
        .just(TravelerLogoutResponseDTO(message: "로그아웃 완료"))
    }

    // MARK: - Profile

    func fetchMe() -> Single<TravelerMeDTO> {
        .just(TravelerMeDTO(traveler: mockTravelerPublic, trip: mockTravelerTrip))
    }

    func updateMe(_ request: TravelerProfileUpdateRequest) -> Single<TravelerPublicDTO> {
        .just(mockTravelerPublic)
    }

    // MARK: - Agreements

    func fetchAgreements() -> Single<TravelerAgreementDTO> {
        .just(mockAgreement)
    }

    func updateAgreements(termsAccepted: Bool, locationAccepted: Bool?, notificationAccepted: Bool?) -> Single<TravelerAgreementDTO> {
        .just(TravelerAgreementDTO(
            termsAccepted: termsAccepted,
            locationPermissionAccepted: locationAccepted,
            notificationPermissionAccepted: notificationAccepted,
            acceptedAt: isoNow(),
            updatedAt: isoNow(),
            requiresAgreement: false
        ))
    }

    // MARK: - Trip & Home

    func fetchTrip() -> Single<TravelerTripDTO> {
        .just(mockTravelerTrip)
    }

    func fetchHome() -> Single<TravelerHomeDTO> {
        .just(TravelerHomeDTO(
            traveler: mockTravelerPublic,
            trip: mockTravelerTrip,
            agreementStatus: mockAgreement,
            requiresAgreement: false,
            todayDayNumber: 2,   // 어제 출발이므로 오늘이 2일차
            todaySchedules: todayMockSchedules,
            nextSchedule: nextMockSchedule,
            managerContact: ["phone": "010-1234-5678", "name": "김담당"],
            todayCongestion: nil,
            congestionStatus: nil,
            advisory: nil
        ))
    }

    /// 오늘(2일차) 일정 전체 — 실제 서버도 오늘 것을 전부 내려줍니다.
    private var todayMockSchedules: [TravelerScheduleDTO] {
        mockSchedules.filter { $0.dayNumber == 2 }.sorted { $0.startTime < $1.startTime }
    }

    /// 아직 시작하지 않은 가장 이른 일정.
    /// 서버가 현재 시각 기준으로 계산해 주는 값이라 목에서도 같은 방식으로 만듭니다.
    private var nextMockSchedule: TravelerScheduleDTO? {
        let now = Self.minutesNow()
        return todayMockSchedules.first { (Self.minutesOf($0.startTime) ?? 0) > now }
    }

    private static func minutesOf(_ time: String) -> Int? {
        let p = time.split(separator: ":").compactMap { Int($0) }
        guard p.count >= 2 else { return nil }
        return p[0] * 60 + p[1]
    }

    private static func minutesNow() -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    // MARK: - 개인 일정

    /// 메모리 보관 — 앱을 다시 켜면 초기화됩니다.
    private static var personalSchedules: [TravelerPersonalScheduleDTO] = [
        TravelerPersonalScheduleDTO(
            id: 9001, dayNumber: 2, scheduleDate: MockTravelerRepository.ymd(Date()),
            title: "기념품 쇼핑", startTime: "20:00:00", endTime: "21:00:00",
            memo: nil, isPersonal: true,
            overlapWarning: false, overlapWithSharedScheduleIds: [],
            createdAt: nil, updatedAt: nil
        )
    ]
    private static var nextPersonalId = 9002

    func fetchPersonalSchedules() -> Single<[TravelerPersonalScheduleDTO]> {
        .just(Self.personalSchedules)
    }

    func createPersonalSchedule(_ request: TravelerPersonalScheduleRequest) -> Single<TravelerPersonalScheduleDTO> {
        // 서버처럼 공용 일정과 겹치는지 판정
        let overlaps = Self.overlappingSharedIds(
            dayNumber: request.dayNumber,
            start: request.startTime,
            end: request.endTime,
            schedules: mockSchedules
        )
        let dto = TravelerPersonalScheduleDTO(
            id: Self.nextPersonalId, dayNumber: request.dayNumber,
            scheduleDate: request.scheduleDate, title: request.title,
            startTime: request.startTime, endTime: request.endTime,
            memo: request.memo, isPersonal: true,
            overlapWarning: !overlaps.isEmpty,
            overlapWithSharedScheduleIds: overlaps,
            createdAt: nil, updatedAt: nil
        )
        Self.nextPersonalId += 1
        Self.personalSchedules.append(dto)
        return .just(dto)
    }

    func updatePersonalSchedule(id: Int, _ request: TravelerPersonalScheduleRequest) -> Single<TravelerPersonalScheduleDTO> {
        let overlaps = Self.overlappingSharedIds(
            dayNumber: request.dayNumber,
            start: request.startTime,
            end: request.endTime,
            schedules: mockSchedules
        )
        let dto = TravelerPersonalScheduleDTO(
            id: id, dayNumber: request.dayNumber,
            scheduleDate: request.scheduleDate, title: request.title,
            startTime: request.startTime, endTime: request.endTime,
            memo: request.memo, isPersonal: true,
            overlapWarning: !overlaps.isEmpty,
            overlapWithSharedScheduleIds: overlaps,
            createdAt: nil, updatedAt: nil
        )
        if let idx = Self.personalSchedules.firstIndex(where: { $0.id == id }) {
            Self.personalSchedules[idx] = dto
        }
        return .just(dto)
    }

    func deletePersonalSchedule(id: Int) -> Single<Void> {
        Self.personalSchedules.removeAll { $0.id == id }
        return .just(())
    }

    private static func overlappingSharedIds(
        dayNumber: Int, start: String, end: String, schedules: [TravelerScheduleDTO]
    ) -> [Int] {
        func mins(_ t: String) -> Int {
            let p = t.split(separator: ":").compactMap { Int($0) }
            return p.count >= 2 ? p[0] * 60 + p[1] : 0
        }
        let s = mins(start), e = mins(end)
        return schedules
            .filter { $0.dayNumber == dayNumber }
            .filter { mins($0.startTime) < e && s < mins($0.endTime) }
            .map(\.id)
    }

    // MARK: - 현지 표현

    func fetchLocalPhrases() -> Single<TravelerLocalPhrasesDTO> {
        .just(TravelerLocalPhrasesDTO(
            destination: "일본 오사카",
            languageCode: "ja",
            languageName: "일본어",
            phrases: [
                LocalPhraseDTO(id: 1, koreanText: "안녕하세요. 커피 하나 부탁드려요.",
                               translatedText: "こんにちは。コーヒーを一つお願いします。",
                               pronunciation: "곤니찌와, 코히 히토츠 오네가이시마스", displayOrder: 1),
                LocalPhraseDTO(id: 2, koreanText: "메뉴판 부탁드립니다.",
                               translatedText: "メニューをお願いします。",
                               pronunciation: "메뉴-오 오네가이시마스", displayOrder: 2),
                LocalPhraseDTO(id: 3, koreanText: "계산 부탁드립니다.",
                               translatedText: "お会計をお願いします。",
                               pronunciation: "오카이케-오 오네가이시마스", displayOrder: 3),
                LocalPhraseDTO(id: 4, koreanText: "화장실이 어디인가요?",
                               translatedText: "トイレはどこですか？",
                               pronunciation: "토이레와 도코데스카", displayOrder: 4),
            ]
        ))
    }

    func fetchCalendar() -> Single<TravelerCalendarDTO> {
        let days = makeMockCalendarDays()
        return .just(TravelerCalendarDTO(trip: mockTravelerTrip, days: days))
    }

    // MARK: - Schedules

    func fetchSchedules() -> Single<[TravelerScheduleDTO]> {
        .just(mockSchedules)
    }

    func fetchSchedule(id: Int) -> Single<TravelerScheduleDTO> {
        if let found = mockSchedules.first(where: { $0.id == id }) {
            return .just(found)
        }
        return .error(HiTripError.notFound(.empty(statusCode: 404)))
    }

    // MARK: - Notices

    func fetchNotices() -> Single<[TravelerNoticeDTO]> {
        .just(mockNotices)
    }

    func markNoticeRead(id: Int) -> Single<Void> {
        Self.readNoticeIds.insert(id)
        return .just(())
    }

    func fetchNotice(id: Int) -> Single<TravelerNoticeDTO> {
        if let found = mockNotices.first(where: { $0.id == id }) {
            return .just(found)
        }
        return .error(HiTripError.notFound(.empty(statusCode: 404)))
    }

    // MARK: - Checklist

    func fetchChecklists() -> Single<[TravelerChecklistItemDTO]> {
        .just(mockChecklists)
    }

    func toggleChecklist(itemId: Int, isChecked: Bool) -> Single<TravelerChecklistItemDTO> {
        if let found = mockChecklists.first(where: { $0.id == itemId }) {
            let updated = TravelerChecklistItemDTO(
                id: found.id,
                title: found.title,
                description: found.description,
                displayOrder: found.displayOrder,
                isChecked: isChecked,
                checkedAt: isChecked ? isoNow() : nil
            )
            return .just(updated)
        }
        return .error(HiTripError.notFound(.empty(statusCode: 404)))
    }

    // MARK: - Spots

    func fetchRecommendedSpots() -> Single<[TravelerSpotDTO]> {
        .just(mockRecommendedSpots)
    }

    func fetchPopularSpots() -> Single<[TravelerSpotDTO]> {
        .just(mockPopularSpots)
    }

    func fetchSpot(id: Int) -> Single<TravelerSpotDTO> {
        let all = mockRecommendedSpots + mockPopularSpots
        if let found = all.first(where: { $0.id == id }) { return .just(found) }
        return .error(HiTripError.notFound(.empty(statusCode: 404)))
    }

    // MARK: - Map & Manager

    func fetchMapPlaces() -> Single<[TravelerMapPlaceDTO]> {
        .just(mockMapPlaces)
    }

    func fetchManagerContact() -> Single<TravelerManagerContactDTO> {
        .just(TravelerManagerContactDTO(manager: ["phone": "010-1234-5678", "name": "김담당 매니저"]))
    }

    // MARK: - 주변 스팟 / 안전

    func fetchNearbySpots(
        category: String,
        lat: Double,
        lng: Double,
        radius: Int?
    ) -> Single<[TravelerNearbySpotDTO]> {
        .just(Self.mockNearbySpots(category: category, lat: lat, lng: lng))
    }

    func fetchSafetySummary() -> Single<TravelerSafetySummaryDTO> {
        // 목에서는 현재 위치를 모르므로 제주 시내를 중심으로 잡습니다
        .just(TravelerSafetySummaryDTO(
            tripId: 1,
            dayNumber: 2,
            geofence: TravelerGeofenceDTO(
                centerLat: "33.499621",
                centerLng: "126.531188",
                radiusKm: "3.0"
            )
        ))
    }

    func sendLocationSnapshot(latitude: Double, longitude: Double, accuracyM: Double?) -> Single<Void> {
        .just(())
    }

    /// 카테고리별로 좌표를 조금씩 흩어 놓아 지도 마커를 확인할 수 있게 합니다.
    private static func mockNearbySpots(category: String, lat: Double, lng: Double) -> [TravelerNearbySpotDTO] {
        let names: [String]
        switch category {
        case "restaurant":    names = ["흑돼지 명가", "해녀의 집", "올레 국수"]
        case "accessibility": names = ["제주도립미술관", "한라수목원"]
        case "pet":           names = ["반려동물 동반 카페", "애월 펫파크"]
        case "convenience":   names = ["GS25 동문점", "CU 칠성로점", "세븐일레븐 관덕정"]
        case "mart":          names = ["이마트 제주점", "하나로마트"]
        default:              names = []
        }

        return names.enumerated().map { index, name in
            TravelerNearbySpotDTO(
                providerObjectId: "\(category)_\(index)",
                name: name,
                categoryName: category,
                categoryGroupCode: nil,
                categoryGroupName: nil,
                phone: nil,
                address: "제주특별자치도 제주시",
                roadAddress: nil,
                placeUrl: nil,
                distanceM: 300 + index * 250,
                lat: String(lat + Double(index + 1) * 0.004),
                lng: String(lng + Double(index % 2 == 0 ? 1 : -1) * 0.005),
                isSponsored: index == 0,
                imageUrl: nil,
                description: "목 데이터"
            )
        }
    }

    func sendEmergencyRequest(message: String, latitude: String?, longitude: String?, accuracyM: String?) -> Single<TravelerEmergencyRequestDTO> {
        .just(TravelerEmergencyRequestDTO(
            id: 1,
            travelerName: "홍길동",
            tripId: 1,
            message: message,
            latitude: latitude,
            longitude: longitude,
            accuracyM: accuracyM,
            status: "open",
            createdAt: isoNow(),
            updatedAt: isoNow()
        ))
    }
}

// MARK: - Mock Data

private extension MockTravelerRepository {

    // MARK: Traveler

    var mockTravelerPublic: TravelerPublicDTO {
        TravelerPublicDTO(
            id: 42,
            lastNameKr: "홍",
            firstNameKr: "길동",
            fullNameKr: "홍길동",
            firstNameEn: "Gildong",
            lastNameEn: "Hong",
            phone: "01012345678",
            email: "gildong@example.com",
            address: "서울시 강남구",
            country: "KR",
            birthDate: "1995-03-15",
            gender: "M",
            totalAmount: 1500000,
            paidAmount: 750000,
            passportVerified: true,
            bookingVerified: false,
            paymentStatusDisplay: "50% 납부",
            docStatusDisplay: "여권 확인 완료"
        )
    }

    var mockTravelerTrip: TravelerTripDTO {
        TravelerTripDTO(
            id: 1,
            title: "제주 힐링 여행 2026",
            destination: "제주",
            startDate: Self.ymd(Self.tripStartDate),
            endDate: Self.ymd(Self.tripStartDate.addingTimeInterval(3 * 86_400)),
            status: "ongoing",
            managerName: "김담당",
            managerContact: ["phone": "010-1234-5678"],
            dDay: -1,   // 어제 출발 → 오늘이 2일차
            durationDays: 4
        )
    }

    var mockAgreement: TravelerAgreementDTO {
        TravelerAgreementDTO(
            termsAccepted: true,
            locationPermissionAccepted: true,
            notificationPermissionAccepted: false,
            acceptedAt: "2026-06-20T10:00:00.000000Z",
            updatedAt: "2026-06-20T10:00:00.000000Z",
            requiresAgreement: false
        )
    }

    // MARK: Schedules (4일 일정)

    var mockSchedules: [TravelerScheduleDTO] {
        [
            // DAY 1 — 6/21
            schedule(1, day: 1, order: 1, start: "09:00:00", end: "11:00:00", place: "제주국제공항",   content: "제주 도착 / 렌터카 수령",  transport: "항공"),
            schedule(2, day: 1, order: 2, start: "11:30:00", end: "13:00:00", place: "흑돼지거리",      content: "점심식사 — 제주 흑돼지",  transport: "전용버스"),
            schedule(3, day: 1, order: 3, start: "13:30:00", end: "16:00:00", place: "성산일출봉",      content: "유네스코 세계자연유산 탐방", transport: "자가용"),
            schedule(4, day: 1, order: 4, start: "16:30:00", end: "18:00:00", place: "섭지코지",        content: "해안 산책 및 사진 촬영",    transport: "도보"),
            schedule(5, day: 1, order: 5, start: "19:00:00", end: "21:00:00", place: "제주시 호텔",     content: "체크인 및 휴식",           transport: "전용버스"),

            // DAY 2 — 6/22 (오늘)
            schedule(6, day: 2, order: 1, start: "08:00:00", end: "09:00:00", place: "호텔 식당",       content: "조식",                     transport: nil),
            schedule(7, day: 2, order: 2, start: "09:30:00", end: "12:00:00", place: "한라산 국립공원", content: "어리목 코스 등반 (1,100m)", transport: "전용버스"),
            schedule(8, day: 2, order: 3, start: "12:30:00", end: "13:30:00", place: "어리목 탐방지원센터", content: "도시락 점심",           transport: "도보"),
            schedule(9, day: 2, order: 4, start: "14:00:00", end: "16:00:00", place: "제주민속촌",      content: "전통문화 체험",            transport: "자가용"),
            schedule(10, day: 2, order: 5, start: "17:00:00", end: "18:30:00", place: "애월 해안도로",  content: "드라이브 및 카페 투어",     transport: "자가용"),
            schedule(11, day: 2, order: 6, start: "19:30:00", end: "21:30:00", place: "협재해수욕장",   content: "석양 감상 및 저녁식사",     transport: "도보"),

            // DAY 3 — 6/23
            schedule(12, day: 3, order: 1, start: "09:00:00", end: "11:30:00", place: "우도",           content: "우도 선착장 출발 / 땅콩 아이스크림", transport: "배"),
            schedule(13, day: 3, order: 2, start: "11:30:00", end: "13:30:00", place: "우도 검멀레해수욕장", content: "스노클링 체험",       transport: "전동자전거"),
            schedule(14, day: 3, order: 3, start: "14:00:00", end: "15:00:00", place: "우도 식당",      content: "해산물 점심",              transport: "도보"),
            schedule(15, day: 3, order: 4, start: "15:30:00", end: "17:00:00", place: "제주 동문시장",  content: "기념품 쇼핑",              transport: "전용버스"),
            schedule(16, day: 3, order: 5, start: "18:00:00", end: "21:00:00", place: "제주 해안",      content: "BBQ 석식 파티",            transport: "전용버스"),

            // DAY 4 — 6/24
            schedule(17, day: 4, order: 1, start: "08:00:00", end: "09:30:00", place: "호텔",           content: "조식 및 체크아웃",         transport: nil),
            schedule(18, day: 4, order: 2, start: "10:00:00", end: "12:00:00", place: "카멜리아힐",     content: "수국 정원 산책",           transport: "자가용"),
            schedule(19, day: 4, order: 3, start: "12:30:00", end: "14:00:00", place: "이호테우해변",   content: "마지막 점심 — 갈치조림",   transport: "전용버스"),
            schedule(20, day: 4, order: 4, start: "15:00:00", end: "17:30:00", place: "제주국제공항",   content: "탑승 수속 및 귀국",        transport: "전용버스"),
        ]
    }

    private func schedule(_ id: Int, day: Int, order: Int, start: String, end: String, place: String, content: String, transport: String?) -> TravelerScheduleDTO {
        let dateStr = tripDayDate(day)
        let durationMin = durationMinutes(from: start, to: end)
        return TravelerScheduleDTO(
            id: id,
            dayNumber: day,
            scheduleDate: dateStr,
            order: order,
            startTime: start,
            endTime: end,
            durationMinutes: durationMin,
            durationDisplay: "\(durationMin ?? 0)분",
            transport: transport,
            mainContent: content,
            meetingPoint: nil,
            placeId: id * 10,
            placeName: place,
            placeAddress: nil,
            placeLatitude: nil,
            placeLongitude: nil
        )
    }

    // MARK: Notices

    /// 읽음 처리한 공지 id — 목 환경에서도 빨간 점이 사라지는 걸 확인할 수 있게 유지합니다
    private static var readNoticeIds: Set<Int> = []

    var mockNotices: [TravelerNoticeDTO] {
        raw.map { n in
            Self.readNoticeIds.contains(n.id)
                ? TravelerNoticeDTO(id: n.id, title: n.title, content: n.content,
                                    priority: n.priority, publishedAt: n.publishedAt,
                                    createdAt: n.createdAt, updatedAt: n.updatedAt,
                                    isRead: true, isActive: n.isActive)
                : n
        }
    }

    private var raw: [TravelerNoticeDTO] {
        [
            TravelerNoticeDTO(id: 1, title: "⚠️ 한라산 등반 안전 수칙",
                content: "내일 한라산 등반 시 반드시 등산화를 착용해 주세요. 기상 변화가 심하므로 방수 재킷도 필수입니다. 오전 9시 30분 호텔 로비에서 집결합니다.",
                priority: "important", publishedAt: "2026-07-19T18:00:00.000000Z",
                createdAt: "2026-07-19T18:00:00.000000Z", updatedAt: "2026-07-19T18:00:00.000000Z",
                isRead: false, isActive: true),

            TravelerNoticeDTO(id: 2, title: "우도 스노클링 장비 신청 마감",
                content: "내일 우도 스노클링 체험을 원하시는 분은 오늘 밤 10시까지 담당자에게 연락 주시기 바랍니다. 장비는 현장에서 제공됩니다.",
                priority: "normal", publishedAt: "2026-07-19T20:00:00.000000Z",
                createdAt: "2026-07-19T20:00:00.000000Z", updatedAt: "2026-07-19T20:00:00.000000Z",
                isRead: false, isActive: true),

            TravelerNoticeDTO(id: 3, title: "내일 조식 시간 변경 안내",
                content: "7월 20일(일) 조식이 08:00으로 변경되었습니다. 한라산 등반 일정이 앞당겨진 관계로 시간을 엄수해 주시기 바랍니다.",
                priority: "normal", publishedAt: "2026-07-19T21:00:00.000000Z",
                createdAt: "2026-07-19T21:00:00.000000Z", updatedAt: "2026-07-19T21:00:00.000000Z",
                isRead: true, isActive: true),

            TravelerNoticeDTO(id: 4, title: "1일차 집합 안내",
                content: "공항 3번 게이트 앞에서 09:00에 집합합니다. 늦으시는 분은 담당자에게 연락 주세요.",
                priority: "normal", publishedAt: "2026-07-18T09:00:00.000000Z",
                createdAt: "2026-07-18T09:00:00.000000Z", updatedAt: "2026-07-18T09:00:00.000000Z",
                isRead: true, isActive: false),
        ]
    }

    // MARK: Checklists

    var mockChecklists: [TravelerChecklistItemDTO] {
        [
            TravelerChecklistItemDTO(id: 1, title: "여권 지참 확인",           description: "해외 체크인 필요", displayOrder: 1, isChecked: true,  checkedAt: "2026-06-20T09:00:00Z"),
            TravelerChecklistItemDTO(id: 2, title: "여행자 보험 가입",          description: "출발 전 필수",    displayOrder: 2, isChecked: true,  checkedAt: "2026-06-19T14:00:00Z"),
            TravelerChecklistItemDTO(id: 3, title: "등산화/방수 재킷 준비",     description: "한라산 등반용",    displayOrder: 3, isChecked: false, checkedAt: nil),
            TravelerChecklistItemDTO(id: 4, title: "수영복 및 물안경 챙기기",   description: "우도 스노클링용",  displayOrder: 4, isChecked: false, checkedAt: nil),
            TravelerChecklistItemDTO(id: 5, title: "현금 환전 (일부)",          description: "시장 소액 결제용", displayOrder: 5, isChecked: true,  checkedAt: "2026-06-20T11:00:00Z"),
            TravelerChecklistItemDTO(id: 6, title: "썬크림 및 모자 지참",       description: "야외 활동 필수",   displayOrder: 6, isChecked: false, checkedAt: nil),
        ]
    }

    // MARK: Spots

    var mockRecommendedSpots: [TravelerSpotDTO] {
        [
            spot(id: 101, type: "recommended", title: "성산일출봉",    desc: "유네스코 세계자연유산, 제주 동쪽의 상징적인 분화구",
                 reason: "일출 명소로 이른 아침 방문 추천",
                 imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Seongsan_Ilchulbong.jpg/1280px-Seongsan_Ilchulbong.jpg",
                 category: "자연", lat: "33.4581", lon: "126.9426"),

            spot(id: 102, type: "recommended", title: "우도",          desc: "소 머리를 닮은 제주의 아름다운 부속 섬",
                 reason: "땅콩 아이스크림과 에메랄드 바다가 유명",
                 imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Udo_Island.jpg/1280px-Udo_Island.jpg",
                 category: "섬/해변", lat: "33.5069", lon: "126.9529"),

            spot(id: 103, type: "recommended", title: "협재해수욕장",  desc: "새하얀 모래사장과 에메랄드빛 바다로 유명한 해수욕장",
                 reason: "석양이 아름다운 서쪽 해변, 저녁 방문 추천",
                 imageUrl: "https://upload.wikimedia.org/wikipedia/commons/4/47/Hyeopjae_Beach.jpg",
                 category: "해변", lat: "33.3941", lon: "126.2394"),
        ]
    }

    var mockPopularSpots: [TravelerSpotDTO] {
        [
            spot(id: 201, type: "popular", title: "제주 동문시장",   desc: "제주 최대 전통 재래시장, 다양한 먹거리와 기념품",
                 reason: "여행자들이 가장 많이 방문하는 시장",
                 imageUrl: "https://cdn.visitjeju.net/photo/20171106/64282.jpg",
                 category: "시장", lat: "33.5139", lon: "126.5216"),

            spot(id: 202, type: "popular", title: "카멜리아힐",      desc: "동양 최대 동백나무 정원, 계절별 다양한 꽃",
                 reason: "수국 시즌(6~7월) 방문 강력 추천",
                 imageUrl: "https://cdn.visitjeju.net/photo/20171106/64283.jpg",
                 category: "정원", lat: "33.2979", lon: "126.3629"),

            spot(id: 203, type: "popular", title: "애월 한담해안산책로", desc: "제주 서쪽 해안을 따라 걷는 아름다운 산책로",
                 reason: "카페 투어와 함께 즐기는 인기 코스",
                 imageUrl: "https://cdn.visitjeju.net/photo/20171106/64284.jpg",
                 category: "산책로", lat: "33.4655", lon: "126.3154"),
        ]
    }

    private func spot(id: Int, type: String, title: String, desc: String, reason: String, imageUrl: String, category: String, lat: String, lon: String) -> TravelerSpotDTO {
        TravelerSpotDTO(
            id: id,
            spotType: type,
            title: title,
            description: desc,
            reason: reason,
            imageUrl: imageUrl,
            displayOrder: id,
            place: TripSpotPlaceDTO(
                id: id * 100,
                name: title,
                address: "제주특별자치도",
                latitude: lat,
                longitude: lon,
                categoryName: category,
                imageUrl: imageUrl
            ),
            // 광고 뱃지 렌더링 확인용 — 인기 스팟 첫 항목만 광고
            isSponsored: id == 201,
            createdAt: "2026-06-01T00:00:00.000000Z",
            updatedAt: "2026-06-01T00:00:00.000000Z"
        )
    }

    // MARK: Map Places

    var mockMapPlaces: [TravelerMapPlaceDTO] {
        [
            TravelerMapPlaceDTO(id: 1, name: "제주국제공항",    address: "제주시 공항로 2",      latitude: "33.5113", longitude: "126.4924", dayNumbers: [1, 4], scheduleIds: [1, 20]),
            TravelerMapPlaceDTO(id: 2, name: "성산일출봉",      address: "서귀포시 성산읍",       latitude: "33.4581", longitude: "126.9426", dayNumbers: [1],    scheduleIds: [3]),
            TravelerMapPlaceDTO(id: 3, name: "한라산 국립공원", address: "제주시 1100로 2070-61", latitude: "33.3625", longitude: "126.5339", dayNumbers: [2],    scheduleIds: [7]),
            TravelerMapPlaceDTO(id: 4, name: "우도",            address: "제주시 우도면",         latitude: "33.5069", longitude: "126.9529", dayNumbers: [3],    scheduleIds: [12, 13]),
            TravelerMapPlaceDTO(id: 5, name: "제주 동문시장",   address: "제주시 관덕로 14길 20", latitude: "33.5139", longitude: "126.5216", dayNumbers: [3],    scheduleIds: [15]),
        ]
    }

    // MARK: Calendar

    private func makeMockCalendarDays() -> [TravelerCalendarDayDTO] {
        let grouped = Dictionary(grouping: mockSchedules) { $0.dayNumber }
        return (1...4).map { day in
            let schedules = grouped[day] ?? []
            let summaries = schedules.map {
                TravelerCalendarScheduleSummaryDTO(
                    id: $0.id, dayNumber: $0.dayNumber, scheduleDate: tripDayDate(day),
                    order: $0.order, startTime: $0.startTime, endTime: $0.endTime,
                    mainContent: $0.mainContent, placeName: $0.placeName
                )
            }
            return TravelerCalendarDayDTO(
                date: tripDayDate(day),
                dayNumber: day,
                scheduleCount: schedules.count,
                schedules: summaries
            )
        }
    }

    // MARK: Helpers

    private func tripDayDate(_ day: Int) -> String {
        Self.ymd(Self.tripStartDate.addingTimeInterval(Double(day - 1) * 86_400))
    }

    /// 여행 시작일 = 어제. 오늘이 항상 2일차가 되도록 현재 날짜 기준으로 잡습니다.
    ///
    /// 날짜를 고정하면 시간이 지나면서 "오늘의 일정"이 사라져 목으로 화면을
    /// 확인할 수 없게 됩니다.
    static var tripStartDate: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(-86_400)
    }

    static func ymd(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.string(from: date)
    }

    private func isoNow() -> String {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return df.string(from: Date())
    }

    private func durationMinutes(from start: String, to end: String) -> Int? {
        let parts = { (s: String) in s.split(separator: ":").compactMap { Int($0) } }
        let sp = parts(start), ep = parts(end)
        guard sp.count >= 2, ep.count >= 2 else { return nil }
        return (ep[0] * 60 + ep[1]) - (sp[0] * 60 + sp[1])
    }
}
