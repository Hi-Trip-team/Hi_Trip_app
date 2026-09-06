import SwiftUI
import MapKit

struct TouristLocationView: View {

    @Environment(\.dismiss) private var dismiss

    var touristName: String = "둘리"
    var address: String = "부산 해운대구 중동 1015 인근"

    private let guideCoordinate = CLLocationCoordinate2D(latitude: 35.158, longitude: 129.159)
    private let touristCoordinate = CLLocationCoordinate2D(latitude: 35.1620, longitude: 129.164)

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1600, longitude: 129.1615),
        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
    )

    var body: some View {
        ZStack(alignment: .top) {
            mapView
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                Spacer()
                bottomPanel
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - 헤더 (타이틀 + 주소/갱신)

    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("\(touristName) 님의 현재 위치")
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

            HStack {
                Text("주소: \(address)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#333840"))
                Spacer()
                Text("10초 전 갱신")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.horizontal, 24)
            .frame(height: 40)
        }
        .background(Color.white)
    }

    // MARK: - 지도

    private var mapView: some View {
        Map(coordinateRegion: $region, annotationItems: pins) { pin in
            MapAnnotation(coordinate: pin.coordinate) {
                VStack(spacing: 2) {
                    Image(systemName: "mappin")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(pin.color)
                    Text(pin.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(pin.color)
                }
            }
        }
        .overlay(boundaryOverlay)
    }

    /// 허용 범위 경계 — 디자인의 -15° 회전 사각형
    private var boundaryOverlay: some View {
        Rectangle()
            .fill(Color.red.opacity(0.05))
            .overlay(Rectangle().stroke(Color.red, lineWidth: 2))
            .frame(width: 340, height: 340)
            .rotationEffect(.degrees(-15))
            .allowsHitTesting(false)
    }

    private var pins: [MapPinItem] {[
        MapPinItem(coordinate: guideCoordinate, label: "나 (안내사)", color: Color(hex: "#0C46C0")),
        MapPinItem(coordinate: touristCoordinate, label: touristName, color: Color(hex: "#734CD9")),
    ]}

    // MARK: - 하단 패널

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // 범례 칩
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red)
                        .frame(width: 14, height: 3)
                    Text("허용 범위 경계")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#333840"))
                }
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Color.white)
                .cornerRadius(15)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 38)

            // 뷰 전환 버튼 3개
            HStack(spacing: 12) {
                viewButton(title: "내 위치", isSelected: false) {
                    region.center = guideCoordinate
                }
                viewButton(title: "관광객 위치", isSelected: false) {
                    region.center = touristCoordinate
                }
                viewButton(title: "전체 보기", isSelected: true) {
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 35.1600, longitude: 129.1615),
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 19)

            // 전화걸기
            Button { } label: {
                Text("전화걸기")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#EF4444"))
                    .cornerRadius(9)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 21)
            .padding(.bottom, 32)
        }
    }

    private func viewButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color(hex: "#2563EB") : Color(hex: "#333840"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color(hex: "#E8F0FF") : Color(hex: "#F3F4F6"))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

private struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let label: String
    let color: Color
}
