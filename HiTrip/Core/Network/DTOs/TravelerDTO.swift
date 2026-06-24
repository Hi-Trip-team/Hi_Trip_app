import Foundation

// MARK: - Auth

struct TravelerLoginRequest: Encodable {
    let phone: String
    let birthDate: String       // "yyyy-MM-dd"
    let inviteCode: String
}

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
}

extension TravelerTripDTO {

    func toTripPackage() -> TripPackage {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")

        return TripPackage(
            name: title,
            startDate: df.date(from: startDate) ?? Date(),
            endDate: df.date(from: endDate) ?? Date(),
            destination: destination
        )
    }

    func toTrip() -> Trip {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")

        return Trip(
            serverId: id,
            title: title,
            date: df.date(from: startDate) ?? Date(),
            location: destination,
            status: status
        )
    }
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

struct TravelerAgreementUpdateRequest: Encodable {
    let termsAccepted: Bool
    let locationPermissionAccepted: Bool?
    let notificationPermissionAccepted: Bool?
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

extension TravelerScheduleDTO {

    func toOfficialSchedule(for date: Date) -> TripOfficialSchedule {
        let start = parseTime(startTime, on: date)
        let end = parseTime(endTime, on: date)

        let emoji: String
        switch transport {
        case "도보":     emoji = "🚶"
        case "전용버스":  emoji = "🚌"
        case "자가용":   emoji = "🚗"
        case "공항버스":  emoji = "✈️"
        case "택시":     emoji = "🚕"
        default:        emoji = "📍"
        }

        let displayTitle: String
        if let pn = placeName, let mc = mainContent, !mc.isEmpty {
            displayTitle = "\(pn) — \(mc)"
        } else {
            displayTitle = placeName ?? mainContent ?? "일정"
        }

        return TripOfficialSchedule(
            emoji: emoji,
            title: displayTitle,
            startTime: start,
            endTime: end,
            date: date,
            placeName: placeName,
            mainContent: mainContent,
            meetingPoint: meetingPoint,
            transport: transport,
            durationDisplay: durationDisplay,
            dayNumber: dayNumber
        )
    }

    private func parseTime(_ timeString: String, on date: Date) -> Date {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        if parts.count >= 2 {
            return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date) ?? date
        }
        return date
    }
}

// MARK: - Calendar

struct TravelerCalendarDTO: Decodable {
    let trip: TravelerTripDTO
    let days: [TravelerCalendarDayDTO]
}

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

struct TravelerChecklistStatusUpdateRequest: Encodable {
    let isChecked: Bool
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

struct TravelerMessageThreadCreateRequest: Encodable {
    let subject: String
    let body: String
}

struct TravelerMessageCreateRequest: Encodable {
    let body: String
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
    let createdAt: String?
    let updatedAt: String?
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

struct TravelerManagerContactDTO: Decodable {
    let manager: [String: String]?
}

// MARK: - Emergency Request

struct TravelerEmergencyRequestCreateRequest: Encodable {
    let message: String
    let latitude: String?
    let longitude: String?
    let accuracyM: String?
}

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

struct TravelerProfileUpdateRequest: Encodable {
    let lastNameKr: String?
    let firstNameKr: String?
    let firstNameEn: String?
    let lastNameEn: String?
    let phone: String?
    let email: String?
    let address: String?
    let country: String?
}

// MARK: - DTO → Domain Model Conversions

extension TravelerChecklistItemDTO {
    func toTripTodo(tripId: UUID) -> TripTodo {
        TripTodo(
            serverId: id,
            title: title,
            subtitle: description.isEmpty ? nil : description,
            isCompleted: isChecked,
            displayOrder: displayOrder,
            tripId: tripId
        )
    }
}

extension TravelerNoticeDTO {
    func toTripNotice() -> TripNotice {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = df.date(from: publishedAt ?? createdAt ?? "") ?? Date()
        return TripNotice(
            title: title,
            content: content,
            date: date,
            isImportant: priority == "important",
            isRepresentative: priority == "important"
        )
    }
}


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
            isRead: true
        )
    }
}
