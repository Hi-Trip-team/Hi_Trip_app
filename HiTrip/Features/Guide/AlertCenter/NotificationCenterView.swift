import SwiftUI

// MARK: - NotificationCenterView
/// 알림 센터 (안내사 전용) — Figma 12381:4544
///
/// 안전 경고·위험·이탈 알림의 단일 수신 창구입니다.
/// 위험 알림은 [확인]을 누를 때까지 서버가 5분 주기로 다시 알립니다.
///
/// 여행객에게는 노출하지 않습니다 (다른 관광객의 건강 정보가 보입니다).

struct NotificationCenterView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AlertCenterViewModel()

    @State private var showLocation = false
    @State private var locationTargetName: String?
    @State private var locationTargetId: Int?

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            filterChips
                .padding(.top, 33)

            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .failed(let message):
                errorView(message)
            case .loaded:
                if viewModel.isEmpty {
                    emptyView
                } else {
                    alertList
                }
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .navigationDestination(isPresented: $showLocation) {
            TouristLocationView(
                participantId: locationTargetId ?? 0,
                touristName: locationTargetName ?? ""
            )
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        NavigationHeader(title: "알림", style: .compact) { dismiss() }
    }

    // MARK: - 필터 칩

    private var filterChips: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(AlertCenterViewModel.Kind.allCases) { kind in
                let isOn = viewModel.kind == kind
                Button { viewModel.kind = kind } label: {
                    Text(kind.label)
                        .font(isOn ? AppFont.captionBold : AppFont.captionMedium)
                        .foregroundColor(isOn ? .white : AppColor.textSecondary)
                        .frame(width: kind == .all ? 64 : 56, height: 32)
                        .background(isOn ? AppColor.accent : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - 목록

    private var alertList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.filtered, id: \.id) { alert in
                    alertCard(alert)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, 28)
            .padding(.bottom, AppSpacing.xxl)
        }
        .refreshable { viewModel.refresh() }
    }

    private func alertCard(_ alert: MonitoringAlertDTO) -> some View {
        let needsAck = viewModel.needsAcknowledge(alert)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Text(viewModel.badgeText(alert))
                    .font(AppFont.caption2Bold)
                    .foregroundColor(badgeForeground(alert))
                    .frame(width: 44, height: 22)
                    .background(badgeBackground(alert))
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.messageText(alert))
                        .font(AppFont.captionMedium)
                        .foregroundColor(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.metaText(alert))
                        .font(AppFont.micro)
                        .foregroundColor(AppColor.textSecondary)
                        .padding(.top, AppSpacing.xs)

                    if needsAck {
                        Text("[확인] 전까지 5분 주기 재알림")
                            .font(AppFont.micro2)
                            .foregroundColor(AppColor.danger)
                            .padding(.top, 6)
                    }
                }

                Spacer(minLength: 0)
            }

            if needsAck {
                HStack {
                    Spacer()
                    Button { viewModel.acknowledge(alert) } label: {
                        Text("확인")
                            .font(AppFont.captionBold)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 28)
                            .background(AppColor.danger)
                            .cornerRadius(AppRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 읽은 알림은 배경을 회색으로
        .background(viewModel.isRead(alert) ? AppColor.surfaceSubtle : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.divider, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { open(alert) }
    }

    private func badgeBackground(_ alert: MonitoringAlertDTO) -> Color {
        if viewModel.isGeneral(alert) { return AppColor.accentSubtle }
        return viewModel.isDangerous(alert) ? AppColor.dangerSubtle : AppColor.warningSubtle
    }

    private func badgeForeground(_ alert: MonitoringAlertDTO) -> Color {
        if viewModel.isGeneral(alert) { return AppColor.accent }
        return viewModel.isDangerous(alert) ? AppColor.danger : AppColor.warning
    }

    /// 유형별 딥링크 — 이탈은 위치 확인, 건강은 안전 관리로 돌아갑니다
    private func open(_ alert: MonitoringAlertDTO) {
        viewModel.markRead(alert)

        if alert.alertType == "location" {
            locationTargetName = alert.travelerName
            locationTargetId = viewModel.participantId(for: alert)
            showLocation = true
        } else {
            // 건강·일정 알림은 앞 화면(안전 관리·전체일정)으로 돌아가 확인합니다
            dismiss()
        }
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        SkeletonList(rows: 4, rowHeight: 76)
    }

    private var emptyView: some View {
        EmptyStateView(icon: "bell.slash", title: "알림이 없어요")
    }

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) { viewModel.load() }
    }
}
