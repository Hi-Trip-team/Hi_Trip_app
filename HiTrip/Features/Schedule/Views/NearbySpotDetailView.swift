import SwiftUI
import MapKit

struct NearbySpotDetailView: View {

    @Environment(\.dismiss) private var dismiss

    var name: String = "해운대 해수욕장"
    var distance: String = "0.4km"
    var address: String = "부산 해운대구 우동 해운대해변로 264"
    var hours: String = "09:00 - 18:00"
    var description: String = "부산 대표 해변, 여름 축제 진행 중"
    var rating: Double = 4.7
    var reviewCount: Int = 1024

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603),
        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
    )

    private let tags = ["해변", "산책로", "무장애 가능", "주차 가능"]

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                VStack(spacing: 0) {
                    thumbnailSection
                    infoSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    descriptionSection
                        .padding(.horizontal, 20)
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    mapPreviewSection
                        .padding(.horizontal, 20)
                    Spacer().frame(height: 32)
                }
            }

            bottomButton
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - 헤더

    private var headerSection: some View {
        ZStack {
            Text(name)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .lineLimit(1)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
                Button { } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    // MARK: - 썸네일

    private var thumbnailSection: some View {
        LinearGradient(
            colors: [Color(hex: "#93C5FD"), Color(hex: "#2563EB")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 200)
        .overlay(
            Image(systemName: "water.waves")
                .font(.system(size: 56))
                .foregroundColor(.white.opacity(0.7))
        )
    }

    // MARK: - 기본 정보

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#F59E0B"))
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                Text("(\(reviewCount))")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                Text(address)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            HStack(spacing: 12) {
                infoChip(icon: "clock", text: hours, color: Color(hex: "#2563EB"))
                infoChip(icon: "location.circle", text: distance, color: Color(hex: "#2E9B67"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#2563EB"))
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Color(hex: "#EEF2FF"))
                            .cornerRadius(13)
                    }
                }
            }
        }
    }

    private func infoChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#374151"))
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }

    // MARK: - 설명

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("소개")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#374151"))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 미니맵

    private var mapPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("위치")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))

            Map(coordinateRegion: $region, annotationItems: [nearbyPin]) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#2563EB"))
                            .frame(width: 28, height: 28)
                        Image(systemName: "mappin")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 150)
            .cornerRadius(12)
            .disabled(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nearbyPin: NearbyPin {
        NearbyPin(coordinate: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603))
    }

    // MARK: - 하단 버튼

    private var bottomButton: some View {
        HStack(spacing: 12) {
            Button { } label: {
                Image(systemName: "heart")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(width: 52, height: 52)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Button { } label: {
                Text("길찾기")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

private struct NearbyPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
