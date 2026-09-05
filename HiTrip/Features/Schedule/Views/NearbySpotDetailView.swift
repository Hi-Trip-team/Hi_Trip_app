import SwiftUI
import MapKit

struct NearbySpotDetailView: View {

    @Environment(\.dismiss) private var dismiss

    var name: String
    var address: String?
    var description: String?
    /// 서버가 주지 않는 값들 — nil이면 해당 UI를 숨깁니다.
    var distance: String?
    var hours: String?
    var rating: Double?
    var reviewCount: Int?
    var imageUrl: String?
    var latitude: Double?
    var longitude: Double?
    var tags: [String] = []

    /// 좌표가 없으면 지도 섹션을 숨깁니다.
    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603),
        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
    )


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
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#93C5FD"), Color(hex: "#2563EB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let urlString = imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            } else {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 52))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(height: 200)
        .clipped()
    }

    // MARK: - 기본 정보

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                Spacer()
                if let rating {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#F59E0B"))
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#111827"))
                    if let reviewCount {
                        Text("(\(reviewCount))")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                }
            }

            if let address, !address.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6B7280"))
                    Text(address)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }

            if hours != nil || distance != nil {
                HStack(spacing: 12) {
                    if let hours {
                        infoChip(icon: "clock", text: hours, color: Color(hex: "#2563EB"))
                    }
                    if let distance {
                        infoChip(icon: "location.circle", text: distance, color: Color(hex: "#2E9B67"))
                    }
                }
            }

            if !tags.isEmpty {
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

    @ViewBuilder
    private var descriptionSection: some View {
        if let description, !description.isEmpty {
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
    }

    // MARK: - 미니맵

    @ViewBuilder
    private var mapPreviewSection: some View {
        if coordinate != nil {
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
        .onAppear {
            if let coordinate {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                )
            }
        }
        }
    }

    private var nearbyPin: NearbyPin {
        NearbyPin(coordinate: coordinate ?? region.center)
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
