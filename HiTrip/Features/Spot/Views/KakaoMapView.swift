import SwiftUI
import KakaoMapsSDK
import CoreLocation

// MARK: - KakaoMapView
/// KakaoMapsSDK를 SwiftUI에서 사용하기 위한 UIViewControllerRepresentable 래퍼
///
/// UIViewRepresentable 대신 UIViewControllerRepresentable을 사용하는 이유:
/// KakaoMapsSDK는 UIViewController 라이프사이클(viewWillAppear/Disappear)을 필요로 함

struct KakaoMapView: UIViewControllerRepresentable {

    let latitude: Double
    let longitude: Double
    @Binding var draw: Bool
    var markers: [MapPlaceItem] = []
    var userLocation: CLLocationCoordinate2D?
    var radiusMeters: Double = 0
    var cameraTarget: MapViewModel.CameraTarget?
    var onMarkerTapped: ((MapPlaceItem) -> Void)?

    func makeUIViewController(context: Context) -> KakaoMapViewController {
        let vc = KakaoMapViewController(
            latitude: latitude,
            longitude: longitude,
            onMarkerTapped: onMarkerTapped
        )
        return vc
    }

    func updateUIViewController(_ vc: KakaoMapViewController, context: Context) {
        if draw {
            vc.activate()
        } else {
            vc.pause()
        }

        guard vc.isMapReady else { return }

        vc.updateMarkers(markers)
        if let loc = userLocation { vc.updateUserLocation(loc) }
        if radiusMeters > 0 {
            vc.updateRadius(
                center: MapPoint(longitude: longitude, latitude: latitude),
                meters: radiusMeters
            )
        }
        if let target = cameraTarget, target != vc.lastCameraTarget {
            vc.lastCameraTarget = target
            vc.moveCamera(to: target.coordinate)
        }
    }

    static func dismantleUIViewController(_ vc: KakaoMapViewController, coordinator: ()) {
        vc.controller?.resetEngine()
    }
}

// MARK: - KakaoMapViewController

final class KakaoMapViewController: UIViewController, MapControllerDelegate {

    var controller: KMController?
    let latitude: Double
    let longitude: Double
    var onMarkerTapped: ((MapPlaceItem) -> Void)?

    var isMapReady = false
    var lastCameraTarget: MapViewModel.CameraTarget?
    private var markerLookup: [String: MapPlaceItem] = [:]

    init(latitude: Double, longitude: Double, onMarkerTapped: ((MapPlaceItem) -> Void)?) {
        self.latitude = latitude
        self.longitude = longitude
        self.onMarkerTapped = onMarkerTapped
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let container = KMViewContainer()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        controller = KMController(viewContainer: container)
        controller?.delegate = self
        controller?.prepareEngine()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        controller?.activateEngine()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controller?.pauseEngine()
    }

    func activate() { controller?.activateEngine() }
    func pause()    { controller?.pauseEngine()    }

    // MARK: - MapControllerDelegate

    func addViews() {
        print("🗺️ [KakaoMap] addViews 호출됨")
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
        mapView.viewRect = view.bounds
        registerPoiStyles(mapView)
        setupShapeStyles(mapView)
    }

    func addViewFailed(_ viewName: String, viewInfoName: String) {
        print("❌ [KakaoMap] addViewFailed: \(viewName)")
    }

    func containerDidResized(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let mapView = controller?.getView("mapView") as? KakaoMap
        mapView?.viewRect = CGRect(origin: .zero, size: size)
    }

    func authenticationSucceeded() { print("✅ [KakaoMap] 인증 성공") }
    func authenticationFailed(_ errorCode: Int, desc: String) {
        print("❌ [KakaoMap] 인증 실패 \(errorCode): \(desc)")
    }

    // MARK: - POI Styles

    private func registerPoiStyles(_ mapView: KakaoMap) {
        let lm = mapView.getLabelManager()
        for (id, color, size) in [("official", UIColor.systemBlue, 20.0),
                                   ("search",   UIColor.systemOrange, 16.0),
                                   ("user",     UIColor.systemRed,    18.0)] {
            let img   = circleImage(color: color, size: size)
            let icon  = PoiIconStyle(symbol: img, anchorPoint: CGPoint(x: 0.5, y: 0.5))
            let style = PoiStyle(styleID: id, styles: [PerLevelPoiStyle(iconStyle: icon, level: 0)])
            lm.addPoiStyle(style)
        }
    }

    private func circleImage(color: UIColor, size: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(color.cgColor)
        ctx.addEllipse(in: rect); ctx.fillPath()
        ctx.setStrokeColor(UIColor.white.cgColor); ctx.setLineWidth(2)
        ctx.addEllipse(in: rect.insetBy(dx: 1, dy: 1)); ctx.strokePath()
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    // MARK: - Shape Styles

    private func setupShapeStyles(_ mapView: KakaoMap) {
        let sm = mapView.getShapeManager()
        sm.addPolygonStyleSet(PolygonStyleSet(styleSetID: "radiusFill", styles: [
            PolygonStyle(styles: [PerLevelPolygonStyle(
                color: UIColor.systemBlue.withAlphaComponent(0.12),
                strokeWidth: 0, strokeColor: .clear, level: 0)])
        ]))
        sm.addPolylineStyleSet(PolylineStyleSet(styleSetID: "radiusBorder", styles: [
            PolylineStyle(styles: [PerLevelPolylineStyle(
                bodyColor: UIColor.systemBlue.withAlphaComponent(0.7),
                bodyWidth: 2, strokeColor: .clear, strokeWidth: 0, level: 0)])
        ]))
    }

    // MARK: - Markers

    func updateMarkers(_ items: [MapPlaceItem]) {
        guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }
        let lm = mapView.getLabelManager()
        lm.removeLabelLayer(layerID: "officialLayer")
        lm.removeLabelLayer(layerID: "searchLayer")
        markerLookup.removeAll()
        addPoiLayer(mapView: mapView, layerID: "officialLayer", styleID: "official", zOrder: 20,
                    items: items.filter { $0.isOfficialSpot })
        addPoiLayer(mapView: mapView, layerID: "searchLayer",   styleID: "search",   zOrder: 10,
                    items: items.filter { !$0.isOfficialSpot })
    }

    private func addPoiLayer(mapView: KakaoMap, layerID: String, styleID: String, zOrder: Int, items: [MapPlaceItem]) {
        guard !items.isEmpty else { return }
        let lm  = mapView.getLabelManager()
        let opt = LabelLayerOptions(layerID: layerID, competitionType: .none, competitionUnit: .poi, orderType: .rank, zOrder: zOrder)
        guard let layer = lm.addLabelLayer(option: opt) else { return }
        for item in items {
            let poiOpt = PoiOptions(styleID: styleID)
            poiOpt.rank = 0; poiOpt.clickable = true
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
        let lm  = mapView.getLabelManager()
        lm.removeLabelLayer(layerID: "userLayer")
        let opt   = LabelLayerOptions(layerID: "userLayer", competitionType: .none, competitionUnit: .poi, orderType: .rank, zOrder: 30)
        let layer = lm.addLabelLayer(option: opt)
        let poiOpt = PoiOptions(styleID: "user"); poiOpt.rank = 0
        layer?.addPoi(option: poiOpt, at: MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude))?.show()
    }

    // MARK: - Radius

    func updateRadius(center: MapPoint, meters: Double) {
        guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }
        let sm = mapView.getShapeManager()
        sm.removeShapeLayer(layerID: "radiusLayer")
        guard let layer = sm.addShapeLayer(layerID: "radiusLayer", zOrder: 1) else { return }
        let pts = circlePoints(center: center, radiusMeters: meters, count: 64)

        let fillOpt = MapPolygonShapeOptions(shapeID: "radiusFill", styleID: "radiusFill", zOrder: 0)
        fillOpt.polygons = [MapPolygon(exteriorRing: pts, hole: nil, styleIndex: 0)]
        layer.addMapPolygonShape(fillOpt)?.show()

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
            return MapPoint(
                longitude: (lng + (radiusMeters / R) * sin(angle) / cos(lat)) * 180 / .pi,
                latitude:  (lat + (radiusMeters / R) * cos(angle)) * 180 / .pi
            )
        }
    }

    // MARK: - Camera

    func moveCamera(to coordinate: CLLocationCoordinate2D) {
        guard let mapView = controller?.getView("mapView") as? KakaoMap else { return }
        let pt     = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
        let update = CameraUpdate.make(target: pt, zoomLevel: 15, mapView: mapView)
        mapView.moveCamera(update)
    }
}
