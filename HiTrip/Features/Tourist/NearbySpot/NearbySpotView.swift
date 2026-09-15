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

    @State private var camera: MapCameraCommand?
    @State private var selectedSpot: TravelerNearbySpotDTO?
    /// 내 위치 + 안전 구역을 한 화면에 맞췄는지 — 한 번 맞춘 뒤에는 사용자가 움직인 지도를 되돌리지 않습니다
    @State private var hasFitInitialCamera = false

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
        // 위치가 갱신될 때마다 카메라를 옮기면 지도를 둘러볼 수 없어서, 처음 한 번만 맞춥니다
        .onChange(of: viewModel.currentLocation?.latitude) { _, _ in fitInitialCameraIfNeeded() }
        .onChange(of: viewModel.geofence?.radiusM) { _, _ in fitInitialCameraIfNeeded() }
        .navigationDestination(item: $selectedSpot) { spot in
            NearbySpotDetailView(
                name: spot.name,
                address: spot.roadAddress ?? spot.address,
                description: spot.description,
                imageUrl: spot.imageUrl,
                isSponsored: spot.isSponsored == true,
                latitude: spot.latitude,
                longitude: spot.longitude,
                categoryName: spot.categoryName,
                phone: spot.phone,
                placeUrl: spot.placeUrl
            )
        }
    }

    // MARK: - 지도

    private var mapLayer: some View {
        KakaoMapView(
            pins: mapPins,
            circles: mapCircles,
            camera: camera,
            // 핀을 누르면 아래 카드가 그 스팟으로 이동합니다
            onPinTap: { id in
                guard id != Self.myLocationPinID else { return }
                viewModel.focusedSpotId = id
            }
        )
    }

    private static let myLocationPinID = "__me"

    /// 내 위치(파랑) + 스팟 핀 — 선택된 스팟은 강조색
    private var mapPins: [MapPin] {
        var pins: [MapPin] = viewModel.spots.compactMap { spot in
            guard let lat = spot.latitude, let lng = spot.longitude else { return nil }
            return MapPin(
                id: spot.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                color: UIColor(spot.id == viewModel.focusedSpotId ? AppColor.accent : AppColor.textSecondary)
            )
        }
        if let me = viewModel.currentLocation {
            pins.append(MapPin(id: Self.myLocationPinID, coordinate: me, color: UIColor(AppColor.brand)))
        }
        return pins
    }

    /// 안내사가 설정한 허용 반경 — 빨간 경계선 (카카오 도형은 점선을 지원하지 않아 실선)
    private var mapCircles: [MapCircleOverlay] {
        guard let lat = viewModel.geofence?.latitude,
              let lng = viewModel.geofence?.longitude,
              let radius = viewModel.geofence?.radiusM else { return [] }
        return [MapCircleOverlay(
            id: "geofence",
            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            radiusM: radius,
            fill: UIColor(AppColor.dangerSoft).withAlphaComponent(0.08),
            stroke: UIColor(AppColor.dangerSoft)
        )]
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
        camera = .center(coordinate, level: 15)
    }

    /// 지도를 열 때 내 위치와 안전 구역(원 전체)이 한 화면에 들어오도록 맞춥니다
    ///
    /// - 둘 다 있으면: 원 둘레 + 내 위치를 모두 담고 끝냅니다
    /// - 하나만 먼저 오면: 그것만 보여주고, 나머지가 오면 다시 맞춥니다
    /// - 안전 구역이 없는 여행: 내 위치로 이동합니다
    private func fitInitialCameraIfNeeded() {
        guard !hasFitInitialCamera else { return }

        let me = viewModel.currentLocation
        let fenceRing: [CLLocationCoordinate2D] = mapCircles.first.map {
            KakaoMapView.circlePoints(center: $0.center, radiusM: $0.radiusM, count: 16)
        } ?? []

        switch (me, fenceRing.isEmpty) {
        case (let me?, false):
            camera = .fit(fenceRing + [me])
            hasFitInitialCamera = true
        case (nil, false):
            camera = .fit(fenceRing)
        case (let me?, true):
            // 안전 구역이 끝내 없을 수도 있어 첫 위치에서 한 번만 옮깁니다 (구역이 오면 위에서 다시 맞춤)
            if camera == nil { camera = .center(me, level: 15) }
        case (nil, true):
            break
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
