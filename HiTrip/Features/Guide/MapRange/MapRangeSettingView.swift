import SwiftUI
import MapKit

// MARK: - MapRangeSettingView
/// 지도 범위 설정 (지오펜스) — Figma 12380:1051
///
/// 일차별로 중심과 반경을 따로 저장합니다.
/// 저장된 좌표는 고정이라 안내사가 이동해도 원이 따라오지 않습니다.

struct MapRangeSettingView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MapRangeSettingViewModel()

    @State private var camera: MapCameraPosition = .automatic
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
        .overlay(alignment: .top) { toastView }
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
        MapReader { proxy in
            Map(position: $camera) {
                if let center = viewModel.centerCoordinate {
                    MapCircle(center: center, radius: Double(viewModel.radiusKm) * 1000)
                        .foregroundStyle(AppColor.accent.opacity(0.10))
                        .stroke(AppColor.accent, lineWidth: 2)

                    Annotation("", coordinate: center) {
                        ZStack {
                            Circle()
                                .fill(AppColor.brand)
                                .frame(width: 26, height: 26)
                            Image(systemName: "mappin")
                                .font(AppFont.captionBold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            // 지도 롱프레스로도 중심을 지정할 수 있습니다
            .onLongPressGesture(minimumDuration: 0.4) { } onPressingChanged: { _ in }
            .gesture(
                LongPressGesture(minimumDuration: 0.4)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        if case .second(_, let drag?) = value,
                           let coordinate = proxy.convert(drag.location, from: .local) {
                            viewModel.setCenter(coordinate)
                        }
                    }
            )
        }
    }

    private func focusCenter() {
        guard let center = viewModel.centerCoordinate else { return }
        // 반경이 화면에 들어오도록 여유를 둡니다
        let span = Double(viewModel.radiusKm) / 111.0 * 2.6
        withAnimation {
            camera = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            ))
        }
    }

    // MARK: - 헤더 / 일차 탭

    private var headerSection: some View {
        ZStack {
            Text("지도 범위 설정")
                .font(AppFont.headlineBold)
                .foregroundColor(AppColor.textPrimary)

            HStack {
                Button { requestLeave() } label: {
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

    @ViewBuilder
    private var toastView: some View {
        if let toast = viewModel.toast {
            Text(toast)
                .font(AppFont.labelMedium)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(AppColor.textPrimary.opacity(0.92))
                .clipShape(Capsule())
                .padding(.top, 100)
                .task(id: toast) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    viewModel.toast = nil
                }
        }
    }
}
