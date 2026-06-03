import Foundation

// MARK: - PlaceDTO
/// 백엔드 GET /api/places/ 응답 모델

struct PlaceDTO: Decodable, Identifiable {
    let id: Int
    let name: String
    let address: String?
    let category: PlaceCategoryDTO?
    let hasImage: Bool?
    let createdAt: String?
    let updatedAt: String?
    let aiMeetingPoint: String?
    let aiGeneratedInfo: String?
}

// MARK: - PlaceCategoryDTO

struct PlaceCategoryDTO: Decodable {
    let id: Int
    let name: String
    let order: Int?
}

// MARK: - PlaceDTO → TripNearbySpot 변환

extension PlaceDTO {

    func toNearbySpot() -> TripNearbySpot {
        // 카테고리 → 앱 내부 카테고리 매핑
        let categoryName: String
        switch category?.name.lowercased() {
        case "park", "garden":    categoryName = "leaf"
        case "beach":             categoryName = "beach"
        case "mountain", "hill":  categoryName = "mountain"
        case "water", "lake":     categoryName = "water"
        default:                  categoryName = "leaf"
        }

        return TripNearbySpot(
            name: name,
            distance: aiMeetingPoint ?? "",
            category: categoryName
        )
    }
}

// MARK: - RecommendationDTO
/// 백엔드 GET /api/recommendations/ 응답 모델

struct RecommendationDTO: Decodable, Identifiable {
    let id: Int
    let name: String
    let order: Int?
    let reason: String?
    let category: String?
    let colorTheme: String?
    let travelTimeMin: Int?
    let transportMethod: String?    // "WALK", "BUS", "TAXI" 등
}

// MARK: - RecommendationDTO → TripNearbySpot 변환

extension RecommendationDTO {

    func toNearbySpot() -> TripNearbySpot {
        // 이동 수단 + 시간 → 거리 텍스트
        let methodText: String
        switch transportMethod?.uppercased() {
        case "WALK":  methodText = "도보"
        case "BUS":   methodText = "버스"
        case "TAXI":  methodText = "택시"
        case "CAR":   methodText = "차량"
        default:      methodText = "이동"
        }
        let distance = travelTimeMin.map { "\(methodText) \($0)분" } ?? ""

        // 카테고리 매핑
        let cat: String
        switch category?.lowercased() {
        case "landmark", "historical landmarks": cat = "mountain"
        case "beach":                            cat = "beach"
        case "park", "nature":                   cat = "leaf"
        default:                                 cat = "leaf"
        }

        return TripNearbySpot(
            name: name,
            distance: distance,
            category: cat
        )
    }
}

// MARK: - CategoryDTO
/// 백엔드 GET /api/categories/ 응답 모델

struct CategoryDTO: Decodable, Identifiable {
    let id: Int
    let name: String
    let createdAt: String?
    let description: String?
}
