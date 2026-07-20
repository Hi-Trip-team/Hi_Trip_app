import SwiftUI
import CoreLocation

// MARK: - NearbyMapView
/// 지도 탭 메인 화면
///
/// 구성:
/// - 풀스크린 KakaoMap (허용 반경 + 마커)
/// - 상단: 페이지 제목 + 카테고리 필터 칩
/// - 우하단: GPS 버튼
/// - 하단: 장소 카드 가로 스크롤

struct NearbyMapView: View {

    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: 풀스크린 지도
            KakaoMapView(
                latitude: viewModel.mapCenter.latitude,
                longitude: viewModel.mapCenter.longitude,
                draw: $viewModel.drawMap,
                markers: viewModel.displayPlaces,
                userLocation: viewModel.currentLocation,
                radiusMeters: viewModel.allowedRadiusMeters,
                cameraTarget: viewModel.cameraTarget
            )
            .ignoresSafeArea()

            // MARK: 상단 오버레이
            VStack(spacing: 0) {
                titleBar
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                categoryBar
                    .padding(.top, 8)

                Spacer()

                // MARK: 하단 GPS + 카드
                VStack(spacing: 8) {
                    gpsButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 16)

                    if !viewModel.displayPlaces.isEmpty {
                        placeCardScroll
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("지도")
        .navigationBarHidden(true)
        .onAppear  { viewModel.drawMap = true }
        .onDisappear { viewModel.drawMap = false }
        .sheet(item: $viewModel.selectedPlace) { place in
            PlaceDetailSheet(place: place)
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Text("주변 인기 스팟")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    // MARK: - Category Filter

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapCategory.allCases) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func categoryChip(_ category: MapCategory) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.selectCategory(category)
        } label: {
            HStack(spacing: 4) {
                Text(category.emoji)
                    .font(.system(size: 13))
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : HiTripColor.textBlack)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? HiTripColor.primary800 : Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - GPS Button

    private var gpsButton: some View {
        Button {
            viewModel.moveToCurrentLocation()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18))
                .foregroundColor(HiTripColor.primary800)
                .frame(width: 46, height: 46)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.14), radius: 6, y: 2)
        }
    }

    // MARK: - Place Card Scroll

    private var placeCardScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.displayPlaces) { place in
                    PlaceCardView(place: place)
                        .onTapGesture { viewModel.selectedPlace = place }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - PlaceCardView

struct PlaceCardView: View {

    let place: MapPlaceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 썸네일
            ZStack {
                HiTripColor.gray200
                Image(systemName: place.isOfficialSpot ? "mappin.circle.fill" : "mappin.and.ellipse")
                    .font(.system(size: 28))
                    .foregroundColor(place.isOfficialSpot ? HiTripColor.primary800 : .orange)
            }
            .frame(width: 155, height: 95)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                if place.isOfficialSpot {
                    Text("📍 공식 스팟")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(HiTripColor.primary800)
                }
                Text(place.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)
                    .lineLimit(1)

                if let category = place.category, !category.isEmpty {
                    Text(category)
                        .font(.system(size: 11))
                        .foregroundColor(HiTripColor.gray400)
                        .lineLimit(1)
                }
                if let address = place.address, !address.isEmpty {
                    Text(address)
                        .font(.system(size: 11))
                        .foregroundColor(HiTripColor.gray400)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 155)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

// MARK: - PlaceDetailSheet

struct PlaceDetailSheet: View {

    let place: MapPlaceItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 헤더 이미지 영역
                    ZStack {
                        HiTripColor.gray200
                        Image(systemName: place.isOfficialSpot ? "mappin.circle.fill" : "mappin.and.ellipse")
                            .font(.system(size: 50))
                            .foregroundColor(place.isOfficialSpot ? HiTripColor.primary800 : .orange)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)

                    VStack(alignment: .leading, spacing: 20) {
                        // 배지 + 이름
                        VStack(alignment: .leading, spacing: 8) {
                            if place.isOfficialSpot {
                                Text("📍 공식 일정 스팟")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(HiTripColor.primary800)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(HiTripColor.primary800.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            Text(place.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(HiTripColor.textBlack)
                        }

                        Divider()

                        if let category = place.category, !category.isEmpty {
                            infoRow(icon: "tag", label: "카테고리", value: category)
                        }
                        if let address = place.address, !address.isEmpty {
                            infoRow(icon: "mappin.and.ellipse", label: "주소", value: address)
                        }
                        if let url = place.placeUrl, !url.isEmpty {
                            infoRow(icon: "link", label: "카카오맵", value: url)
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

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.textBlack)
            }
        }
    }
}
