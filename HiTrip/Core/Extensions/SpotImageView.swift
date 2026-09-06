import SwiftUI

// MARK: - SpotImageView
/// 장소 이미지 — 없거나 실패하면 카테고리에 맞는 대체 아이콘을 보여줍니다.
///
/// 서버의 `image_url`이 현재 빈 문자열로 내려오는 경우가 있어,
/// 빈 값·잘못된 URL·로딩 실패를 모두 같은 대체 화면으로 처리합니다.
/// 깨진 이미지 아이콘 대신 카테고리 아이콘을 써서 의도된 화면처럼 보이게 합니다.

struct SpotImageView: View {

    let imageUrl: String?
    var categoryName: String?
    /// 아이콘 크기 — 썸네일(작게)과 상세 헤더(크게)에서 다르게 씁니다.
    var iconSize: CGFloat = 28

    var body: some View {
        ZStack {
            if let url = validURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack {
                            placeholderBackground
                            ProgressView().tint(Color(hex: "#9CA3AF"))
                        }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
    }

    private var validURL: URL? {
        guard let imageUrl, !imageUrl.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return URL(string: imageUrl)
    }

    // MARK: - 대체 화면

    private var placeholder: some View {
        ZStack {
            placeholderBackground
            Image(systemName: Self.icon(for: categoryName))
                .font(.system(size: iconSize, weight: .light))
                .foregroundColor(Color(hex: "#9CA3AF"))
        }
    }

    private var placeholderBackground: some View {
        Color(hex: "#D9DEE5")
    }

    // MARK: - 카테고리 매핑

    /// 카테고리명은 서버가 자유 문자열로 주므로 키워드 포함 여부로 판단합니다.
    static func icon(for category: String?) -> String {
        guard let c = category, !c.isEmpty else { return "mappin.and.ellipse" }

        switch true {
        case c.contains("해변"), c.contains("해수욕"), c.contains("바다"), c.contains("섬"):
            return "water.waves"
        case c.contains("산책"), c.contains("둘레"), c.contains("트레킹"):
            return "figure.walk"
        case c.contains("산"), c.contains("등산"), c.contains("자연"), c.contains("숲"):
            return "mountain.2"
        case c.contains("정원"), c.contains("공원"), c.contains("수목"):
            return "leaf"
        case c.contains("시장"), c.contains("쇼핑"), c.contains("상점"):
            return "bag"
        case c.contains("카페"), c.contains("디저트"):
            return "cup.and.saucer"
        case c.contains("음식"), c.contains("맛집"), c.contains("식당"):
            return "fork.knife"
        case c.contains("문화재"), c.contains("유적"), c.contains("박물관"), c.contains("사찰"), c.contains("고궁"):
            return "building.columns"
        case c.contains("숙소"), c.contains("호텔"), c.contains("리조트"):
            return "bed.double"
        case c.contains("전망"), c.contains("야경"):
            return "binoculars"
        default:
            return "mappin.and.ellipse"
        }
    }
}
