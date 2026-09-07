import Foundation

// MARK: - Staff DTOs
/// 관리자 API 응답 DTO — Hi Trip API v1.0.0 스키마 기준
///
/// 서버가 상태 판정(normal/warning/danger/…)과 집계를 모두 내려주므로
/// 앱에서 임계값을 다시 계산하지 않습니다.

/// 본문이 없거나 무시해도 되는 응답용
struct EmptyResponse: Decodable {
    init() {}
    init(from decoder: Decoder) throws {}
}

// MARK: - 프로필

struct StaffProfileDTO: Decodable {
    let id: Int
    let username: String
    let email: String
    let phone: String
    let travelAgencyName: String
    let fullNameKr: String
    let fullNameEn: String
    let roleDisplay: String
    let isActive: Bool
    let isApproved: Bool

    enum CodingKeys: String, CodingKey {
        case id, username, email, phone
        case travelAgencyName = "travel_agency_name"
        case fullNameKr = "full_name_kr"
        case fullNameEn = "full_name_en"
        case roleDisplay = "role_display"
        case isActive = "is_active"
        case isApproved = "is_approved"
    }
}

struct CSRFTokenDTO: Decodable {
    let csrfToken: String
}

// MARK: - 여행

struct StaffTripDTO: Decodable {
    let id: Int
    let title: String
    let destination: String
    let startDate: String
    let endDate: String
    let managerName: String
    let participantCount: Int

    /// 여행별 안전 임계값 — 서버 설정값
    let heartRateMin: Int?
    let heartRateMax: Int?
    let spo2Min: String?

    let geofenceCenterLat: String?
    let geofenceCenterLng: String?
    let geofenceRadiusKm: String?

    enum CodingKeys: String, CodingKey {
        case id, title, destination
        case startDate = "start_date"
        case endDate = "end_date"
        case managerName = "manager_name"
        case participantCount = "participant_count"
        case heartRateMin = "heart_rate_min"
        case heartRateMax = "heart_rate_max"
        case spo2Min = "spo2_min"
        case geofenceCenterLat = "geofence_center_lat"
        case geofenceCenterLng = "geofence_center_lng"
        case geofenceRadiusKm = "geofence_radius_km"
    }
}

// MARK: - 일정

struct StaffScheduleDTO: Decodable {
    let id: Int
    let trip: Int
    let dayNumber: Int
    let startTime: String
    let endTime: String
    let durationMinutes: Int
    let placeName: String
    let durationDisplay: String
    let transport: String?
    let mainContent: String?
    let meetingPoint: String?
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case id, trip, transport, order
        case dayNumber = "day_number"
        case startTime = "start_time"
        case endTime = "end_time"
        case durationMinutes = "duration_minutes"
        case placeName = "place_name"
        case durationDisplay = "duration_display"
        case mainContent = "main_content"
        case meetingPoint = "meeting_point"
    }
}

// MARK: - 모니터링 (안전 관리)

/// 안전 현황 요약 — 상단 pill
struct MonitoringSummaryDTO: Decodable {
    let total: Int
    let safe: Int
    let warning: Int
    let danger: Int
    let stale: Int
    let offline: Int
    let unknown: Int
}

/// 상태 값 — 서버 판정 결과
enum MonitoringStatus: String, Decodable {
    case normal, warning, danger, stale, offline, unknown

    /// 알 수 없는 값이 와도 앱이 죽지 않도록
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = MonitoringStatus(rawValue: raw) ?? .unknown
    }
}

struct HealthSnapshotDTO: Decodable {
    let heartRate: Int?
    let spo2: String?
    let measuredAt: String?

    enum CodingKeys: String, CodingKey {
        case heartRate = "heart_rate"
        case spo2
        case measuredAt = "measured_at"
    }
}

struct LocationSnapshotDTO: Decodable {
    let latitude: String?
    let longitude: String?
    let accuracyM: String?
    let measuredAt: String?

    enum CodingKeys: String, CodingKey {
        case latitude, longitude
        case accuracyM = "accuracy_m"
        case measuredAt = "measured_at"
    }
}

/// 사고 요약 — 이탈 거리/사유가 여기 담김
struct IncidentSummaryDTO: Decodable {
    let id: Int
    let travelerName: String
    /// heart_rate | heart_zero | spo2 | geofence
    let incidentType: String
    /// warning | danger
    let severity: String
    /// open | recovered
    let status: String
    let reasonCode: String
    let message: String
    let openedAt: String?
    let acknowledgedAt: String?

    var isGeofence: Bool { incidentType == "geofence" }
    var isOpen: Bool { status == "open" }

    enum CodingKeys: String, CodingKey {
        case id, severity, status, message
        case travelerName = "traveler_name"
        case incidentType = "incident_type"
        case reasonCode = "reason_code"
        case openedAt = "opened_at"
        case acknowledgedAt = "acknowledged_at"
    }
}

/// 참가자별 최신 상태 — 안전관리 테이블 한 행
struct ParticipantLatestDTO: Decodable {
    let participantId: Int
    let travelerName: String
    let tripId: Int
    let health: HealthSnapshotDTO?
    let location: LocationSnapshotDTO?
    let healthStatus: MonitoringStatus
    let locationStatus: MonitoringStatus
    let overallStatus: MonitoringStatus
    let activeIncidents: [IncidentSummaryDTO]

    /// 이탈 사고 (있으면 이탈여부 셀에 표시)
    var geofenceIncident: IncidentSummaryDTO? {
        activeIncidents.first { $0.isGeofence && $0.isOpen }
    }

    enum CodingKeys: String, CodingKey {
        case health, location
        case participantId = "participant_id"
        case travelerName = "traveler_name"
        case tripId = "trip_id"
        case healthStatus = "health_status"
        case locationStatus = "location_status"
        case overallStatus = "overall_status"
        case activeIncidents = "active_incidents"
    }
}

/// 경보 — 알림 센터 한 행
struct MonitoringAlertDTO: Decodable {
    let id: Int
    let travelerName: String
    let tripId: Int
    /// health | location
    let alertType: String
    /// warning | danger
    let severity: String
    let reasonCode: String
    let incident: Int?
    let message: String
    let snapshotTime: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, severity, message, incident
        case travelerName = "traveler_name"
        case tripId = "trip_id"
        case alertType = "alert_type"
        case reasonCode = "reason_code"
        case snapshotTime = "snapshot_time"
        case createdAt = "created_at"
    }
}

// MARK: - 공지

struct StaffNoticeDTO: Decodable {
    let id: Int
    /// global | trip
    let scope: String?
    let trip: Int?
    let tripTitle: String
    let authorName: String
    let title: String
    let content: String
    /// normal | important
    let priority: String?
    let publishedAt: String?
    let isActive: Bool
    let readCount: Int
    let audienceCount: Int
    let unreadCount: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, scope, trip, title, content, priority
        case tripTitle = "trip_title"
        case authorName = "author_name"
        case publishedAt = "published_at"
        case isActive = "is_active"
        case readCount = "read_count"
        case audienceCount = "audience_count"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
    }
}

// MARK: - 안전 구역 (지도 범위 설정)

struct GeofenceDTO: Decodable {
    let id: Int
    let trip: Int
    let dayNumber: Int
    /// 낙관적 잠금 — 수정 시 expected_revision으로 되돌려 보내야 함
    let revision: Int
    let isActive: Bool
    let centerLat: String
    let centerLng: String
    let centerAddress: String?
    let radiusKm: Int
    let updatedByName: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, trip, revision
        case dayNumber = "day_number"
        case isActive = "is_active"
        case centerLat = "center_lat"
        case centerLng = "center_lng"
        case centerAddress = "center_address"
        case radiusKm = "radius_km"
        case updatedByName = "updated_by_name"
        case updatedAt = "updated_at"
    }
}


// MARK: - 참가자 명부

/// GET /api/v1/trips/{trip_pk}/participants/
///
/// 관광객 정보 팝업의 국가·여권번호·전화번호는 여기서 옵니다.
/// 모니터링 응답(ParticipantLatest)에는 이름만 있어 participant id로 이어 붙입니다.
struct TripParticipantDTO: Decodable {
    let id: Int
    let trip: Int?
    let traveler: TravelerDetailDTO?
    let joinedDate: String?

    enum CodingKeys: String, CodingKey {
        case id, trip, traveler
        case joinedDate = "joined_date"
    }
}

struct TravelerDetailDTO: Decodable {
    let id: Int
    let fullNameKr: String?
    let phone: String?
    let country: String?
    let passportNumber: String?

    enum CodingKeys: String, CodingKey {
        case id, phone, country
        case fullNameKr = "full_name_kr"
        case passportNumber = "passport_number"
    }

    /// "DND***000" — 중간 3자리를 가립니다
    var maskedPassport: String? {
        guard let raw = passportNumber, raw.count >= 6 else { return passportNumber }
        let chars = Array(raw)
        let head = String(chars[0..<3])
        let tail = String(chars[(chars.count - 3)...])
        return head + "***" + tail
    }
}
