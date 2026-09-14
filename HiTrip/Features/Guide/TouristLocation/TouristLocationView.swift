import SwiftUI
import MapKit
import UIKit

// MARK: - TouristLocationView
/// 관광객 위치 확인 — Figma 12381:4267
///
/// 관광객 핀(보라)과 안내사 핀(파랑), 허용 범위 경계를 함께 보여줍니다.
/// 관광객 좌표는 10초마다 갱신하고, GPS가 끊기면 마지막 위치를 반투명으로 표시합니다.

struct TouristLocationView: View {

    /// 어느 관광객인지 — 안전 관리·알림 센터에서 넘겨줍니다
    let participantId: Int
    /// 좌표를 받기 전에 헤더에 보여줄 이름
    var touristName: String = ""

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TouristLocationViewModel

    @State private var camera: MapCameraCommand?
    /// 첫 좌표를 받으면 한 번만 전체 보기로 맞춥니다 — 이후엔 사용자가 옮긴 화면을 유지합니다
    @State private var hasFocusedOnce = false

    init(participantId: Int, touristName: String = "") {
        self.participantId = participantId
        self.touristName = touristName
        _viewModel = StateObject(wrappedValue: TouristLocationViewModel(participantId: participantId))
    }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                headerSection
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                legend
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, 38)

                mapButtons
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, 19)

                callButton
                    .padding(.horizontal, 21)
                    .padding(.bottom, AppSpacing.xl)
            }

            if viewModel.returnedNotice {
                returnedToast
            }
        }
        .background(AppColor.successSubtle)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
        .onChange(of: viewModel.touristCoordinate?.latitude) { _, _ in
            guard !hasFocusedOnce else { return }
            hasFocusedOnce = true
            focusAll()
        }
    }

    // MARK: - 지도

    private var mapLayer: some View {
        KakaoMapView(pins: mapPins, circles: mapCircles, camera: camera)
    }

    /// 관광객(보라) · 안내사(파랑) 핀 — 이름은 하단 범례로 구분합니다
    private var mapPins: [MapPin] {
        var pins: [MapPin] = []
        if let coordinate = viewModel.touristCoordinate {
            // GPS가 끊기면 반투명으로 — 옛 위치라는 표시
            pins.append(MapPin(id: "tourist", coordinate: coordinate,
                               color: UIColor(AppColor.touristPin),
                               opacity: viewModel.isStale ? 0.45 : 1))
        }
        if let guide = viewModel.guideLocation {
            pins.append(MapPin(id: "guide", coordinate: guide, color: UIColor(AppColor.brand)))
        }
        return pins
    }

    /// 허용 범위 경계 — 빨간 실선
    private var mapCircles: [MapCircleOverlay] {
        guard let center = viewModel.geofenceCenter, let radius = viewModel.geofenceRadiusM else { return [] }
        return [MapCircleOverlay(id: "geofence", center: center, radiusM: radius,
                                 fill: UIColor.red.withAlphaComponent(0.05), stroke: .red)]
    }

    private func pin(color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
            Image(systemName: "mappin")
                .font(AppFont.captionBold)
                .foregroundColor(.white)
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        VStack(spacing: 0) {
            NavigationHeader(
                title: "\(viewModel.touristName.isEmpty ? touristName : viewModel.touristName) 님의 현재 위치",
                style: .compact
            ) { dismiss() }

            HStack(alignment: .firstTextBaseline) {
                Text("주소: \(viewModel.address.isEmpty ? "확인 중" : viewModel.address)")
                    .font(AppFont.label)
                    .foregroundColor(AppColor.textBody)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(viewModel.updatedText)
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, 17)
            .padding(.bottom, AppSpacing.sm)
        }
        .background(Color.white)
    }

    // MARK: - 범례

    private var legend: some View {
        HStack(spacing: AppSpacing.xs) {
            Rectangle()
                .fill(Color.red)
                .frame(width: 14, height: 3)
                .cornerRadius(1)
            Text("허용 범위 경계")
                .font(AppFont.caption)
                .foregroundColor(AppColor.textBody)
        }
        .padding(.horizontal, AppSpacing.sm)
        .frame(height: 30)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    // MARK: - 지도 이동 버튼

    private var mapButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            mapButton("내 위치", isPrimary: false) {
                if let guide = viewModel.guideLocation { focus(on: guide) }
            }
            mapButton("관광객 위치", isPrimary: false) {
                if let coordinate = viewModel.touristCoordinate { focus(on: coordinate) }
            }
            mapButton("전체 보기", isPrimary: true) { focusAll() }
        }
    }

    private func mapButton(_ title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(isPrimary ? AppFont.labelBold : AppFont.labelMedium)
                .foregroundColor(isPrimary ? AppColor.accent : AppColor.textBody)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isPrimary ? AppColor.accentSubtle : AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }

    private func focus(on coordinate: CLLocationCoordinate2D) {
        camera = .center(coordinate, level: 16)
    }

    /// 두 핀과 경계 원이 모두 보이도록 줌을 맞춥니다
    private func focusAll() {
        var points: [CLLocationCoordinate2D] = []
        if let tourist = viewModel.touristCoordinate { points.append(tourist) }
        if let guide = viewModel.guideLocation { points.append(guide) }
        if let center = viewModel.geofenceCenter, let radius = viewModel.geofenceRadiusM {
            // 원 둘레 좌표를 넣어 경계까지 화면에 담습니다
            points += KakaoMapView.circlePoints(center: center, radiusM: radius * 1.2, count: 8)
        }
        guard !points.isEmpty else { return }
        camera = .fit(points)
    }

    // MARK: - 전화걸기

    private var callButton: some View {
        Button { call() } label: {
            Text("전화걸기")
                .font(AppFont.bodyLBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(viewModel.phoneNumber == nil
                            ? AppColor.borderMuted : AppColor.danger)
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.phoneNumber == nil)
    }

    private func call() {
        guard let phone = viewModel.phoneNumber else { return }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - 복귀 토스트

    private var returnedToast: some View {
        ToastView(message: "범위 내로 복귀했어요")
            .padding(.top, 120)
            .task(id: viewModel.returnedNotice) {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                viewModel.returnedNotice = false
            }
    }
}
