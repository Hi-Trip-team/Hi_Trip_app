import SwiftUI

// MARK: - SpotMapView
/// 관광지 위치를 전체화면 KakaoMap으로 보여주는 뷰
///
/// SpotDetailView에서 "지도 보기" 버튼을 누르면 Sheet로 표시됨.
/// ScrollView 밖에서 KakaoMap을 렌더링하므로 Metal GPU 이슈 없음.

struct SpotMapView: View {

    let spot: TourSpotItem
    @Environment(\.dismiss) private var dismiss
    @State private var drawMap = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let lat = spot.latitude, let lng = spot.longitude {
                    KakaoMapView(
                        latitude: lat,
                        longitude: lng,
                        draw: $drawMap
                    )
                    .ignoresSafeArea()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 40))
                            .foregroundColor(HiTripColor.gray300)
                        Text("위치 정보가 없습니다")
                            .font(.system(size: 15))
                            .foregroundColor(HiTripColor.gray400)
                    }
                }
            }
            .navigationTitle(spot.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .onAppear { drawMap = true }
            .onDisappear { drawMap = false }
        }
    }
}
