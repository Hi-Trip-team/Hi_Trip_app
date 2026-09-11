import SwiftUI
import MapKit

// MARK: - NearbySpotView
/// 주변 인기 스팟 (지도) — 피그마 12380:1095
///
/// 지도 위에 상황별 검색 칩·상태 칩·내 위치 버튼·스팟 카드가 겹칩니다.
/// 서버가 카테고리를 필수로 받아 "전체" 조회가 없으므로 칩은 항상 하나가 선택됩니다.

struct NearbySpotView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NearbySpotViewModel()

    @State private var camera: MapCameraPosition = .automatic
    @State private var selectedSpot: TravelerNearbySpotDTO?

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                headerSection
                categoryChips
                    .padding(.top, AppSpacing.xs)
                statusChips
                    .padding(.top, AppSpacing.md)
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                myLocationButton
                    .padding(.trailing, AppSpacing.xl)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, AppSpacing.sm)
                spotCards
                    .padding(.bottom, AppSpacing.xl)
            }

            if viewModel.isOutsideGeofence {
                outsideBanner
            }
        }
        .background(AppColor.successSubtle)
        .navigationBarHidden(true)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: viewModel.currentLocation?.latitude) { _, _ in moveToCurrentLocation() }
        .navigationDestination(item: $selectedSpot) { spot in
            NearbySpotDetailView(
                name: spot.name,
                address: spot.roadAddress ?? spot.address,
                description: spot.description,
                imageUrl: spot.imageUrl,
                isSponsored: spot.isSponsored == true,
                latitude: spot.latitude,
                longitude: spot.longitude,
                categoryName: spot.categoryName
            )
        }
    }

    // MARK: - 지도

    private var mapLayer: some View {
        Map(position: $camera, selection: $viewModel.focusedSpotId) {
            UserAnnotation()

            // 안내사가 설정한 허용 반경 — 빨간 경계선
            if let lat = viewModel.geofence?.latitude,
               let lng = viewModel.geofence?.longitude,
               let radius = viewModel.geofence?.radiusM {
                MapCircle(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    radius: radius
                )
                .foregroundStyle(AppColor.dangerSoft.opacity(0.08))
                .stroke(AppColor.dangerSoft, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }

            ForEach(viewModel.spots) { spot in
                if let lat = spot.latitude, let lng = spot.longitude {
                    Marker(spot.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        .tint(spot.id == viewModel.focusedSpotId
                              ? AppColor.accent : AppColor.textSecondary)
                        .tag(spot.id)
                }
            }
        }
        .mapControls { MapCompass() }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        NavigationHeader(title: "주변 인기 스팟", style: .compact) { dismiss() }
    }

    // MARK: - 상황별 검색 칩

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(NearbySpotViewModel.Category.allCases) { category in
                    let isSelected = viewModel.selectedCategory == category
                    Button { viewModel.select(category) } label: {
                        Text(category.label)
                            .font(isSelected ? AppFont.captionSemiBold : AppFont.captionMedium)
                            .foregroundColor(isSelected ? AppColor.accent : AppColor.textBody)
                            .frame(width: 63, height: 34)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 26)
        }
    }

    // MARK: - 상태 칩

    private var statusChips: some View {
        HStack(spacing: 7) {
            if viewModel.isAccuracyLow {
                statusChip("⚠ GPS 정확도 낮음", background: AppColor.gray700)
            }
            if viewModel.geofence != nil {
                statusChip("빨간 선 = 안전 구역 경계", background: AppColor.dangerSoft)
            }
            Spacer()
        }
        .padding(.horizontal, 26)
    }

    private func statusChip(_ text: String, background: Color) -> some View {
        Text(text)
            .font(AppFont.caption2Medium)
            .foregroundColor(.white)
            .padding(.horizontal, 11)
            .frame(height: 26)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    // MARK: - 안전 구역 이탈 배너

    private var outsideBanner: some View {
        VStack {
            Text("안전 구역을 벗어났어요")
                .font(AppFont.labelBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppColor.dangerSoft)
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .transition(.move(edge: .top))
    }

    // MARK: - 내 위치 버튼

    private var myLocationButton: some View {
        Button { moveToCurrentLocation() } label: {
            Image(systemName: "location.fill")
                .font(AppFont.headline)
                .foregroundColor(AppColor.accent)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func moveToCurrentLocation() {
        guard let coordinate = viewModel.currentLocation else { return }
        withAnimation {
            camera = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            ))
        }
    }

    // MARK: - 스팟 카드

    @ViewBuilder
    private var spotCards: some View {
        switch viewModel.state {
        case .failed(let message):
            messageCard(message, actionTitle: "재시도") { viewModel.loadSpots() }

        case .loading, .idle:
            if viewModel.authorizationDenied {
                permissionCard
            } else {
                EmptyView()
            }

        case .loaded:
            if viewModel.spots.isEmpty {
                messageCard("주변에 결과가 없어요", actionTitle: nil, action: nil)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.spots) { spot in
                            spotCard(spot)
                                .onTapGesture { selectedSpot = spot }
                        }
                    }
                    .padding(.horizontal, 14)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $viewModel.focusedSpotId)
            }
        }
    }

    private func spotCard(_ spot: TravelerNearbySpotDTO) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            ZStack(alignment: .topLeading) {
                SpotImageView(
                    imageUrl: spot.imageUrl,
                    categoryName: spot.categoryName,
                    iconSize: 24
                )
                .frame(width: 86, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                if spot.isSponsored == true {
                    Text("광고")
                        .font(AppFont.micro2Medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .frame(height: 16)
                        .background(AppColor.ink)
                        .cornerRadius(4)
                        .padding(AppSpacing.xxs)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(spot.name)
                    .font(AppFont.labelBold)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)

                if let distance = spot.distanceText {
                    Text(distance)
                        .font(AppFont.caption2)
                        .foregroundColor(.black)
                }

                if let address = spot.roadAddress ?? spot.address {
                    Text(address)
                        .font(AppFont.caption2)
                        .foregroundColor(.black)
                        .lineLimit(2)
                }

                if let description = spot.description, !description.isEmpty {
                    Text(description)
                        .font(AppFont.caption2)
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .frame(width: 326, height: 113, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.divider, lineWidth: 1)
        )
        .id(spot.id)
    }

    // MARK: - 위치 권한 / 안내 카드

    private var permissionCard: some View {
        VStack(spacing: 10) {
            Text("위치 권한을 허용해주세요")
                .font(AppFont.bodyBold)
                .foregroundColor(AppColor.textPrimary)
            Text("주변 스팟과 안전 구역을 보여드리려면 위치 정보가 필요해요")
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("설정 이동")
                    .font(AppFont.labelBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .frame(height: 40)
                    .background(AppColor.accent)
                    .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .frame(width: 326)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }

    private func messageCard(_ text: String, actionTitle: String?, action: (() -> Void)?) -> some View {
        VStack(spacing: 10) {
            Text(text)
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.labelBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .frame(height: 40)
                        .background(AppColor.accent)
                        .cornerRadius(AppRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .frame(width: 326)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }
}
