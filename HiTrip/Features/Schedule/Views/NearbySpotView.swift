import SwiftUI
import MapKit

struct NearbySpotView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter = "음식점"
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603),
        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
    )

    private let filters = ["음식점", "무장애", "반려동물", "편의점", "마트"]

    private let spots: [NearbySpot] = [
        NearbySpot(name: "해운대 해수욕장",
                   distance: "0.4km",
                   isOpen: true,
                   hours: "09:00 - 18:00",
                   address: "부산 해운대구 우동 해운대해변로 264",
                   description: "부산 대표 해변, 여름 축제 진행 중",
                   coordinate: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            // 필터 칩
            filterRow
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            ZStack(alignment: .bottom) {
                // 지도
                mapView

                // 오버레이 배지
                VStack {
                    HStack(spacing: 8) {
                        Text("⚠ GPS 정확도 낮음")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Color(hex: "#4F4F4F"))
                            .cornerRadius(13)

                        Text("빨간 선 = 안전 구역 경계")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Color(hex: "#E46059"))
                            .cornerRadius(13)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .padding(.top, 8)

                // 내 위치 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            region.center = CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603)
                        } label: {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#2563EB"))
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 16)
                        .padding(.bottom, 130)
                    }
                }

                // 하단 스팟 카드
                NavigationLink(destination: NearbySpotDetailView(
                    name: spots[0].name,
                    address: spots[0].address,
                    description: spots[0].description,
                    distance: spots[0].distance,
                    hours: spots[0].hours
                )) {
                    spotCard(spots[0])
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("주변 인기 스팟")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    // MARK: - 필터

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { f in
                    Button { selectedFilter = f } label: {
                        Text(f)
                            .font(.system(size: 12, weight: selectedFilter == f ? .semibold : .medium))
                            .foregroundColor(selectedFilter == f ? Color(hex: "#2563EB") : Color(hex: "#333840"))
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(Color.white)
                            .cornerRadius(15)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 지도

    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: spots) { spot in
            MapAnnotation(coordinate: spot.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#2563EB"))
            }
        }
        .overlay(
            // 허용 범위 경계 원
            Circle()
                .stroke(Color.red.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [6]))
                .padding(60)
                .allowsHitTesting(false)
        )
        .background(Color(hex: "#E0EAE0"))
    }

    // MARK: - 스팟 카드

    private func spotCard(_ spot: NearbySpot) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#E5E7EB"))
                .frame(width: 86, height: 86)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(Color(hex: "#9CA3AF"))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))

                HStack(spacing: 4) {
                    Text(spot.distance)
                        .font(.system(size: 11))
                        .foregroundColor(.black)
                    Text("·")
                    Text("영업중")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#2E9B67"))
                    Text(spot.hours)
                        .font(.system(size: 11))
                        .foregroundColor(.black)
                }

                Text(spot.address)
                    .font(.system(size: 11))
                    .foregroundColor(.black)

                Text(spot.description)
                    .font(.system(size: 11))
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
    }
}

private struct NearbySpot: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let isOpen: Bool
    let hours: String
    let address: String
    let description: String
    let coordinate: CLLocationCoordinate2D
}
