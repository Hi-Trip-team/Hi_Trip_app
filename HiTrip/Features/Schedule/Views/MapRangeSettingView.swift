import SwiftUI
import MapKit

struct MapRangeSettingView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var radius: Double = 500
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.1588, longitude: 129.1603),
        span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            mapView

            controlPanel
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
        }
        .navigationTitle("지도 범위 설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - 지도

    private var mapView: some View {
        Map(coordinateRegion: $region)
            .ignoresSafeArea()
            .overlay(
                Circle()
                    .stroke(Color(hex: "#2563EB").opacity(0.6),
                            style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .padding(mapCirclePadding)
                    .allowsHitTesting(false)
            )
            .overlay(
                Circle()
                    .fill(Color(hex: "#2563EB").opacity(0.08))
                    .padding(mapCirclePadding)
                    .allowsHitTesting(false)
            )
    }

    private var mapCirclePadding: CGFloat {
        let base: CGFloat = 500
        let ratio = CGFloat(radius) / base
        let minPad: CGFloat = 20
        let maxPad: CGFloat = 100
        return max(minPad, maxPad - (ratio - 0.2) * 80)
    }

    // MARK: - 컨트롤 패널

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("안전 범위")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                Spacer()
                Text("\(Int(radius))m")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#2563EB"))
            }

            Slider(value: $radius, in: 100...2000, step: 50)
                .tint(Color(hex: "#2563EB"))

            Button { dismiss() } label: {
                Text("범위 저장")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 2)
    }
}
