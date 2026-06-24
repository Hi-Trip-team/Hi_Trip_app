import Foundation

// MARK: - TripDTO
/// 백엔드 GET /api/trips/ 응답 모델
///
/// snake_case → camelCase 변환은 JSONDecoder.keyDecodingStrategy로 자동 처리
/// 이 DTO는 네트워크 레이어 전용이며, 앱 내부에서는 TripPackage/Trip 모델로 변환하여 사용

struct TripDTO: Decodable, Identifiable {
    let id: Int
    let title: String
    let status: String                  // "planning", "active", "completed"
    let manager: Int?
    let endDate: String?                // "2025-03-08" (Date only)
    let spo2Min: String?
    let createdAt: String?
    let startDate: String?              // "2025-03-08"
    let updatedAt: String?
    let destination: String?
    let inviteCode: String?
    let managerName: String?
    let heartRateMax: Int?
    let heartRateMin: Int?
    let participantCount: Int?
    let geofenceRadiusKm: String?
    let geofenceCenterLat: String?
    let geofenceCenterLng: String?
}

// MARK: - TripDTO → TripPackage 변환

extension TripDTO {

    /// DTO → 앱 내부 TripPackage 모델 변환
    func toTripPackage() -> TripPackage {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let start = dateFormatter.date(from: startDate ?? "") ?? Date()
        let end = dateFormatter.date(from: endDate ?? "") ?? Date()

        return TripPackage(
            id: UUID(),  // 서버 ID와 매핑 필요 시 별도 필드 추가
            name: title,
            startDate: start,
            endDate: end,
            destination: destination ?? "",
            totalParticipants: participantCount ?? 0,
            currentParticipants: participantCount ?? 0,
            weatherDescription: ""
        )
    }

    /// DTO → 앱 내부 Trip 모델 변환
    func toTrip() -> Trip {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let date = dateFormatter.date(from: startDate ?? "") ?? Date()

        return Trip(
            serverId: id,
            title: title,
            date: date,
            location: destination ?? "",
            thumbnailName: "mappin.circle.fill",
            memberAvatars: [],
            status: status,
            inviteCode: inviteCode
        )
    }
}

// MARK: - TripCreateRequest
/// POST /api/trips/ 요청 바디

struct TripCreateRequest: Encodable {
    let title: String
    let startDate: String          // "yyyy-MM-dd"
    let endDate: String
    let destination: String
    let participantCount: Int?
    let geofenceRadiusKm: String?
    let geofenceCenterLat: String?
    let geofenceCenterLng: String?
}
