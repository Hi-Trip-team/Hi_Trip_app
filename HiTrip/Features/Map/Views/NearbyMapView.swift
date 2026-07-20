import SwiftUI
import CoreLocation

// MARK: - NearbyMapView
/// 지도 탭 메인 화면 — 피그마 디자인 반영
///
/// 구성:
/// - 풀스크린 KakaoMap (허용 반경 + 마커)
/// - 상단 좌측: "주변 인기 스팟" 타이틀 (그림자 텍스트)
/// - 상단: 카테고리 필터 칩 (흰 배경 알약)
/// - 우측 중단: GPS 원형 버튼 + 줌(— +) 가로 버튼
/// - 하단: 장소 카드 가로 스크롤 (이미지 + 이름 + 카테고리 + 별점(N) + 도보)

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
                cameraTarget: viewModel.cameraTarget,
                zoomTrigger: viewModel.zoomTrigger
            )
            .ignoresSafeArea()

            // MARK: 오버레이 레이어
            VStack(spacing: 0) {

                // 상단: 타이틀 + 카테고리
                VStack(alignment: .leading, spacing: 10) {
                    titleLabel
                        .padding(.horizontal, 20)

                    categoryBar
                }
                .padding(.top, 12)

                Spacer()

                // 우측 컨트롤: GPS + 줌
                HStack {
                    Spacer()
                    rightControls
                        .padding(.trailing, 16)
                        .padding(.bottom, viewModel.displayPlaces.isEmpty ? 32 : 8)
                }

                // 하단 장소 카드
                if !viewModel.displayPlaces.isEmpty {
                    placeCardScroll
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear  { viewModel.drawMap = true  }
        .onDisappear { viewModel.drawMap = false }
        .sheet(item: $viewModel.selectedPlace) { place in
            PlaceDetailSheet(place: place)
        }
    }

    // MARK: - Title Label

    private var titleLabel: some View {
        HStack {
            Text("주변 인기 스팟")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
                .shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 0)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .background(Color.white.opacity(0.8).clipShape(Circle()))
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
            .shadow(color: .black.opacity(0.12), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Right Controls (GPS + Zoom)

    private var rightControls: some View {
        VStack(spacing: 10) {
            // GPS 버튼 (원형)
            Button {
                viewModel.moveToCurrentLocation()
            } label: {
                Image(systemName: "location")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
                    .frame(width: 42, height: 42)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.14), radius: 6, y: 2)
            }

            // 줌 버튼 가로 배치 (— +)
            HStack(spacing: 0) {
                Button { viewModel.zoomOut() } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                        .frame(width: 42, height: 42)
                }
                Divider()
                    .frame(height: 24)
                Button { viewModel.zoomIn() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                        .frame(width: 42, height: 42)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
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
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundColor(HiTripColor.gray300)
            }
            .frame(width: 160, height: 120)
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

                HStack(spacing: 4) {
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
        .frame(width: 160)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.10), radius: 8, y: 2)
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
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(HiTripColor.gray300)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)

                    VStack(alignment: .leading, spacing: 20) {
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
