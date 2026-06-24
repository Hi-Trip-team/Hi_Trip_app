import SwiftUI

// MARK: - TravelerSpotDetailView
/// 서버 추천/인기 스팟 상세 화면 (Sheet)
///
/// TravelerSpotDTO 기반 — 여행사가 등록한 추천 장소 정보 표시.
/// 이름, 추천 이유, 주소, 이미지, 카테고리 포함.

struct TravelerSpotDetailView: View {

    let spot: TravelerSpotDTO
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 헤더 이미지
                    headerImage

                    VStack(alignment: .leading, spacing: 20) {
                        // 이름 + 유형 뱃지
                        titleSection

                        Divider()

                        // 추천 이유
                        if !spot.reason.isEmpty {
                            infoBlock(icon: "star.fill", color: .orange, title: "추천 이유", content: spot.reason)
                        }

                        // 설명
                        if !spot.description.isEmpty {
                            infoBlock(icon: "text.alignleft", color: HiTripColor.primary800, title: "소개", content: spot.description)
                        }

                        // 주소
                        if let address = spot.place.address, !address.isEmpty {
                            infoRow(icon: "mappin.and.ellipse", title: "주소", content: address)
                        }

                        // 카테고리
                        if let category = spot.place.categoryName {
                            infoRow(icon: "tag", title: "카테고리", content: category)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
            }
        }
    }

    // MARK: - 헤더 이미지

    private var headerImage: some View {
        Group {
            if let urlStr = spot.imageUrl.isEmpty ? nil : spot.imageUrl,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 220)
        .clipped()
    }

    private var placeholderImage: some View {
        ZStack {
            HiTripColor.gray200
            Image(systemName: spotIcon)
                .font(.system(size: 44))
                .foregroundColor(HiTripColor.gray400)
        }
    }

    // MARK: - 제목 섹션

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 유형 뱃지
            Text(spot.spotType == "recommended" ? "🌟 추천 장소" : "🔥 인기 장소")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(spot.spotType == "recommended" ? .orange : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (spot.spotType == "recommended" ? Color.orange : Color.red).opacity(0.1)
                )
                .cornerRadius(8)

            Text(spot.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
        }
    }

    // MARK: - 정보 블록 (여러 줄)

    private func infoBlock(icon: String, color: Color, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)
            }
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HiTripColor.screenBackground)
        .cornerRadius(12)
    }

    // MARK: - 정보 행 (한 줄)

    private func infoRow(icon: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.textBlack)
            }
        }
    }

    // MARK: - 아이콘 헬퍼

    private var spotIcon: String {
        switch spot.place.categoryName?.lowercased() ?? "" {
        case let c where c.contains("음식") || c.contains("식당") || c.contains("카페"):
            return "fork.knife"
        case let c where c.contains("숙박") || c.contains("호텔"):
            return "bed.double.fill"
        case let c where c.contains("관광") || c.contains("문화"):
            return "building.columns.fill"
        case let c where c.contains("쇼핑"):
            return "bag.fill"
        default:
            return "mappin.circle.fill"
        }
    }
}
