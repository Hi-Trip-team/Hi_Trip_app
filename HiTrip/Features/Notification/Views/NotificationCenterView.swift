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
            TouristLocationView(touristName: locationTargetName ?? "")
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        ZStack {
            Text("알림")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
            .padding(.leading, 12)
        }
        .frame(height: 24)
        .padding(.top, 8)
    }

    // MARK: - 필터 칩

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(AlertCenterViewModel.Kind.allCases) { kind in
                let isOn = viewModel.kind == kind
                Button { viewModel.kind = kind } label: {
                    Text(kind.label)
                        .font(.system(size: 12, weight: isOn ? .bold : .medium))
                        .foregroundColor(isOn ? .white : Color(hex: "#6B7280"))
                        .frame(width: kind == .all ? 64 : 56, height: 32)
                        .background(isOn ? Color(hex: "#2563EB") : Color(hex: "#F3F4F6"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 목록

    private var alertList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filtered, id: \.id) { alert in
                    alertCard(alert)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .refreshable { viewModel.refresh() }
    }

    private func alertCard(_ alert: MonitoringAlertDTO) -> some View {
        let needsAck = viewModel.needsAcknowledge(alert)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(viewModel.badgeText(alert))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(badgeForeground(alert))
                    .frame(width: 44, height: 22)
                    .background(badgeBackground(alert))
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.messageText(alert))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#111827"))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.metaText(alert))
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .padding(.top, 8)

                    if needsAck {
                        Text("[확인] 전까지 5분 주기 재알림")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "#EF4444"))
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 28)
                            .background(Color(hex: "#EF4444"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 읽은 알림은 배경을 회색으로
        .background(viewModel.isRead(alert) ? Color(hex: "#F9FAFB") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { open(alert) }
    }

    private func badgeBackground(_ alert: MonitoringAlertDTO) -> Color {
        if viewModel.isGeneral(alert) { return Color(hex: "#E8F0FF") }
        return viewModel.isDangerous(alert) ? Color(hex: "#FCE5E5") : Color(hex: "#FFF2D9")
    }

    private func badgeForeground(_ alert: MonitoringAlertDTO) -> Color {
        if viewModel.isGeneral(alert) { return Color(hex: "#2563EB") }
        return viewModel.isDangerous(alert) ? Color(hex: "#EF4444") : Color(hex: "#EB8C0D")
    }

    /// 유형별 딥링크 — 이탈은 위치 확인, 건강은 안전 관리로 돌아갑니다
    private func open(_ alert: MonitoringAlertDTO) {
        viewModel.markRead(alert)

        if alert.alertType == "location" {
            locationTargetName = alert.travelerName
            showLocation = true
        } else {
            // 건강·일정 알림은 앞 화면(안전 관리·전체일정)으로 돌아가 확인합니다
            dismiss()
        }
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("알림을 불러오는 중이에요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        Text("알림이 없어요")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "#6B7280"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Button { viewModel.load() } label: {
                Text("재시도")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
