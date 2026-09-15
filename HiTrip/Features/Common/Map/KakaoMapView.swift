import SwiftUI
import UIKit
import CoreLocation
import KakaoMapsSDK

// MARK: - KakaoMapView
/// 카카오맵 공용 지도 — 핀·반경 원·카메라·탭 이벤트
///
/// 화면은 "무엇을 그릴지"만 넘기고, SDK 호출은 모두 여기서 합니다.
/// - pins: 색 원형 핀. 탭하면 onPinTap(id)
/// - circles: 반경 원 (카카오 SDK에 원 도형이 없어 64각형으로 그립니다)
/// - camera: 값이 바뀔 때마다 한 번 적용됩니다 (같은 명령을 다시 보내려면 새로 만들면 됩니다)
/// - onTap / onLongPress: 지도 좌표
///
/// KakaoMapsSDK는 UIViewController 생명주기(엔진 활성·일시정지)가 필요해
/// UIViewControllerRepresentable로 감쌉니다.

struct KakaoMapView: UIViewControllerRepresentable {

    var pins: [MapPin] = []
    var circles: [MapCircleOverlay] = []
    var camera: MapCameraCommand?
    /// 첫 화면 중심 — 좌표를 받기 전에 보이는 곳 (기본: 서울시청)
    var initialCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    var onTap: ((CLLocationCoordinate2D) -> Void)?
    var onLongPress: ((CLLocationCoordinate2D) -> Void)?
    var onPinTap: ((String) -> Void)?

    func makeUIViewController(context: Context) -> KakaoMapHostController {
        KakaoMapHostController(initialCenter: initialCenter)
    }

    func updateUIViewController(_ controller: KakaoMapHostController, context: Context) {
        controller.onTap = onTap
        controller.onLongPress = onLongPress
        controller.onPinTap = onPinTap
        controller.render(pins: pins, circles: circles, camera: camera)
    }

    static func dismantleUIViewController(_ controller: KakaoMapHostController, coordinator: ()) {
        controller.shutdown()
    }

    /// 중심에서 반경만큼 떨어진 둘레 좌표 — 원 그리기와 "원 전체 보기" 카메라에 씁니다
    static func circlePoints(center: CLLocationCoordinate2D, radiusM: Double, count: Int = 64) -> [CLLocationCoordinate2D] {
        let lat = center.latitude * .pi / 180
        let lng = center.longitude * .pi / 180
        let earth = 6_371_000.0
        return (0..<count).map { i in
            let angle = 2 * Double.pi * Double(i) / Double(count)
            return CLLocationCoordinate2D(
                latitude: (lat + (radiusM / earth) * cos(angle)) * 180 / .pi,
                longitude: (lng + (radiusM / earth) * sin(angle) / cos(lat)) * 180 / .pi
            )
        }
    }
}

// MARK: - 그릴 것

struct MapPin: Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    var color: UIColor
    /// GPS가 끊긴 옛 위치 등을 반투명으로
    var opacity: CGFloat = 1

    static func == (l: MapPin, r: MapPin) -> Bool {
        l.id == r.id && l.coordinate.latitude == r.coordinate.latitude
            && l.coordinate.longitude == r.coordinate.longitude
            && l.color == r.color && l.opacity == r.opacity
    }
}

struct MapCircleOverlay: Equatable {
    let id: String
    let center: CLLocationCoordinate2D
    let radiusM: Double
    var fill: UIColor
    var stroke: UIColor

    static func == (l: MapCircleOverlay, r: MapCircleOverlay) -> Bool {
        l.id == r.id && l.center.latitude == r.center.latitude
            && l.center.longitude == r.center.longitude && l.radiusM == r.radiusM
            && l.fill == r.fill && l.stroke == r.stroke
    }
}

struct MapCameraCommand: Equatable {
    enum Kind {
        /// 한 지점으로 — level은 카카오 줌 레벨(클수록 확대, 15 ≈ 동네)
        case center(CLLocationCoordinate2D, level: Int)
        /// 모든 좌표가 화면에 들어오도록
        case fit([CLLocationCoordinate2D])
    }

    let id = UUID()
    let kind: Kind

    static func center(_ coordinate: CLLocationCoordinate2D, level: Int = 16) -> MapCameraCommand {
        MapCameraCommand(kind: .center(coordinate, level: level))
    }

    static func fit(_ coordinates: [CLLocationCoordinate2D]) -> MapCameraCommand {
        MapCameraCommand(kind: .fit(coordinates))
    }

    static func == (l: MapCameraCommand, r: MapCameraCommand) -> Bool { l.id == r.id }
}

// MARK: - KakaoMapHostController

final class KakaoMapHostController: UIViewController, MapControllerDelegate {

    var onTap: ((CLLocationCoordinate2D) -> Void)?
    var onLongPress: ((CLLocationCoordinate2D) -> Void)?
    var onPinTap: ((String) -> Void)?

    private static let viewName = "mapView"
    private static let pinLayerID = "pinLayer"
    private static let shapeLayerID = "circleLayer"

    private let initialCenter: CLLocationCoordinate2D
    private var controller: KMController?
    private var isReady = false
    private var eventHandlers: [DisposableEventHandler] = []

    // 마지막으로 받은 값과 실제로 그린 값 — 바뀐 것만 다시 그립니다
    private var pins: [MapPin] = []
    private var circles: [MapCircleOverlay] = []
    private var camera: MapCameraCommand?
    private var drawnPins: [MapPin]?
    private var drawnCircles: [MapCircleOverlay]?
    private var appliedCameraID: UUID?

    private var pinIDByItemID: [String: String] = [:]
    private var registeredStyleIDs = Set<String>()

    private var map: KakaoMap? { controller?.getView(Self.viewName) as? KakaoMap }

    init(initialCenter: CLLocationCoordinate2D) {
        self.initialCenter = initialCenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    // MARK: - 생명주기

    override func viewDidLoad() {
        super.viewDidLoad()
        // 엔진이 다시 그려지기 전 잠깐 비치는 배경 — 투명이면 아래 화면 색(붉은 톤 등)이 보였습니다
        view.backgroundColor = .white

        let container = KMViewContainer()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        controller = KMController(viewContainer: container)
        controller?.delegate = self
        controller?.prepareEngine()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        controller?.activateEngine()
    }

    /// 스크롤 화면 안의 작은 지도는 준비 시점에 크기가 0이라 타일이 그려지지 않습니다.
    /// 배치가 끝날 때마다 실제 크기로 맞춥니다.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isReady, view.bounds.width > 0, view.bounds.height > 0,
              let map, map.viewRect.size != view.bounds.size else { return }
        map.viewRect = view.bounds
    }

    /// 화면 전환이 끝난 뒤 한 번 더 켭니다.
    /// 지도 화면 위에 지도가 있는 화면(스팟 상세)을 올리면, 아래 화면의 viewWillDisappear가
    /// 새 화면의 viewWillAppear보다 늦게 불려 엔진을 멈춰 버립니다 → 새 지도가 회색으로 남음.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        controller?.activateEngine()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        controller?.pauseEngine()
    }

    func shutdown() {
        eventHandlers.forEach { $0.dispose() }
        eventHandlers.removeAll()
        controller?.pauseEngine()
        controller?.resetEngine()
    }

    // MARK: - MapControllerDelegate

    func addViews() {
        let info = MapviewInfo(
            viewName: Self.viewName,
            viewInfoName: "map",
            defaultPosition: initialCenter.mapPoint,
            defaultLevel: 15
        )
        controller?.addView(info)
    }

    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
        guard let map else { return }
        map.viewRect = view.bounds
        isReady = true

        eventHandlers = [
            map.addTerrainTappedEventHandler(target: self) { owner in
                { param in owner.dispatch { owner.onTap?(param.position.coordinate) } }
            },
            map.addTerrainLongPressedEventHandler(target: self) { owner in
                { param in owner.dispatch { owner.onLongPress?(param.position.coordinate) } }
            },
            map.addPoisTappedEventHandler(target: self) { owner in
                { param in
                    owner.dispatch {
                        guard let pinID = owner.pinIDByItemID[param.poiID] else { return }
                        owner.onPinTap?(pinID)
                    }
                }
            },
        ]
        refresh()
    }

    func addViewFailed(_ viewName: String, viewInfoName: String) {
        print("[KakaoMap] addViewFailed: \(viewName)")
    }

    func containerDidResized(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        map?.viewRect = CGRect(origin: .zero, size: size)
    }

    func authenticationSucceeded() {}

    func authenticationFailed(_ errorCode: Int, desc: String) {
        print("[KakaoMap] 인증 실패 \(errorCode): \(desc)")
    }

    // MARK: - 그리기

    func render(pins: [MapPin], circles: [MapCircleOverlay], camera: MapCameraCommand?) {
        self.pins = pins
        self.circles = circles
        self.camera = camera
        refresh()
    }

    private func refresh() {
        guard isReady, let map else { return }
        if drawnCircles != circles {
            drawCircles(on: map)
            drawnCircles = circles
        }
        if drawnPins != pins {
            drawPins(on: map)
            drawnPins = pins
        }
        if let camera, camera.id != appliedCameraID {
            appliedCameraID = camera.id
            move(map, with: camera)
        }
    }

    private func drawPins(on map: KakaoMap) {
        let labels = map.getLabelManager()
        labels.removeLabelLayer(layerID: Self.pinLayerID)
        pinIDByItemID.removeAll()
        guard !pins.isEmpty else { return }

        let option = LabelLayerOptions(
            layerID: Self.pinLayerID, competitionType: .none,
            competitionUnit: .poi, orderType: .rank, zOrder: 20
        )
        guard let layer = labels.addLabelLayer(option: option) else { return }

        for pin in pins {
            let poiOption = PoiOptions(styleID: pinStyleID(for: pin, labels: labels))
            poiOption.rank = 0
            poiOption.clickable = true
            if let poi = layer.addPoi(option: poiOption, at: pin.coordinate.mapPoint) {
                poi.show()
                pinIDByItemID[poi.itemID] = pin.id
            }
        }
    }

    /// 색·투명도별 핀 스타일을 처음 쓸 때 한 번 등록합니다
    private func pinStyleID(for pin: MapPin, labels: LabelManager) -> String {
        let id = "pin_\(pin.color.styleKey)_\(Int(pin.opacity * 100))"
        guard !registeredStyleIDs.contains(id) else { return id }

        let image = Self.pinImage(color: pin.color, opacity: pin.opacity)
        let icon = PoiIconStyle(symbol: image, anchorPoint: CGPoint(x: 0.5, y: 0.5))
        labels.addPoiStyle(PoiStyle(styleID: id, styles: [PerLevelPoiStyle(iconStyle: icon, level: 0)]))
        registeredStyleIDs.insert(id)
        return id
    }

    private func drawCircles(on map: KakaoMap) {
        let shapes = map.getShapeManager()
        shapes.removeShapeLayer(layerID: Self.shapeLayerID)
        guard !circles.isEmpty else { return }
        // zOrder가 낮으면 기본 지도 타일 아래에 깔려 보이지 않습니다 — 카카오 예제와 같은 10001
        guard let layer = shapes.addShapeLayer(layerID: Self.shapeLayerID, zOrder: 10001) else {
            #if DEBUG
            print("🗺️ [KakaoMap] shape layer 생성 실패 — 원 \(circles.count)개를 그리지 못함")
            #endif
            return
        }

        for circle in circles {
            let styleID = "circle_\(circle.fill.styleKey)_\(circle.stroke.styleKey)"
            if !registeredStyleIDs.contains(styleID) {
                // SwiftUI Color에서 만든 UIColor는 색 공간이 달라 카카오 렌더러가 투명으로 그립니다 → sRGB로 변환
                let style = PerLevelPolygonStyle(
                    color: circle.fill.sRGB, strokeWidth: 3, strokeColor: circle.stroke.sRGB, level: 0
                )
                shapes.addPolygonStyleSet(PolygonStyleSet(styleSetID: styleID, styles: [PolygonStyle(styles: [style])]))
                registeredStyleIDs.insert(styleID)
            }

            // 원 둘레 좌표는 SDK 함수로 만듭니다 — 폴리곤 링 방향(cw)을 SDK 규칙에 맞추기 위함
            let ring = Primitives.getCirclePoints(
                radius: circle.radiusM, numPoints: 64, cw: true, center: circle.center.mapPoint
            )
            let option = MapPolygonShapeOptions(shapeID: circle.id, styleID: styleID, zOrder: 0)
            option.polygons = [MapPolygon(exteriorRing: ring, hole: nil, styleIndex: 0)]
            let shape = layer.addMapPolygonShape(option)
            shape?.show()
            #if DEBUG
            print("🗺️ [KakaoMap] circle \(circle.id) r=\(Int(circle.radiusM))m points=\(ring.count) shape=\(shape == nil ? "nil" : "ok")")
            #endif
        }
        // addMapPolygonShape는 도형을 비동기로 만들어 반환값이 nil일 수 있습니다.
        // 반환값에 show()를 부르면 원이 영영 안 보이므로, 레이어 단위로 표시합니다.
        layer.showAllPolygonShapes()
    }

    private func move(_ map: KakaoMap, with command: MapCameraCommand) {
        switch command.kind {
        case .center(let coordinate, let level):
            map.moveCamera(CameraUpdate.make(target: coordinate.mapPoint, zoomLevel: level, mapView: map))
        case .fit(let coordinates):
            guard let first = coordinates.first else { return }
            if coordinates.count == 1 {
                map.moveCamera(CameraUpdate.make(target: first.mapPoint, zoomLevel: 16, mapView: map))
            } else {
                let area = AreaRect(points: coordinates.map(\.mapPoint))
                map.moveCamera(CameraUpdate.make(area: area, levelLimit: 17))
            }
        }
    }

    /// SDK 이벤트가 어느 스레드에서 오든 화면 쪽 콜백은 메인에서 부릅니다
    private func dispatch(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    /// 흰 테두리 + 흰 핀 아이콘이 들어간 26pt 원
    private static func pinImage(color: UIColor, opacity: CGFloat) -> UIImage {
        let size = CGSize(width: 26, height: 26)
        return UIGraphicsImageRenderer(size: size).image { context in
            let rect = CGRect(origin: .zero, size: size)
            color.withAlphaComponent(opacity).setFill()
            context.cgContext.fillEllipse(in: rect)
            UIColor.white.withAlphaComponent(opacity).setStroke()
            context.cgContext.setLineWidth(2)
            context.cgContext.strokeEllipse(in: rect.insetBy(dx: 1, dy: 1))

            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            if let symbol = UIImage(systemName: "mappin", withConfiguration: config)?
                .withTintColor(.white.withAlphaComponent(opacity), renderingMode: .alwaysOriginal) {
                symbol.draw(at: CGPoint(x: (size.width - symbol.size.width) / 2,
                                        y: (size.height - symbol.size.height) / 2))
            }
        }
    }
}

// MARK: - 좌표 변환

private extension CLLocationCoordinate2D {
    var mapPoint: MapPoint { MapPoint(longitude: longitude, latitude: latitude) }
}

private extension MapPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: wgsCoord.latitude, longitude: wgsCoord.longitude)
    }
}

private extension UIColor {
    /// 카카오 렌더러가 읽을 수 있는 단순 sRGB 색
    var sRGB: UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(max(r, 0), 1), green: min(max(g, 0), 1), blue: min(max(b, 0), 1), alpha: a)
    }

    /// 스타일 ID용 색 키 (RGBA 16진수)
    var styleKey: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }
}
