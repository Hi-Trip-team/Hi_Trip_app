import SwiftUI
import CoreLocation

// MARK: - NearbyMapView
/// 주변 인기 스팟 — 지도 중심 레이아웃
///
/// 피그마 0827 수정본 기준:
/// - 헤더: 타이틀 + 카테고리 칩
/// - 상태 칩: GPS 정확도 + 안전 구역 범례
/// - 지도 (화면 대부분, 안전 구역 빨간 점선 원 오버레이)
/// - 하단: 가로 스크롤 스팟 카드

struct NearbyMapView: View {

    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            // 지도 전체 배경
            mapSection
                .ignoresSafeArea(edges: .bottom)

            // 상단 오버레이 (타이틀 + 칩)
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.lg)
                    .padding(.bottom, HiTripSpacing.smd)
                    .background(Color.white.opacity(0.95))

                categoryBar
                    .padding(.bottom, HiTripSpacing.smd)
                    .background(Color.white.opacity(0.95))

                statusChips
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.bottom, HiTripSpacing.sm)
                    .background(Color.white.opacity(0.95))

                Spacer()

                // 하단 가로 스크롤 카드
                spotScrollSection
                    .padding(.bottom, HiTripSpacing.xl)
            }

            // GPS 버튼 (지도 오른쪽 중간)
            gpsButton
                .padding(.trailing, HiTripSpacing.md)
                .padding(.bottom, 200)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear  { viewModel.drawMap = true  }
        .onDisappear { viewModel.drawMap = false }
        .sheet(item: $viewModel.selectedPlace) { place in
            PlaceDetailSheet(place: place)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("주변 인기 스팟")
                .font(HiTripFont.title1)
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            if viewModel.isLoading {
                ProgressView().scaleEffect(0.8)
            }
        }
    }

    // MARK: - Category Chips

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HiTripSpacing.sm) {
                ForEach(MapCategory.allCases) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, HiTripSpacing.pagePadding)
        }
    }

    private func categoryChip(_ category: MapCategory) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.selectCategory(category)
        } label: {
            HStack(spacing: HiTripSpacing.xs) {
                Text(category.emoji).font(.system(size: 13))
                Text(category.rawValue)
                    .font(HiTripFont.labelM)
                    .foregroundColor(isSelected ? .white : HiTripColor.textBlack)
            }
            .padding(.horizontal, HiTripSpacing.md)
            .padding(.vertical, HiTripSpacing.xxs)
            .background(isSelected ? HiTripColor.primary800 : Color.white)
            .cornerRadius(HiTripRadius.pill)
            .shadow(
                color: Color(hex: "B4BCC9").opacity(0.30),
                radius: 4, y: 1
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Chips

    private var statusChips: some View {
        HStack(spacing: HiTripSpacing.sm) {
            statusChip(
                icon: "exclamationmark.triangle.fill",
                text: "GPS 정확도 낮음",
                color: HiTripColor.gpsLowAccuracy
            )
            statusChip(
                icon: "circle.dashed",
                text: "빨간 선 = 안전 구역 경계",
                color: HiTripColor.safeZoneBorder
            )
            Spacer()
        }
    }

    private func statusChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: HiTripSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(text)
                .font(HiTripFont.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, HiTripSpacing.sm)
        .padding(.vertical, HiTripSpacing.xs)
        .background(color.opacity(0.10))
        .cornerRadius(HiTripRadius.chip)
    }

    // MARK: - Map Section

    private var mapSection: some View {
        KakaoMapView(
            latitude: viewModel.mapCenter.latitude,
            longitude: viewModel.mapCenter.longitude,
            draw: $viewModel.drawMap,
            markers: viewModel.displayPlaces,
            userLocation: viewModel.currentLocation,
            radiusMeters: viewModel.allowedRadiusMeters,
            cameraTarget: viewModel.cameraTarget,
            zoomTrigger: viewModel.zoomTrigger
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .horizontal)
    }

    // MARK: - GPS Button

    private var gpsButton: some View {
        Button {
            viewModel.moveToCurrentLocation()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HiTripColor.primary800)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(
                    color: Color(hex: "B4BCC9").opacity(0.30),
                    radius: HiTripShadow.controlRadius,
                    y: HiTripShadow.controlY
                )
        }
    }

    // MARK: - Spot Horizontal Scroll

    private var spotScrollSection: some View {
        Group {
            if viewModel.displayPlaces.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HiTripSpacing.md) {
                        ForEach(viewModel.displayPlaces) { place in
                            SpotHorizontalCardView(place: place) {
                                viewModel.selectedPlace = place
                            }
                        }
                    }
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.vertical, HiTripSpacing.sm)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: HiTripSpacing.sm) {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 28))
                    .foregroundColor(HiTripColor.gray300)
                Text("주변 스팟이 없습니다")
                    .font(HiTripFont.body)
                    .foregroundColor(HiTripColor.gray400)
            }
            .padding(.vertical, HiTripSpacing.xl)
            Spacer()
        }
        .background(Color.white.opacity(0.9))
        .cornerRadius(HiTripRadius.lg)
        .padding(.horizontal, HiTripSpacing.pagePadding)
    }
}

// MARK: - PlaceDetailSheet (재사용)

struct PlaceDetailSheet: View {

    let place: MapPlaceItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 헤더 이미지
                    ZStack {
                        HiTripColor.gray200
                        if let urlStr = place.imageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    placeholderIcon
                                }
                            }
                        } else {
                            placeholderIcon
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()

                    VStack(alignment: .leading, spacing: HiTripSpacing.xl) {
                        // 타이틀 영역
                        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
                            HStack(spacing: HiTripSpacing.sm) {
                                if place.isOfficialSpot {
                                    Text("📍 공식 일정 스팟")
                                        .font(HiTripFont.captionM)
                                        .foregroundColor(HiTripColor.primary800)
                                        .padding(.horizontal, HiTripSpacing.smd)
                                        .padding(.vertical, HiTripSpacing.xs)
                                        .background(HiTripColor.primary800.opacity(0.12))
                                        .cornerRadius(HiTripRadius.sm)
                                }
                                if let cat = place.category, !cat.isEmpty {
                                    Text(cat)
                                        .font(HiTripFont.captionM)
                                        .foregroundColor(HiTripColor.gray500)
                                        .padding(.horizontal, HiTripSpacing.smd)
                                        .padding(.vertical, HiTripSpacing.xs)
                                        .background(HiTripColor.gray100)
                                        .cornerRadius(HiTripRadius.sm)
                                }
                            }

                            Text(place.name)
                                .font(HiTripFont.title1)
                                .foregroundColor(HiTripColor.textBlack)

                            if let dist = place.distanceMeters {
                                HStack(spacing: HiTripSpacing.xs) {
                                    let distStr = dist >= 1000
                                        ? String(format: "%.1fkm", Double(dist) / 1000)
                                        : "\(dist)m"
                                    Text(distStr)
                                        .font(HiTripFont.label)
                                        .foregroundColor(HiTripColor.gray500)
                                    Text("·")
                                        .foregroundColor(HiTripColor.gray300)
                                    Text("영업중")
                                        .font(HiTripFont.label)
                                        .foregroundColor(HiTripColor.onlineGreen)
                                }
                            }
                        }

                        Divider()

                        // 주소
                        if let address = place.address, !address.isEmpty {
                            infoRow(icon: "mappin.and.ellipse", value: address, copyable: true)
                        }

                        // 카카오맵 URL
                        if let url = place.placeUrl, !url.isEmpty {
                            infoRow(icon: "link", value: url)
                        }
                    }
                    .padding(HiTripSpacing.pagePadding)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 길찾기 버튼
                Button {
                    if let lat = Optional(place.latitude),
                       let lng = Optional(place.longitude),
                       let url = URL(string: "kakaomap://look?p=\(lat),\(lng)") {
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

    private var placeholderIcon: some View {
        Image(systemName: "photo")
            .font(.system(size: 40))
            .foregroundColor(HiTripColor.gray300)
    }

    private func infoRow(icon: String, value: String, copyable: Bool = false) -> some View {
        HStack(alignment: .top, spacing: HiTripSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
                .frame(width: 20)
            Text(value)
                .font(HiTripFont.body)
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            if copyable {
                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Text("복사")
                        .font(HiTripFont.caption)
                        .foregroundColor(HiTripColor.primary800)
                }
            }
        }
    }
}
