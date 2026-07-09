import SwiftUI
import KakaoMapsSDK
import CoreLocation

// MARK: - KakaoMapView
/// KakaoMapsSDK의 KMViewContainer를 SwiftUI에서 사용하기 위한 래퍼
///
/// 지원 기능:
/// - 기본 지도 렌더링
/// - 공식 스팟 / 검색 결과 마커 표시 (파란/주황 구분)
/// - 허용 반경 폴리곤 오버레이
/// - 현재 위치 마커
/// - cameraTarget 변경 시 카메라 이동

struct KakaoMapView: UIViewRepresentable {

    // MARK: - Properties

    let latitude: Double
    let longitude: Double
    @Binding var draw: Bool
    var markers: [MapPlaceItem] = []
    var userLocation: CLLocationCoordinate2D?
    var radiusMeters: Double = 0
    var cameraTarget: MapViewModel.CameraTarget?
    var onMarkerTapped: ((MapPlaceItem) -> Void)?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> KMViewContainer {
        let view = KMViewContainer()
        view.sizeToFit()
        context.coordinator.createController(view)
        return view
    }

    func updateUIView(_ uiView: KMViewContainer, context: Context) {
        let coord = context.coordinator

        if draw {
            if coord.isEnginePrepared { coord.controller?.activateEngine() }
        } else {
            coord.controller?.pauseEngine()
        }

        guard coord.isMapReady else {
            coord.pendingMarkers     = markers
            coord.pendingUserLoc     = userLocation
            coord.pendingRadius      = radiusMeters
            coord.pendingCameraMove  = cameraTarget
            return
        }

        coord.updateMarkers(markers)

        if let loc = userLocation {
            coord.updateUserLocation(loc)
        }

        if radiusMeters > 0 {
            coord.updateRadius(
                center: MapPoint(longitude: longitude, latitude: latitude),
                meters: radiusMeters
            )
        }

        if let target = cameraTarget, target != coord.lastCameraTarget {
            coord.lastCameraTarget = target
            coord.moveCamera(to: target.coordinate)
        }
    }

    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: Coordinator) {
        coordinator.controller?.resetEngine()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            latitude: latitude,
            longitude: longitude,
            onMarkerTapped: onMarkerTapped
        )
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MapControllerDelegate {

        var controller: KMController?
        let latitude: Double
        let longitude: Double
        var onMarkerTapped: ((MapPlaceItem) -> Void)?

        var isEnginePrepared = false
        var isMapReady       = false
        private var first    = true

        // 지도 준비 전 대기 중인 데이터
        var pendingMarkers:    [MapPlaceItem]                  = []
        var pendingUserLoc:    CLLocationCoordinate2D?
        var pendingRadius:     Double                          = 0
        var pendingCameraMove: MapViewModel.CameraTarget?

        var lastCameraTarget: MapViewModel.CameraTarget?

        // itemID → MapPlaceItem 룩업 (마커 탭 처리용)
        private var markerLookup: [String: MapPlaceItem] = [:]

        init(latitude: Double, longitude: Double, onMarkerTapped: ((MapPlaceItem) -> Void)?) {
            self.latitude        = latitude
            self.longitude       = longitude
            self.onMarkerTapped  = onMarkerTapped
            super.init()
        }

        func createController(_ view: KMViewContainer) {
            controller = KMController(viewContainer: view)
            controller?.delegate = self
            controller?.prepareEngine()
        }

        // MARK: - MapControllerDelegate

        func addViews() {
            let info = MapviewInfo(
                viewName: "mapView",
                viewInfoName: "map",
                defaultPosition: MapPoint(longitude: longitude, latitude: latitude),
                defaultLevel: 15
            )
            controller?.addView(info)
        }

        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            print("✅ [KakaoMap] addViewSucceeded")
            isMapReady = true
            guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }

            registerPoiStyles(mapView)
            setupShapeLayer(mapView)

            // 대기 중이던 업데이트 적용
            updateMarkers(pendingMarkers);     pendingMarkers = []
            if let loc = pendingUserLoc { updateUserLocation(loc); pendingUserLoc = nil }
            if pendingRadius > 0 {
                updateRadius(center: MapPoint(longitude: longitude, latitude: latitude), meters: pendingRadius)
                pendingRadius = 0
            }
            if let t = pendingCameraMove {
                lastCameraTarget = t
                moveCamera(to: t.coordinate)
                pendingCameraMove = nil
            }
        }

        func addViewFailed(_ viewName: String, viewInfoName: String) {
            print("❌ [KakaoMap] addViewFailed: \(viewName)")
        }

        func containerDidResized(_ size: CGSize) {
            let mapView = controller?.getView("mapView") as? KakaoMap
            mapView?.viewRect = CGRect(origin: .zero, size: size)
            if first {
                first = false
                isEnginePrepared = true
                controller?.activateEngine()
            }
        }

        func authenticationSucceeded() { print("✅ [KakaoMap] 인증 성공") }
        func authenticationFailed(_ errorCode: Int, desc: String) {
            print("❌ [KakaoMap] 인증 실패 \(errorCode): \(desc)")
        }

        // MARK: - POI Styles

        private func registerPoiStyles(_ mapView: KakaoMap) {
            let lm = mapView.getLabelManager()

            // 공식 스팟 — 파란 원
            let blueImg  = circleImage(color: .systemBlue,   size: 20)
            let blueIcon = PoiIconStyle(symbol: blueImg, anchorPoint: CGPoint(x: 0.5, y: 0.5))
            let blueStyle = PoiStyle(styleID: "official", styles: [PerLevelPoiStyle(iconStyle: blueIcon, level: 0)])
            lm.addPoiStyle(blueStyle)

            // 검색 결과 — 주황 원
            let orangeImg  = circleImage(color: .systemOrange, size: 16)
            let orangeIcon = PoiIconStyle(symbol: orangeImg, anchorPoint: CGPoint(x: 0.5, y: 0.5))
            let orangeStyle = PoiStyle(styleID: "search", styles: [PerLevelPoiStyle(iconStyle: orangeIcon, level: 0)])
            lm.addPoiStyle(orangeStyle)

            // 내 위치 — 빨간 원
            let redImg   = circleImage(color: .systemRed,    size: 18)
            let redIcon  = PoiIconStyle(symbol: redImg, anchorPoint: CGPoint(x: 0.5, y: 0.5))
            let redStyle = PoiStyle(styleID: "user", styles: [PerLevelPoiStyle(iconStyle: redIcon, level: 0)])
            lm.addPoiStyle(redStyle)
        }

        private func circleImage(color: UIColor, size: CGFloat) -> UIImage {
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.setFillColor(color.cgColor)
            ctx.addEllipse(in: rect)
            ctx.fillPath()
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(2)
            ctx.addEllipse(in: rect.insetBy(dx: 1, dy: 1))
            ctx.strokePath()
            let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()
            return img
        }

        // MARK: - Markers

        func updateMarkers(_ items: [MapPlaceItem]) {
            guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }
            let lm = mapView.getLabelManager()
            lm.removeLabelLayer(layerID: "officialLayer")
            lm.removeLabelLayer(layerID: "searchLayer")
            markerLookup.removeAll()

            addPoiLayer(
                mapView: mapView,
                layerID: "officialLayer",
                styleID: "official",
                zOrder: 20,
                items: items.filter { $0.isOfficialSpot }
            )
            addPoiLayer(
                mapView: mapView,
                layerID: "searchLayer",
                styleID: "search",
                zOrder: 10,
                items: items.filter { !$0.isOfficialSpot }
            )
        }

        private func addPoiLayer(mapView: KakaoMap, layerID: String, styleID: String, zOrder: Int, items: [MapPlaceItem]) {
            guard !items.isEmpty else { return }
            let lm = mapView.getLabelManager()
            let opt = LabelLayerOptions(
                layerID: layerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: zOrder
            )
            guard let layer = lm.addLabelLayer(option: opt) else { return }
            for item in items {
                let poiOpt = PoiOptions(styleID: styleID)
                poiOpt.rank = 0
                poiOpt.clickable = true
                let pt = MapPoint(longitude: item.longitude, latitude: item.latitude)
                if let poi = layer.addPoi(option: poiOpt, at: pt) {
                    poi.show()
                    markerLookup[poi.itemID] = item
                }
            }
        }

        // MARK: - User Location

        func updateUserLocation(_ coordinate: CLLocationCoordinate2D) {
            guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }
            let lm = mapView.getLabelManager()
            lm.removeLabelLayer(layerID: "userLayer")
            let opt = LabelLayerOptions(layerID: "userLayer", competitionType: .none, competitionUnit: .poi, orderType: .rank, zOrder: 30)
            let layer = lm.addLabelLayer(option: opt)
            let poiOpt = PoiOptions(styleID: "user")
            poiOpt.rank = 0
            let pt = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
            layer?.addPoi(option: poiOpt, at: pt)?.show()
        }

        // MARK: - Radius Polygon

        private func setupShapeLayer(_ mapView: KakaoMap) {
            let sm = mapView.getShapeManager()

            // 반경 채움 스타일
            let fillStyle = PolygonStyleSet(styleSetID: "radiusFill", styles: [
                PolygonStyle(styles: [
                    PerLevelPolygonStyle(color: UIColor.systemBlue.withAlphaComponent(0.12),
                                        strokeWidth: 0,
                                        strokeColor: .clear,
                                        level: 0)
                ])
            ])
            sm.addPolygonStyleSet(fillStyle)

            // 반경 외곽선 스타일
            let borderStyle = PolylineStyleSet(styleSetID: "radiusBorder", styles: [
                PolylineStyle(styles: [
                    PerLevelPolylineStyle(bodyColor: UIColor.systemBlue.withAlphaComponent(0.7),
                                         bodyWidth: 2,
                                         strokeColor: .clear,
                                         strokeWidth: 0,
                                         level: 0)
                ])
            ])
            sm.addPolylineStyleSet(borderStyle)

            sm.addShapeLayer(layerID: "radiusLayer", zOrder: 1)
        }

        func updateRadius(center: MapPoint, meters: Double) {
            guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }
            let sm = mapView.getShapeManager()

            // 레이어 재생성
            sm.removeShapeLayer(layerID: "radiusLayer")
            guard let layer = sm.addShapeLayer(layerID: "radiusLayer", zOrder: 1) else { return }

            let pts = circlePoints(center: center, radiusMeters: meters, count: 64)

            // 채움 폴리곤
            let fillOpt = MapPolygonShapeOptions(shapeID: "radiusFill", styleID: "radiusFill", zOrder: 0)
            fillOpt.polygons = [MapPolygon(exteriorRing: pts, hole: nil, styleIndex: 0)]
            layer.addMapPolygonShape(fillOpt)?.show()

            // 외곽선 폴리라인 (닫힌 링)
            let borderOpt = MapPolylineShapeOptions(shapeID: "radiusBorder", styleID: "radiusBorder", zOrder: 1)
            borderOpt.polylines = [MapPolyline(line: pts + [pts[0]], styleIndex: 0)]
            layer.addMapPolylineShape(borderOpt)?.show()
        }

        private func circlePoints(center: MapPoint, radiusMeters: Double, count: Int) -> [MapPoint] {
            let lat = center.wgsCoord.latitude  * .pi / 180
            let lng = center.wgsCoord.longitude * .pi / 180
            let R   = 6371000.0

            return (0..<count).map { i in
                let angle = 2 * Double.pi * Double(i) / Double(count)
                let dLat  = (radiusMeters / R) * cos(angle)
                let dLng  = (radiusMeters / R) * sin(angle) / cos(lat)
                return MapPoint(
                    longitude: (lng + dLng) * 180 / .pi,
                    latitude:  (lat + dLat) * 180 / .pi
                )
            }
        }

        // MARK: - Camera

        func moveCamera(to coordinate: CLLocationCoordinate2D) {
            guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }
            let pt = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
            let update = CameraUpdate.make(target: pt, zoomLevel: 15, mapView: mapView)
            mapView.moveCamera(update)
        }
    }
}
