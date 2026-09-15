import Foundation

// MARK: - Auth

struct TravelerAuthResponseDTO: Decodable {
    let token: String
    let expiresAt: String?
    let traveler: TravelerPublicDTO
    let trip: TravelerTripDTO
    let agreementStatus: TravelerAgreementDTO
    let requiresAgreement: Bool
}

struct TravelerLogoutResponseDTO: Decodable {
    let message: String
}

// MARK: - Traveler Public Profile

struct TravelerPublicDTO: Decodable {
    let id: Int
    let lastNameKr: String
    let firstNameKr: String
    let fullNameKr: String
    let firstNameEn: String
    let lastNameEn: String
    let phone: String
    let email: String
    let address: String
    let country: String
    let birthDate: String       // "yyyy-MM-dd"
    let gender: String          // "M" or "F"
    let totalAmount: Int
    let paidAmount: Int
    let passportVerified: Bool
    let bookingVerified: Bool
    let paymentStatusDisplay: String
    let docStatusDisplay: String
}

// MARK: - Traveler Me

struct TravelerMeDTO: Decodable {
    let traveler: TravelerPublicDTO
    let trip: TravelerTripDTO
}

// MARK: - Trip

struct TravelerTripDTO: Decodable {
    let id: Int
    let title: String
    let destination: String
    let startDate: String       // "yyyy-MM-dd"
    let endDate: String         // "yyyy-MM-dd"
    let status: String          // "planning", "ongoing", "completed"
    let managerName: String?
    let managerContact: [String: String]?
    let dDay: Int
    let durationDays: Int
    /// 여행지 시간대(IANA, 예: "Asia/Seoul") — 서버 추가 예정. 없으면 TripClock이 한국 시간대로 계산
    var timezone: String? = nil
}

// MARK: - Agreement

struct TravelerAgreementDTO: Decodable {
    let termsAccepted: Bool?
    let locationPermissionAccepted: Bool?
    let notificationPermissionAccepted: Bool?
    let acceptedAt: String?
    let updatedAt: String?
    let requiresAgreement: Bool
}

// MARK: - Home

struct TravelerHomeDTO: Decodable {
    let traveler: TravelerPublicDTO
    let trip: TravelerTripDTO
    let agreementStatus: TravelerAgreementDTO
    let requiresAgreement: Bool
    let todayDayNumber: Int?
    let todaySchedules: [TravelerScheduleDTO]
    let nextSchedule: TravelerScheduleDTO?
    let managerContact: [String: String]?
    let todayCongestion: [HomeCongestionDTO]?
    /// 혼잡도 외부 데이터 수신 상태 — fresh/fallback/unavailable 등
    let congestionStatus: HomeExternalDataStatusDTO?
    let advisory: HomeAdvisoryDTO?
}

/// 외부 데이터(혼잡도) 수신 상태
struct HomeExternalDataStatusDTO: Decodable {
    let status: String?
    let fallbackUsed: Bool?
    let sourceFetchedAt: String?
    let errorCode: String?
}

struct HomeCongestionDTO: Decodable {
    let spotName: String
    let baseDate: String        // "yyyy-MM-dd"
    let congestionRate: Double
}

struct HomeAdvisoryDTO: Decodable {
    let level: String           // "info" | "caution" | "warning"
    let messages: [String]
    let suggestion: AdvisorySuggestionDTO?
}

struct AdvisorySuggestionDTO: Decodable {
    let spotName: String
    let congestionRate: Double
}

// MARK: - Schedule

struct TravelerScheduleDTO: Decodable, Identifiable {
    let id: Int
    let dayNumber: Int
    let scheduleDate: String?   // "yyyy-MM-dd" — trip start date + (dayNumber - 1)
    let order: Int
    let startTime: String       // "HH:mm:ss"
    let endTime: String         // "HH:mm:ss"
    let durationMinutes: Int?
    let durationDisplay: String
    let transport: String?
    let mainContent: String?
    let meetingPoint: String?
    let placeId: Int?
    let placeName: String?
    let placeAddress: String?
    let placeLatitude: String?
    let placeLongitude: String?
}

// MARK: - Personal Schedule (개인 일정)

struct TravelerPersonalScheduleDTO: Decodable, Identifiable {
    let id: Int
    let dayNumber: Int
    let scheduleDate: String        // "yyyy-MM-dd"
    let title: String               // 최대 20자
    let startTime: String           // "HH:mm:ss"
    let endTime: String
    let memo: String?               // 최대 100자
    let isPersonal: Bool
    /// 공용 일정과 시간이 겹치는지 — 서버가 판정합니다.
    let overlapWarning: Bool
    /// 겹치는 공용 일정의 id 목록
    let overlapWithSharedScheduleIds: [Int]
    let createdAt: String?
    let updatedAt: String?
}

/// 개인 일정 생성·수정 요청
struct TravelerPersonalScheduleRequest {
    let dayNumber: Int
    let scheduleDate: String
    let title: String
    let startTime: String
    let endTime: String
    let memo: String?

    func asDictionary() -> [String: Any] {
        var body: [String: Any] = [
            "day_number": dayNumber,
            "schedule_date": scheduleDate,
            "title": title,
            "start_time": startTime,
            "end_time": endTime,
        ]
        if let memo, !memo.isEmpty { body["memo"] = memo }
        return body
    }
}

// MARK: - Local Phrases (현지 언어)

struct TravelerLocalPhrasesDTO: Decodable {
    let destination: String
    /// "ja", "en" 등 — 음성 합성 언어 선택에 사용
    let languageCode: String
    let languageName: String
    let phrases: [LocalPhraseDTO]
}

struct LocalPhraseDTO: Decodable, Identifiable {
    let id: Int
    let koreanText: String
    let translatedText: String
    let pronunciation: String
    let displayOrder: Int

    // audio_url / audio_source / tts_text 는 서버가 주지만 쓰지 않습니다.
    // 발음은 기기 음성 합성으로 출력합니다.
}

// MARK: - Calendar

struct TravelerCalendarDayDTO: Decodable {
    let date: String            // "yyyy-MM-dd"
    let dayNumber: Int
    let scheduleCount: Int
    let schedules: [TravelerCalendarScheduleSummaryDTO]
}

struct TravelerCalendarScheduleSummaryDTO: Decodable, Identifiable {
    let id: Int
    let dayNumber: Int
    let scheduleDate: String?
    let order: Int
    let startTime: String
    let endTime: String
    let mainContent: String?
    let placeName: String?
}

// MARK: - Checklist

struct TravelerChecklistItemDTO: Decodable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let displayOrder: Int
    let isChecked: Bool
    let checkedAt: String?      // ISO8601 datetime
}

// MARK: - Notices

struct TravelerNoticeDTO: Decodable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let priority: String        // "normal", "important"
    let publishedAt: String?
    let createdAt: String?
    let updatedAt: String?
    /// 읽음 여부 — 홈의 안 읽음 뱃지 계산에 사용
    let isRead: Bool?
    /// 활성 여부 — 홈에는 활성 공지만 노출합니다
    let isActive: Bool?
}

// MARK: - Messages (Thread 기반)

struct TravelerMessageThreadDTO: Decodable, Identifiable {
    let id: Int
    let participant: Int
    let travelerId: Int
    let travelerName: String
    let subject: String
    let status: String          // "open", "closed"
    let latestMessage: [String: String]?
    let createdAt: String?
    let updatedAt: String?
}

struct TravelerMessageDTO: Decodable, Identifiable {
    let id: Int
    let senderType: String      // "traveler", "staff"
    let staffSender: Int?
    let staffSenderName: String?
    let body: String
    let createdAt: String?
}

// MARK: - Spots (Popular / Recommended)

struct TravelerSpotDTO: Decodable, Identifiable, Hashable {
    let id: Int
    let spotType: String        // "recommended", "popular"
    let title: String
    let description: String
    let reason: String
    let imageUrl: String
    let displayOrder: Int
    let place: TripSpotPlaceDTO
    /// 광고 여부 — 카드 좌상단 "광고" 뱃지
    let isSponsored: Bool?
    let createdAt: String?
    let updatedAt: String?
}

/// GET /api/v1/tourist/popular-spots/, /recommended-spots/ 응답
///
/// 서버가 배열 대신 수신 상태를 함께 담아 줍니다.
/// status: fresh(정상) · fallback(이전 정상 데이터) · empty(결과 없음) · unavailable(이용 불가)
struct TravelerSpotCollectionDTO: Decodable {
    let status: String?
    let fallbackUsed: Bool?
    let count: Int?
    let results: [TravelerSpotDTO]
}

struct TripSpotPlaceDTO: Decodable, Hashable {
    let id: Int
    let name: String
    let address: String?
    let latitude: String?
    let longitude: String?
    let categoryName: String?
    let imageUrl: String?
}

// MARK: - Map

struct TravelerMapPlaceDTO: Decodable, Identifiable {
    let id: Int
    let name: String
    let address: String?
    let latitude: String
    let longitude: String
    let dayNumbers: [Int]
    let scheduleIds: [Int]
}

// MARK: - Manager Contact

// MARK: - Emergency Request

struct TravelerEmergencyRequestDTO: Decodable, Identifiable {
    let id: Int
    let travelerName: String
    let tripId: Int
    let message: String
    let latitude: String?
    let longitude: String?
    let accuracyM: String?
    let status: String          // "open", "resolved"
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - Profile Update

// MARK: - DTO → Domain Model Conversions

extension TravelerMessageThreadDTO {
    func toChatRoom() -> ChatRoom {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let lastMsg = latestMessage?["body"] ?? ""
        let lastDateStr = latestMessage?["created_at"] ?? updatedAt ?? ""
        let lastDate = df.date(from: lastDateStr) ?? Date()
        let createdDate = df.date(from: createdAt ?? "") ?? Date()

        return ChatRoom(
            serverId: id,
            threadSubject: subject,
            status: status,
            participantName: subject,
            participantType: "staff",
            isGroupChat: false,
            lastMessage: lastMsg,
            lastMessageDate: lastDate,
            createdAt: createdDate
        )
    }
}

extension TravelerMessageDTO {
    func toMessage(chatRoomId: UUID, currentUserId: String, currentUserName: String) -> Message {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let sentAt = df.date(from: createdAt ?? "") ?? Date()

        let isFromTraveler = senderType == "traveler"
        let senderId = isFromTraveler ? currentUserId : "staff_\(staffSender ?? 0)"
        let senderName = isFromTraveler ? currentUserName : (staffSenderName ?? "담당자")

        return Message(
            serverId: id,
            senderType: senderType,
            chatRoomId: chatRoomId,
            senderId: senderId,
            senderName: senderName,
            content: body,
            sentAt: sentAt,
            sendStatus: .sent
        )
    }
}

// MARK: - Chat v1 DTOs

struct ChatRoomV1DTO: Decodable {
    let id: Int
    let roomType: String?           // "direct", "group"
    let trip: Int?
    let tripTitle: String?
    let touristId: Int?
    let touristName: String?
    let peerTourists: [[String: AnyCodable]]?
    let assignedStaffId: Int?
    let subject: String?
    let latestMessage: [String: AnyCodable]?
    let unreadCount: Int
    let createdAt: String?
    let updatedAt: String?
}

struct ChatMessageV1DTO: Decodable {
    let id: Int
    let room: Int
    let sender: Int?
    let senderName: String?
    let senderRole: String?         // "tourist", "staff"
    let clientMessageId: String?
    let messageType: String?
    let body: String
    let metadata: [String: AnyCodable]?
    let replyTo: Int?
    let attachments: [ChatAttachmentDTO]?
    /// WebSocket 이벤트에는 빠질 수 있어 선택값으로 둡니다
    let isDeleted: Bool?
    let createdAt: String?
}

struct ChatAttachmentDTO: Decodable {
    let id: Int
    let mediaType: String?
    let downloadUrl: String?
    let originalName: String?
    let mimeType: String?
    let duration: Int?

    func toAttachment() -> MessageAttachment {
        MessageAttachment(
            id: id,
            mediaType: mediaType ?? "photo",
            downloadUrl: downloadUrl,
            originalName: originalName,
            duration: duration
        )
    }
}

// MARK: - 첨부 업로드

/// POST /api/v1/chat/uploads/presign/
struct ChatUploadIntentDTO: Decodable {
    let attachmentId: Int
    /// 항상 "PUT"
    let method: String?
    let uploadUrl: String
    let expiresAt: String?
    /// 업로드 PUT에 반드시 실어야 하는 헤더 (Content-Type 등)
    let requiredHeaders: [String: String]?
}

struct ChatMessagePageDTO: Decodable {
    let results: [ChatMessageV1DTO]
    let nextCursor: Int?
}

// AnyCodable helper for heterogeneous JSON values
struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self)   { value = v; return }
        if let v = try? c.decode(Int.self)    { value = v; return }
        if let v = try? c.decode(Double.self) { value = v; return }
        if let v = try? c.decode(String.self) { value = v; return }
        value = NSNull()
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool:   try c.encode(v)
        case let v as Int:    try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        default:              try c.encodeNil()
        }
    }
}

extension ChatRoomV1DTO {
    func toChatRoom() -> ChatRoom {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let lastMsg = Self.previewText(latestMessage)
        let lastDateStr = latestMessage?["created_at"]?.value as? String ?? updatedAt ?? ""
        let lastDate = df.date(from: lastDateStr) ?? Date()
        let createdDate = df.date(from: createdAt ?? "") ?? Date()
        // 서버 enum은 trip_group | direct
        let isGroup = roomType == "trip_group"

        let name: String
        if let subject, !subject.isEmpty { name = subject }
        else if let tn = touristName     { name = tn }
        else                             { name = "채팅" }

        return ChatRoom(
            serverId: id,
            threadSubject: subject,
            status: nil,
            participantName: name,
            participantType: roomType ?? "direct",
            isGroupChat: isGroup,
            tripId: trip,
            lastMessage: lastMsg,
            lastMessageDate: lastDate,
            unreadCount: unreadCount,
            isOnline: false,
            createdAt: createdDate
        )
    }

    /// 목록 미리보기 — 본문이 없는 첨부 메시지는 '사진' · '음성 메시지' · '동영상'
    static func previewText(_ latest: [String: AnyCodable]?) -> String {
        guard let latest else { return "" }
        if let body = latest["body"]?.value as? String, !body.isEmpty { return body }

        var mediaTypes: [String] = []
        if let list = latest["attachments"]?.value as? [Any] {
            mediaTypes = list.compactMap {
                ($0 as? [String: Any])?["media_type"] as? String
                    ?? ($0 as? [String: AnyCodable])?["media_type"]?.value as? String
            }
        }
        let type = mediaTypes.first ?? (latest["message_type"]?.value as? String) ?? ""
        switch type {
        case "photo", "image":  return "사진"
        case "audio", "voice":  return "음성 메시지"
        case "video":           return "동영상"
        case "attachment":      return "첨부 파일"
        default:                return ""
        }
    }
}

extension ChatMessageV1DTO {

    /// - Parameters:
    ///   - currentUserId: Keychain의 내 사용자 id
    ///   - currentRole: 내 역할("tourist" | "staff") — 내 말풍선 판정 기준.
    ///     여행객 앱과 관리자 앱이 같은 방을 보므로 역할을 고정하면 안 됩니다.
    ///   - myChatUserId: 서버 메시지의 sender로 오는 내 사용자 id (여행객은 보낸 메시지 응답에서 알게 됨)
    ///   - myName: 아직 id를 모를 때 쓰는 내 이름
    func toMessage(
        chatRoomId: UUID, currentUserId: String, currentRole: String,
        myChatUserId: Int? = nil, myName: String? = nil
    ) -> Message {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let sentAt = df.date(from: createdAt ?? "") ?? Date()

        // 서버 sender_role은 tourist | manager | admin 입니다. 앱 역할은 tourist | staff라
        // 그대로 비교하면 안내사가 보낸 메시지가 상대 말풍선으로 보였습니다.
        let senderSide = (senderRole == "tourist") ? "tourist" : "staff"
        // 안내사는 한 방에 여러 명일 수 있어 보낸 사람 id까지 맞아야 내 메시지입니다
        let isMine: Bool = {
            guard senderSide == currentRole else { return false }
            if currentRole == "staff", let sender { return String(sender) == currentUserId }
            // 여행객: 단체방에는 다른 여행객도 있어 역할만으로는 구분이 안 됩니다
            if let myChatUserId, let sender { return sender == myChatUserId }
            if let myName, !myName.isEmpty, let senderName { return senderName == myName }
            return true
        }()
        let senderId = isMine ? currentUserId : "\(senderRole ?? "peer")_\(sender ?? 0)"
        let name = senderName ?? (isMine ? "나" : "상대방")

        return Message(
            serverId: id,
            senderType: senderRole ?? currentRole,
            chatRoomId: chatRoomId,
            senderId: senderId,
            senderName: name,
            content: body,
            sentAt: sentAt,
            sendStatus: .sent,
            attachments: (attachments ?? []).map { $0.toAttachment() }
        )
    }
}

// MARK: - 주변 스팟 (상황별 검색)

/// GET /api/v1/tourist/nearby-spots/
struct TravelerNearbySpotsResponseDTO: Decodable {
    let category: String?
    let categoryLabel: String?
    let totalCount: Int?
    let count: Int?
    let results: [TravelerNearbySpotDTO]
}

struct TravelerNearbySpotDTO: Decodable, Identifiable, Hashable {
    /// 외부 제공자(카카오) 장소 id — 목록 식별자로 씁니다
    let providerObjectId: String
    let name: String
    let categoryName: String?
    let categoryGroupCode: String?
    let categoryGroupName: String?
    let phone: String?
    let address: String?
    let roadAddress: String?
    let placeUrl: String?
    let distanceM: Int?
    /// 서버 명세는 문자열이지만 실제로는 숫자로 옵니다 — 둘 다 받습니다
    let lat: FlexibleDouble?
    let lng: FlexibleDouble?
    let isSponsored: Bool?
    let imageUrl: String?
    let description: String?

    var id: String { providerObjectId }

    var latitude: Double? { lat?.value }
    var longitude: Double? { lng?.value }

    /// "0.4km" — 1km 미만은 m로 보여줍니다
    var distanceText: String? {
        guard let distanceM else { return nil }
        if distanceM < 1000 { return "\(distanceM)m" }
        return String(format: "%.1fkm", Double(distanceM) / 1000)
    }
}

// MARK: - 안전(지오펜스)

/// GET /api/v1/tourist/safety/summary/ — 필요한 부분만 받습니다
struct TravelerSafetySummaryDTO: Decodable {
    let tripId: Int?
    let dayNumber: Int?
    let geofence: TravelerGeofenceDTO?
}

struct TravelerGeofenceDTO: Decodable {
    /// 명세는 문자열 — 주변 스팟처럼 숫자로 올 수도 있어 둘 다 받습니다
    let centerLat: FlexibleDouble?
    let centerLng: FlexibleDouble?
    let radiusKm: FlexibleDouble?

    var latitude: Double? { centerLat?.value }
    var longitude: Double? { centerLng?.value }
    /// 미터
    var radiusM: Double? { radiusKm?.value.map { $0 * 1000 } }
}

// MARK: - FlexibleDouble

/// 숫자·문자열 어느 쪽으로 와도 받는 실수
///
/// 서버 명세상 좌표·반경은 문자열(decimal)인데, 주변 스팟 응답은 실제로 숫자(37.5665…)를 줍니다.
/// 한쪽 형식만 받으면 목록 전체가 해석에 실패하므로 둘 다 허용합니다. 해석할 수 없으면 nil.
struct FlexibleDouble: Decodable, Hashable, ExpressibleByStringLiteral {
    let value: Double?

    /// Mock 데이터에서 `"33.499621"`처럼 문자열로 바로 만들 수 있게 합니다
    init(stringLiteral text: String) {
        value = Double(text)
    }

    /// Mock에서 계산한 좌표를 그대로 넣을 때
    init(_ number: Double) {
        value = number
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            value = number
        } else if let text = try? container.decode(String.self) {
            value = Double(text.trimmingCharacters(in: .whitespaces))
        } else {
            value = nil
        }
    }
}
