import SwiftUI
import MapKit

// MARK: - StaticMapPreview
/// 조작이 필요 없는 작은 지도 — 정적 이미지로 그립니다
///
/// 스팟 상세처럼 지도 화면 위에 올라가는 곳에서 카카오 지도를 하나 더 띄우면
/// 엔진끼리 간섭해 가끔 타일이 그려지지 않았습니다(핀만 보이는 빈 지도).
/// 미리보기는 조작이 없으므로 지도 이미지를 한 번 만들어 보여주는 쪽이 확실하고 가볍습니다.
///
/// 이미지는 Apple 지도 스냅숏(MKMapSnapshotter)으로 만들고, 핀은 앱 공통 핀을 가운데에 겹칩니다.

struct StaticMapPreview: View {

    let coordinate: CLLocationCoordinate2D
    var pinColor: Color = AppColor.accent
    /// 화면에 담을 범위(미터) — 기본 약 600m
    var spanMeters: CLLocationDistance = 600

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    AppColor.surface
                    if !failed { ProgressView().tint(AppColor.textTertiary) }
                }

                pin
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .task(id: TaskKey(coordinate: coordinate, size: proxy.size)) {
                await render(size: proxy.size)
            }
        }
    }

    /// 앱 공통 핀 모양 — 원 + 흰 핀 아이콘
    private var pin: some View {
        ZStack {
            Circle()
                .fill(pinColor)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            Image(systemName: "mappin")
                .font(AppFont.captionBold)
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
    }

    private func render(size: CGSize) async {
        guard size.width > 0, size.height > 0 else { return }
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: spanMeters,
            longitudinalMeters: spanMeters
        )
        options.size = size
        options.pointOfInterestFilter = .includingAll

        do {
            let snapshot = try await MKMapSnapshotter(options: options).start()
            image = snapshot.image
        } catch {
            failed = true
        }
    }

    /// 좌표나 크기가 바뀔 때만 다시 그립니다
    private struct TaskKey: Equatable {
        let latitude: Double
        let longitude: Double
        let width: CGFloat
        let height: CGFloat

        init(coordinate: CLLocationCoordinate2D, size: CGSize) {
            latitude = coordinate.latitude
            longitude = coordinate.longitude
            width = size.width
            height = size.height
        }
    }
}
