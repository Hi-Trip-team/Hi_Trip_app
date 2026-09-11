import SwiftUI
import UIKit

// MARK: - SafetyManagementView
/// 안전 관리 — Figma 12381:4446
///
/// 상태 요약 칩(탭 시 필터·재탭 해제) / 30초 갱신 / 관광객 표
/// 행을 누르면 관광객 정보 팝업이 뜹니다.

struct SafetyManagementView: View {

    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SafetyManagementViewModel()

    @State private var selected: ParticipantLatestDTO?
    @State private var showLocation = false
    @State private var locationTarget: ParticipantLatestDTO?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                filterChips
                    .padding(.top, 21)
                updatedRow
                    .padding(.top, 14)

                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case .failed(let message):
                    errorView(message)
                case .loaded:
                    if viewModel.isEmpty {
                        emptyView
                    } else {
                        participantTable
                    }
                }
            }
            .background(Color.white)

            if let selected {
                TouristInfoPopup(
                    participant: selected,
                    profile: viewModel.profile(for: selected),
                    statusLine: viewModel.statusLine(selected),
                    canViewLocation: viewModel.canViewLocation(selected),
                    isEscaped: selected.geofenceIncident != nil,
                    onClose: { self.selected = nil },
                    onViewLocation: {
                        locationTarget = selected
                        self.selected = nil
                        showLocation = true
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selected?.participantId)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
        .navigationDestination(isPresented: $showLocation) {
            TouristLocationView(
                participantId: locationTarget?.participantId ?? 0,
                touristName: locationTarget?.travelerName ?? ""
            )
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        NavigationHeader(title: "안전 관리", style: .compact) {
            onDismiss?()
            dismiss()
        }
    }

    // MARK: - 상태 요약 칩

    private var filterChips: some View {
        HStack(spacing: AppSpacing.xs) {
            chip("전체 \(viewModel.totalCount)",
                 background: AppColor.surface, foreground: AppColor.textBody,
                 isOn: viewModel.filter == nil) { viewModel.filter = nil }

            chip("경고 \(viewModel.warningCount)",
                 background: AppColor.warningSubtle, foreground: AppColor.warning,
                 isOn: viewModel.filter == .warning) { viewModel.toggle(.warning) }

            chip("위험 \(viewModel.dangerCount)",
                 background: AppColor.dangerSubtle, foreground: AppColor.danger,
                 isOn: viewModel.filter == .danger) { viewModel.toggle(.danger) }

            chip("이탈 \(viewModel.escapedCount)",
                 background: AppColor.dangerSubtle, foreground: AppColor.danger,
                 isOn: viewModel.filter == .escaped) { viewModel.toggle(.escaped) }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private func chip(
        _ text: String, background: Color, foreground: Color,
        isOn: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(text)
                .font(AppFont.captionBold)
                .foregroundColor(foreground)
                .frame(width: 64, height: 32)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .stroke(isOn ? foreground : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var updatedRow: some View {
        HStack {
            Spacer()
            Text(viewModel.updatedText)
                .font(AppFont.caption2)
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - 표

    private var participantTable: some View {
        ScrollView {
            VStack(spacing: 0) {
                tableHeader
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xl)

                ForEach(viewModel.sortedParticipants, id: \.participantId) { p in
                    participantRow(p)
                        .padding(.horizontal, AppSpacing.xl)

                    Rectangle()
                        .fill(AppColor.divider)
                        .frame(height: 1)
                        .padding(.horizontal, AppSpacing.xl)
                }

                legend
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, 26)
                    .padding(.bottom, AppSpacing.xxl)
            }
        }
        .refreshable { viewModel.refresh() }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            headerCell("이름", width: 72)
            headerCell("연락처", width: 84)
            headerCell("이탈여부", width: 74)
            headerCell("심박수", width: 64)
            headerCell("SpO₂", width: 44)
        }
        .padding(.horizontal, AppSpacing.xs)
        .frame(height: 36)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(AppFont.caption2Bold)
            .foregroundColor(AppColor.textSecondary)
            .frame(width: width, alignment: .leading)
    }

    private func participantRow(_ p: ParticipantLatestDTO) -> some View {
        HStack(spacing: 0) {
            Text(p.travelerName)
                .font(AppFont.labelMedium)
                .foregroundColor(AppColor.accent)
                .frame(width: 72, alignment: .leading)
                .lineLimit(1)

            Text(viewModel.profile(for: p)?.phone ?? "—")
                .font(AppFont.micro)
                .foregroundColor(AppColor.textSecondary)
                .frame(width: 84, alignment: .leading)
                .lineLimit(1)

            // 이탈 거리 — 빨간 셀을 누르면 위치 확인으로 이동합니다
            Group {
                if let distance = viewModel.escapeDistanceText(p) {
                    Text(distance)
                        .font(AppFont.captionBold)
                        .foregroundColor(AppColor.danger)
                        .padding(.horizontal, AppSpacing.xs)
                        .frame(height: 20)
                        .background(AppColor.dangerSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xs))
                        .onTapGesture {
                            locationTarget = p
                            showLocation = true
                        }
                } else {
                    Text(p.locationStatus == .offline || p.locationStatus == .unknown ? "—" : "정상")
                        .font(AppFont.caption)
                        .foregroundColor(p.locationStatus == .offline || p.locationStatus == .unknown
                                         ? AppColor.textSecondary : AppColor.textBody)
                }
            }
            .frame(width: 74, alignment: .leading)

            metricCell(viewModel.heartRateText(p), level: viewModel.heartRateLevel(p), width: 64)
            metricCell(viewModel.spo2Text(p), level: viewModel.spo2Level(p), width: 44)
        }
        .padding(.horizontal, AppSpacing.xs)
        .frame(height: 56)
        .contentShape(Rectangle())
        .onTapGesture { selected = p }
    }

    /// 심박·SpO₂ 셀 — 경고는 주황, 위험은 빨강 뱃지
    private func metricCell(
        _ text: String,
        level: SafetyManagementViewModel.Level,
        width: CGFloat
    ) -> some View {
        Group {
            switch level {
            case .normal:
                Text(text)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textBody)
            case .unknown:
                Text("—")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
            case .warning, .danger:
                Text(text)
                    .font(AppFont.captionBold)
                    .foregroundColor(level == .warning ? AppColor.warning : AppColor.danger)
                    .padding(.horizontal, AppSpacing.xs)
                    .frame(height: 20)
                    .background(level == .warning ? AppColor.warningSubtle : AppColor.dangerSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.xs))
            }
        }
        .frame(width: width, alignment: .leading)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("경고(주황) · 위험(빨강) · — 데이터 수신 안 됨(워치 미연동·통신 두절)")
            Text("정렬: 위험 → 경고 → 정상 · 행 탭 시 관광객 정보 팝업")
        }
        .font(AppFont.micro)
        .foregroundColor(AppColor.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        SkeletonList(rows: 6, rowHeight: 44, spacing: AppSpacing.xs)
    }

    private var emptyView: some View {
        EmptyStateView(icon: "person.2", title: "등록된 관광객이 없습니다")
    }

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) { viewModel.load() }
    }
}

// MARK: - 관광객 정보 팝업
/// Figma 12381:4366 — 320×300 카드
///
/// 여권번호는 중간 3자리를 가리고, 👁을 누르면 3초만 보여줍니다.
/// 위치보기는 이탈이거나 건강 경고·위험일 때만 누를 수 있습니다 (프라이버시).
