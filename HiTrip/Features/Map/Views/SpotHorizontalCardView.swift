import SwiftUI

// MARK: - SpotHorizontalCardView
/// 주변 인기 스팟 지도 하단에 표시되는 가로 스크롤 카드 (단일 아이템)

struct SpotHorizontalCardView: View {

    let place: MapPlaceItem
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: HiTripSpacing.md) {
                // 썸네일
                thumbnailImage
                    .frame(width: 80, height: 80)
                    .cornerRadius(HiTripRadius.sm)
                    .clipped()

                // 텍스트
                VStack(alignment: .leading, spacing: HiTripSpacing.xs) {
                    Text(place.name)
                        .font(HiTripFont.bodyBold)
                        .foregroundColor(HiTripColor.textBlack)
                        .lineLimit(1)

                    if let distance = distanceText {
                        HStack(spacing: HiTripSpacing.xs) {
                            Text(distance)
                                .font(HiTripFont.caption)
                                .foregroundColor(HiTripColor.gray500)

                            Text("·")
                                .font(HiTripFont.caption)
                                .foregroundColor(HiTripColor.gray300)

                            Text("영업중")
                                .font(HiTripFont.caption)
                                .foregroundColor(HiTripColor.onlineGreen)
                        }
                    }

                    if let address = place.address, !address.isEmpty {
                        Text(address)
                            .font(HiTripFont.caption)
                            .foregroundColor(HiTripColor.gray500)
                            .lineLimit(1)
                    }

                    if let category = place.category, !category.isEmpty {
                        Text(category)
                            .font(HiTripFont.caption)
                            .foregroundColor(HiTripColor.gray400)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(HiTripSpacing.cardPadding)
            .frame(width: 300)
            .background(Color.white)
            .cornerRadius(HiTripRadius.card)
            .shadow(
                color: Color(hex: "B4BCC9").opacity(0.25),
                radius: HiTripShadow.cardRadius,
                y: HiTripShadow.cardY
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailImage: some View {
        ZStack {
            HiTripColor.gray100
            if let urlStr = place.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "photo")
            .font(.system(size: 20))
            .foregroundColor(HiTripColor.gray300)
    }

    private var distanceText: String? {
        guard let d = place.distanceMeters else { return nil }
        return d >= 1000 ? String(format: "%.1fkm", Double(d) / 1000) : "\(d)m"
    }
}
