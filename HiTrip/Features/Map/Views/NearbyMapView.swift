import SwiftUI
import CoreLocation

// MARK: - NearbyMapView
/// 지도 탭 메인 화면
///
/// 구성:
/// - 상단: 타이틀 + 카테고리 필터 칩
/// - 중단: 지도 (고정 높이 ~50%)  +  GPS/줌 컨트롤 오버레이
/// - 하단: 스팟 카드 2열 세로 스크롤

struct NearbyMapView: View {

    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        VStack(spacing: 0) {

            // MARK: 상단 헤더
            headerSection
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)

            // MARK: 카테고리 필터
            categoryBar
                .padding(.bottom, 12)

            // MARK: 지도 (고정 높이)
            mapSection

            // MARK: 하단 스팟 목록
            spotListSection
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
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Category Bar

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapCategory.allCases) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, 20)
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
            .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Map Section

    private var mapSection: some View {
        ZStack(alignment: .bottomTrailing) {
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

            // GPS + 줌 컨트롤
            rightControls
                .padding(.trailing, 12)
                .padding(.bottom, 12)
        }
        .frame(height: 320)
        .clipped()
    }

    // MARK: - Right Controls

    private var rightControls: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.moveToCurrentLocation()
            } label: {
                Image(systemName: "location")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
                    .frame(width: 42, height: 42)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 6, y: 2)
            }

            HStack(spacing: 0) {
                Button { viewModel.zoomOut() } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                        .frame(width: 42, height: 42)
                }
                Divider().frame(height: 24)
                Button { viewModel.zoomIn() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                        .frame(width: 42, height: 42)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 6, y: 2)
        }
    }

    // MARK: - Spot List (2열 그리드)

    private var spotListSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        return ScrollView {
            if viewModel.displayPlaces.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 32))
                        .foregroundColor(HiTripColor.gray300)
                    Text("주변 스팟이 없습니다")
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray400)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.displayPlaces) { place in
                        PlaceCardView(place: place)
                            .onTapGesture { viewModel.selectedPlace = place }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)
    }
}

// MARK: - PlaceCardView

struct PlaceCardView: View {

    let place: MapPlaceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 썸네일 이미지
            ZStack {
                HiTripColor.gray200
                if let urlStr = place.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(HiTripColor.gray300)
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(HiTripColor.gray300)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .clipped()
            .cornerRadius(12, corners: [.topLeft, .topRight])

            // 텍스트 영역
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)
                    .lineLimit(1)

                if let category = place.category, !category.isEmpty {
                    Text(category)
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray400)
                        .lineLimit(1)
                }

                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                    if let rating = place.rating {
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(HiTripColor.textBlack)
                    }
                    if let count = place.ratingCount {
                        Text("(\(count))")
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray400)
                    }
                }

                if let mins = place.walkingMinutes {
                    Text("도보 \(mins)분")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray400)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 8, y: 2)
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
                    ZStack {
                        HiTripColor.gray200
                        if let urlStr = place.imageUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(HiTripColor.gray300)
                            }
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(HiTripColor.gray300)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()

                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            if place.isOfficialSpot {
                                Text("📍 공식 일정 스팟")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(HiTripColor.primary800)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(HiTripColor.primary800.opacity(0.14))
                                    .cornerRadius(8)
                            }
                            Text(place.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(HiTripColor.textBlack)

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.yellow)
                                if let rating = place.rating {
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 14, weight: .medium))
                                }
                                if let count = place.ratingCount {
                                    Text("(\(count))")
                                        .font(.system(size: 13))
                                        .foregroundColor(HiTripColor.gray400)
                                }
                                if let mins = place.walkingMinutes {
                                    Text("· 도보 \(mins)분")
                                        .font(.system(size: 13))
                                        .foregroundColor(HiTripColor.gray400)
                                }
                            }
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
