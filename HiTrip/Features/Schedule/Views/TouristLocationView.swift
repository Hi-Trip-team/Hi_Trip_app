import SwiftUI
import MapKit

// MARK: - TouristLocationView
/// 관광객 위치 확인 화면
/// 지도 위에 안내사 위치 + 허용 범위 경계(빨간 폴리곤) 표시

struct TouristLocationView: View {

    @Environment(\.dismiss) private var dismiss

    // 부산 해운대 기준 샘플 좌표
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    private let address = "부산 해운대구 중동 1로 110"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Address bar
            addressBar

            // Map
            mapSection

            // Legend + Buttons
            bottomSection
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Address

    private var addressBar: some View {
        HStack {
            Text("주소: \(address)")
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.gray500)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Map

    private var mapSection: some View {
        Map(coordinateRegion: $region, annotationItems: mapAnnotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                VStack(spacing: 2) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(HiTripColor.primary800)
                    Text(item.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(radius: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .overlay(
            // 허용 범위 경계 — 빨간 테두리 오버레이 (실제 구현에서는 MKPolygon 사용)
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.red, lineWidth: 2)
                .padding(40)
                .allowsHitTesting(false)
        )
    }

    private var mapAnnotations: [MapPin] {
        [MapPin(coordinate: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603), label: "나 (안내사)")]
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 12) {
            // Legend
            HStack {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 16, height: 2)
                    Text("허용 범위 경계")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray500)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            // 내 위치 버튼
            Button {
                region.center = CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603)
            } label: {
                Text("내 위치")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HiTripColor.gray100)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            // 비상 알림 버튼
            Button {
                // 비상 알림 발송
            } label: {
                Text("비상 알림 발송")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding(.top, 12)
        .background(Color.white)
    }
}

// MARK: - MapPin

private struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let label: String
}
