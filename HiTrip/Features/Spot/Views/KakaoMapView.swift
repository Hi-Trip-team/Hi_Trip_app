import SwiftUI
import KakaoMapsSDK

// MARK: - KakaoMapView
/// KakaoMapsSDK의 KMViewContainer를 SwiftUI에서 사용하기 위한 래퍼
///
/// SwiftUI는 UIKit 뷰를 직접 사용할 수 없어서
/// UIViewRepresentable 프로토콜로 감싸야 함.
///
/// 핵심 라이프사이클:
/// 1. makeUIView → KMViewContainer 생성
/// 2. prepareEngine() → 엔진 준비
/// 3. containerDidResized() → 컨테이너 크기 확정 시 엔진 활성화
/// 4. addViews() → 엔진 활성화 후 지도 뷰 추가
/// 5. onDisappear → pauseEngine / dismantleUIView → resetEngine

struct KakaoMapView: UIViewRepresentable {

    // MARK: - Properties

    let latitude: Double
    let longitude: Double
    @Binding var draw: Bool

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> KMViewContainer {
        let view = KMViewContainer()
        view.sizeToFit()
        context.coordinator.createController(view)
        return view
    }

    /// draw 상태에 따라 엔진 활성화/일시정지
    ///
    /// ⚠️ 주의: activateEngine은 containerDidResized 이후에 호출해야 함.
    /// 컨테이너 크기가 확정되기 전에 활성화하면 렌더링 영역이 0이라 지도가 안 보임.
    /// 그래서 첫 활성화는 containerDidResized에서 하고,
    /// 여기서는 이미 활성화된 이후의 재개/일시정지만 담당.
    func updateUIView(_ uiView: KMViewContainer, context: Context) {
        if draw {
            if context.coordinator.isEnginePrepared {
                context.coordinator.controller?.activateEngine()
            }
        } else {
            context.coordinator.controller?.pauseEngine()
        }
    }

    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: Coordinator) {
        coordinator.controller?.resetEngine()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(latitude: latitude, longitude: longitude)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MapControllerDelegate {

        var controller: KMController?
        let latitude: Double
        let longitude: Double

        /// containerDidResized가 한 번이라도 호출되었는지
        var isEnginePrepared = false

        /// 첫 번째 containerDidResized에서만 엔진 활성화
        var first = true

        init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
            super.init()
        }

        func createController(_ view: KMViewContainer) {
            controller = KMController(viewContainer: view)
            controller?.delegate = self
            controller?.prepareEngine()
        }

        // MARK: - MapControllerDelegate

        /// 엔진 준비 완료 → 지도 뷰 추가
        func addViews() {
            let defaultPosition = MapPoint(
                longitude: longitude,
                latitude: latitude
            )
            let mapviewInfo = MapviewInfo(
                viewName: "spotMap",
                viewInfoName: "map",
                defaultPosition: defaultPosition,
                defaultLevel: 15
            )

            controller?.addView(mapviewInfo)
        }

        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            print("✅ [KakaoMap] addViewSucceeded: \(viewName)")

            // 지도 뷰가 추가된 후 렌더링 영역 재설정
            let mapView = controller?.getView("spotMap") as? KakaoMap
            print("🗺️ [KakaoMap] mapView: \(String(describing: mapView))")
        }

        func addViewFailed(_ viewName: String, viewInfoName: String) {
            print("❌ [KakaoMap] addViewFailed: \(viewName)")
        }

        /// 컨테이너 크기가 확정될 때 호출
        ///
        /// 이 시점에서 지도의 렌더링 영역(viewRect)을 설정하고,
        /// 첫 호출 시 엔진을 활성화해야 지도가 정상 렌더링됨.
        func containerDidResized(_ size: CGSize) {
            print("📐 [KakaoMap] containerDidResized: \(size)")

            let mapView = controller?.getView("spotMap") as? KakaoMap
            mapView?.viewRect = CGRect(origin: .zero, size: size)

            if first {
                first = false
                isEnginePrepared = true
                controller?.activateEngine()
            }
        }

        func authenticationSucceeded() {
            print("✅ [KakaoMap] 인증 성공")
        }

        func authenticationFailed(_ errorCode: Int, desc: String) {
            print("❌ [KakaoMap] 인증 실패: code=\(errorCode), \(desc)")
        }
    }
}
