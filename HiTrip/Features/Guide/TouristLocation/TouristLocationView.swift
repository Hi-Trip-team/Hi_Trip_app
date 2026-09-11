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

    @State private var camera: MapCameraPosition = .automatic

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
            if case .automatic = camera { focusAll() }
        }
    }

    // MARK: - 지도

    private var mapLayer: some View {
        Map(position: $camera) {
            // 허용 범위 경계 — 빨간 실선
            if let center = viewModel.geofenceCenter, let radius = viewModel.geofenceRadiusM {
                MapCircle(center: center, radius: radius)
                    .foregroundStyle(Color.red.opacity(0.05))
                    .stroke(Color.red, lineWidth: 2)
            }

            if let coordinate = viewModel.touristCoordinate {
                Annotation(viewModel.touristName.isEmpty ? touristName : viewModel.touristName,
                           coordinate: coordinate) {
                    pin(color: AppColor.touristPin)
                        // GPS가 끊기면 반투명으로 — 옛 위치라는 표시
                        .opacity(viewModel.isStale ? 0.45 : 1)
                }
            }

            if let guide = viewModel.guideLocation {
                Annotation("나 (안내사)", coordinate: guide) {
                    pin(color: AppColor.brand)
                }
            }
        }
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
            ZStack {
                Text("\(viewModel.touristName.isEmpty ? touristName : viewModel.touristName) 님의 현재 위치")
                    .font(AppFont.headlineBold)
                    .foregroundColor(AppColor.textPrimary)

                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(AppFont.title3Medium)
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                    }
                    Spacer()
                }
                .padding(.leading, AppSpacing.sm)
            }
            .frame(height: 24)
            .padding(.top, AppSpacing.xs)

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
        withAnimation {
            camera = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }
    }

    /// 두 핀과 경계가 모두 보이도록 줌을 맞춥니다
    private func focusAll() {
        var points: [CLLocationCoordinate2D] = []
        if let tourist = viewModel.touristCoordinate { points.append(tourist) }
        if let guide = viewModel.guideLocation { points.append(guide) }
        if let center = viewModel.geofenceCenter { points.append(center) }
        guard !points.isEmpty else { return }

        let lats = points.map(\.latitude), lngs = points.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lngs.min()! + lngs.max()!) / 2
        )
        // 경계 원까지 담기도록 반경만큼 여유를 둡니다
        let radiusDegrees = (viewModel.geofenceRadiusM ?? 0) / 111_000 * 2.4
        let span = MKCoordinateSpan(
            latitudeDelta: max(lats.max()! - lats.min()!, radiusDegrees, 0.006) * 1.4,
            longitudeDelta: max(lngs.max()! - lngs.min()!, radiusDegrees, 0.006) * 1.4
        )

        withAnimation { camera = .region(MKCoordinateRegion(center: center, span: span)) }
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
        Text("범위 내로 복귀했어요")
            .font(AppFont.labelMedium)
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(AppColor.textPrimary.opacity(0.92))
            .clipShape(Capsule())
            .padding(.top, 120)
            .task(id: viewModel.returnedNotice) {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                viewModel.returnedNotice = false
            }
    }
}
