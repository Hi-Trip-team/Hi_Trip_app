import SwiftUI
import CoreLocation

// MARK: - MapRangeSettingView
/// 지도 범위 설정 (지오펜스) — Figma 12380:1051
///
/// 일차별로 중심과 반경을 따로 저장합니다.
/// 저장된 좌표는 고정이라 안내사가 이동해도 원이 따라오지 않습니다.

struct MapRangeSettingView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MapRangeSettingViewModel()

    @State private var camera: MapCameraCommand?
    @State private var showLeaveConfirm = false

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                dayTabs
                    .padding(.top, 29)
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                bottomSheet
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .toast($viewModel.toast, alignment: .top, inset: 100)
        .background(AppColor.successSubtle)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.centerCoordinate?.latitude) { _, _ in focusCenter() }
        .confirmationDialog(
            "변경사항을 저장하지 않고 나가시겠습니까?",
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("나가기", role: .destructive) { dismiss() }
            Button("계속", role: .cancel) { }
        }
        .alert("저장하지 못했어요", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            Button("재시도") { viewModel.saveError = nil; viewModel.save() }
            Button("닫기", role: .cancel) { viewModel.saveError = nil }
        } message: {
            Text(viewModel.saveError ?? "")
        }
    }

    // MARK: - 지도

    private var mapLayer: some View {
        KakaoMapView(
            pins: viewModel.centerCoordinate.map {
                [MapPin(id: "center", coordinate: $0, color: UIColor(AppColor.brand))]
            } ?? [],
            circles: viewModel.centerCoordinate.map {
                [MapCircleOverlay(
                    id: "range", center: $0, radiusM: Double(viewModel.radiusKm) * 1000,
                    fill: UIColor(AppColor.accent).withAlphaComponent(0.10),
                    stroke: UIColor(AppColor.accent)
                )]
            } ?? [],
            camera: camera,
            // 지도 롱프레스로도 중심을 지정할 수 있습니다
            onLongPress: { viewModel.setCenter($0) }
        )
    }

    private func focusCenter() {
        guard let center = viewModel.centerCoordinate else { return }
        // 원 전체와 하단 시트에 가리는 몫까지 들어오도록 반경보다 넓게 맞춥니다
        let margin = Double(viewModel.radiusKm) * 1000 * 1.6
        camera = .fit(KakaoMapView.circlePoints(center: center, radiusM: margin, count: 8))
    }

    // MARK: - 헤더 / 일차 탭

    private var headerSection: some View {
        NavigationHeader(title: "지도 범위 설정", style: .compact) { requestLeave() }
    }

    private var dayTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(1...max(viewModel.totalDays, 1), id: \.self) { day in
                    let isOn = viewModel.selectedDay == day
                    Button { viewModel.select(day: day) } label: {
                        Text("\(day)일차")
                            .font(isOn ? AppFont.labelBold : AppFont.labelMedium)
                            .foregroundColor(isOn ? .white : AppColor.textSecondary)
                            .frame(width: 78, height: 36)
                            .background(isOn ? AppColor.accent : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
        }
    }

    // MARK: - 하단 시트

    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.xxs) {
                Text("중심 주소")
                    .font(AppFont.bodyMBold)
                    .foregroundColor(.black)
                Text("|  탭하여 검색, 지도 롱프레스로도 지정")
                    .font(AppFont.bodyMMedium)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.top, AppSpacing.xxl)

            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(AppFont.bodyL)
                    .foregroundColor(AppColor.danger)
                Text(viewModel.centerAddress.isEmpty ? "중심을 지정해주세요" : viewModel.centerAddress)
                    .font(AppFont.bodyMMedium)
                    .foregroundColor(.black)
                    .lineLimit(1)
            }
            .padding(.top, 14)

            if viewModel.isUnset {
                // 미설정 일차는 전일 값을 기본으로 제안합니다
                Text("아직 설정되지 않은 일차예요. 전일 설정을 기본값으로 불러왔습니다.")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.warning)
                    .padding(.top, AppSpacing.xs)
            }

            HStack {
                Text("허용 반경")
                    .font(AppFont.bodyMMedium)
                    .foregroundColor(.black)
                Spacer()
                Text("\(viewModel.radiusKm)km")
                    .font(AppFont.bodyMBold)
                    .foregroundColor(.black)
            }
            .padding(.top, 26)

            // 1~10km 정수 단계
            Slider(
                value: Binding(
                    get: { Double(viewModel.radiusKm) },
                    set: { viewModel.radiusKm = Int($0.rounded()) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(AppColor.accent)
            .padding(.top, 6)

            HStack {
                Text("1km")
                Spacer()
                Text("10km • 정수 단계")
            }
            .font(AppFont.caption)
            .foregroundColor(.black)

            Button { viewModel.useMyLocation() } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "location.fill")
                        .font(AppFont.body)
                    Text("내 위치로 중심 설정")
                        .font(AppFont.bodyLBold)
                }
                .foregroundColor(AppColor.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColor.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .padding(.top, 26)

            Button { viewModel.save() } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("저장하기")
                            .font(AppFont.bodyLBold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(viewModel.centerCoordinate == nil
                            ? AppColor.borderMuted : AppColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.centerCoordinate == nil || viewModel.isSaving)
            .padding(.top, 10)
            .padding(.bottom, 34)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }

    private func requestLeave() {
        if viewModel.hasUnsavedChanges {
            showLeaveConfirm = true
        } else {
            dismiss()
        }
    }

}
