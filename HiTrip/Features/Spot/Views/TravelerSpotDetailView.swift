import SwiftUI

// MARK: - TravelerSpotDetailView
/// 서버 추천/인기 스팟 상세 화면 (Sheet)
///
/// 피그마 0827 수정본:
/// - 헤더 이미지 → 이름 + 카테고리 태그 → 거리/영업시간
/// - 어드벤티지 카드 (있는 경우)
/// - 장소 설명
/// - 주소 (복사 버튼)
/// - 하단 고정 "길찾기" 버튼 (카카오맵 딥링크)
/// ✂️ 제거: 별점, 리뷰수, 카카오맵 URL 행

struct TravelerSpotDetailView: View {

    let spot: TravelerSpotDTO
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerImage

                    VStack(alignment: .leading, spacing: HiTripSpacing.xl) {
                        titleSection
                        Divider()
                        if !spot.reason.isEmpty {
                            AdvantageCardView(
                                title: spot.reason,
                                description: "이용 시 가이드에게 보여 주세요"
                            )
                        }
                        if !spot.description.isEmpty {
                            descriptionSection
                        }
                        if let address = spot.place.address, !address.isEmpty {
                            addressRow(address)
                        }
                    }
                    .padding(HiTripSpacing.pagePadding)
                }
            }
            .safeAreaInset(edge: .bottom) {
                findRouteButton
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

    // MARK: - Header Image

    private var headerImage: some View {
        Group {
            if !spot.imageUrl.isEmpty, let url = URL(string: spot.imageUrl) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipped()
    }

    private var placeholderImage: some View {
        ZStack {
            HiTripColor.gray100
            Image(systemName: spotIcon)
                .font(.system(size: 44))
                .foregroundColor(HiTripColor.gray300)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
            // 카테고리 태그
            if let cat = spot.place.categoryName, !cat.isEmpty {
                categoryTag(cat)
            }

            Text(spot.title)
                .font(HiTripFont.title1)
                .foregroundColor(HiTripColor.textBlack)

            // 거리 + 영업중
            HStack(spacing: HiTripSpacing.sm) {
                Text("영업중")
                    .font(HiTripFont.captionM)
                    .foregroundColor(HiTripColor.onlineGreen)
                if let addr = spot.place.address {
                    Text("·")
                        .foregroundColor(HiTripColor.gray300)
                    Text(addr)
                        .font(HiTripFont.caption)
                        .foregroundColor(HiTripColor.gray500)
                        .lineLimit(1)
                }
            }
        }
    }

    private func categoryTag(_ text: String) -> some View {
        Text(text)
            .font(HiTripFont.captionM)
            .foregroundColor(HiTripColor.gray500)
            .padding(.horizontal, HiTripSpacing.smd)
            .padding(.vertical, HiTripSpacing.xs)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.sm)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        Text(spot.description)
            .font(HiTripFont.body)
            .foregroundColor(HiTripColor.textGrayA)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(4)
    }

    // MARK: - Address Row

    private func addressRow(_ address: String) -> some View {
        HStack(alignment: .top, spacing: HiTripSpacing.md) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
                .frame(width: 20)
            Text(address)
                .font(HiTripFont.body)
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            Button {
                UIPasteboard.general.string = address
            } label: {
                Text("복사")
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.primary800)
            }
        }
    }

    // MARK: - Find Route Button

    private var findRouteButton: some View {
        Button {
            let lat = spot.place.latitude
            let lng = spot.place.longitude
            if let url = URL(string: "kakaomap://look?p=\(lat),\(lng)") {
                UIApplication.shared.open(url)
            }
        } label: {
            Text("길찾기")
                .font(HiTripFont.bodyLBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HiTripSpacing.lg)
                .background(HiTripColor.primary800)
                .cornerRadius(HiTripRadius.button)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HiTripSpacing.pagePadding)
        .padding(.vertical, HiTripSpacing.md)
        .background(Color.white)
    }

    // MARK: - Helpers

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
