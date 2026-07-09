import Foundation

// MARK: - MapCategory

enum MapCategory: String, CaseIterable, Identifiable {
    case accessible  = "무장애"
    case petFriendly = "반려동물"
    case halal       = "할랄"
    case convenience = "편의점"
    case mart        = "마트"
    case restaurant  = "음식점"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .accessible:  return "♿"
        case .petFriendly: return "🐾"
        case .halal:       return "🌙"
        case .convenience: return "🏪"
        case .mart:        return "🛒"
        case .restaurant:  return "🍽️"
        }
    }

    /// Kakao Local API 카테고리 코드 (nil이면 키워드 검색)
    var kakaoCode: String? {
        switch self {
        case .convenience: return "CS2"
        case .mart:        return "MT1"
        case .restaurant:  return "FD6"
        default:           return nil
        }
    }

    /// 카테고리 코드가 없는 경우 사용할 검색 키워드
    var keyword: String? {
        switch self {
        case .accessible:  return "무장애 관광"
        case .petFriendly: return "반려동물 동반"
        case .halal:       return "할랄"
        default:           return nil
        }
    }
}

// MARK: - MapPlaceItem

struct MapPlaceItem: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let category: String?
    let isOfficialSpot: Bool  // 안내사가 등록한 공식 스팟
    let placeUrl: String?

    static func == (lhs: MapPlaceItem, rhs: MapPlaceItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Conversions

extension KakaoLocalPlace {
    func toMapPlaceItem() -> MapPlaceItem {
        MapPlaceItem(
            id: id,
            name: placeName,
            address: roadAddressName.isEmpty ? addressName : roadAddressName,
            latitude: Double(y) ?? 0,
            longitude: Double(x) ?? 0,
            category: categoryName,
            isOfficialSpot: false,
            placeUrl: placeUrl.isEmpty ? nil : placeUrl
        )
    }
}

extension TravelerMapPlaceDTO {
    func toMapPlaceItem() -> MapPlaceItem {
        MapPlaceItem(
            id: "official_\(id)",
            name: name,
            address: address,
            latitude: Double(latitude) ?? 0,
            longitude: Double(longitude) ?? 0,
            category: nil,
            isOfficialSpot: true,
            placeUrl: nil
        )
    }
}
