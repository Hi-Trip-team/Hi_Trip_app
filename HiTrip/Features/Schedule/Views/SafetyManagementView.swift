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
        ZStack {
            Text("안전 관리")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))

            HStack {
                Button {
                    onDismiss?()
                    dismiss()
                } label: {
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

    // MARK: - 상태 요약 칩

    private var filterChips: some View {
        HStack(spacing: 8) {
            chip("전체 \(viewModel.totalCount)",
                 background: Color(hex: "#F3F4F6"), foreground: Color(hex: "#333840"),
                 isOn: viewModel.filter == nil) { viewModel.filter = nil }

            chip("경고 \(viewModel.warningCount)",
                 background: Color(hex: "#FFF2D9"), foreground: Color(hex: "#EB8C0D"),
                 isOn: viewModel.filter == .warning) { viewModel.toggle(.warning) }

            chip("위험 \(viewModel.dangerCount)",
                 background: Color(hex: "#FCE5E5"), foreground: Color(hex: "#EF4444"),
                 isOn: viewModel.filter == .danger) { viewModel.toggle(.danger) }

            chip("이탈 \(viewModel.escapedCount)",
                 background: Color(hex: "#FCE5E5"), foreground: Color(hex: "#EF4444"),
                 isOn: viewModel.filter == .escaped) { viewModel.toggle(.escaped) }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    private func chip(
        _ text: String, background: Color, foreground: Color,
        isOn: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(foreground)
                .frame(width: 64, height: 32)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isOn ? foreground : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var updatedRow: some View {
        HStack {
            Spacer()
            Text(viewModel.updatedText)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 표

    private var participantTable: some View {
        ScrollView {
            VStack(spacing: 0) {
                tableHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                ForEach(viewModel.sortedParticipants, id: \.participantId) { p in
                    participantRow(p)
                        .padding(.horizontal, 24)

                    Rectangle()
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                }

                legend
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .padding(.bottom, 32)
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
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(Color(hex: "#F3F4F6"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color(hex: "#6B7280"))
            .frame(width: width, alignment: .leading)
    }

    private func participantRow(_ p: ParticipantLatestDTO) -> some View {
        HStack(spacing: 0) {
            Text(p.travelerName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#2563EB"))
                .frame(width: 72, alignment: .leading)
                .lineLimit(1)

            Text(viewModel.profile(for: p)?.phone ?? "—")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 84, alignment: .leading)
                .lineLimit(1)

            // 이탈 거리 — 빨간 셀을 누르면 위치 확인으로 이동합니다
            Group {
                if let distance = viewModel.escapeDistanceText(p) {
                    Text(distance)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .background(Color(hex: "#FCE5E5"))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onTapGesture {
                            locationTarget = p
                            showLocation = true
                        }
                } else {
                    Text(p.locationStatus == .offline || p.locationStatus == .unknown ? "—" : "정상")
                        .font(.system(size: 12))
                        .foregroundColor(p.locationStatus == .offline || p.locationStatus == .unknown
                                         ? Color(hex: "#6B7280") : Color(hex: "#333840"))
                }
            }
            .frame(width: 74, alignment: .leading)

            metricCell(viewModel.heartRateText(p), level: viewModel.heartRateLevel(p), width: 64)
            metricCell(viewModel.spo2Text(p), level: viewModel.spo2Level(p), width: 44)
        }
        .padding(.horizontal, 8)
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
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#333840"))
            case .unknown:
                Text("—")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            case .warning, .danger:
                Text(text)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(level == .warning ? Color(hex: "#EB8C0D") : Color(hex: "#EF4444"))
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(level == .warning ? Color(hex: "#FFF2D9") : Color(hex: "#FCE5E5"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(width: width, alignment: .leading)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("경고(주황) · 위험(빨강) · — 데이터 수신 안 됨(워치 미연동·통신 두절)")
            Text("정렬: 위험 → 경고 → 정상 · 행 탭 시 관광객 정보 팝업")
        }
        .font(.system(size: 10))
        .foregroundColor(Color(hex: "#6B7280"))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("안전 정보를 불러오는 중이에요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        Text("등록된 관광객이 없습니다")
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

// MARK: - 관광객 정보 팝업
/// Figma 12381:4366 — 320×300 카드
///
/// 여권번호는 중간 3자리를 가리고, 👁을 누르면 3초만 보여줍니다.
/// 위치보기는 이탈이거나 건강 경고·위험일 때만 누를 수 있습니다 (프라이버시).

struct TouristInfoPopup: View {

    let participant: ParticipantLatestDTO
    let profile: TravelerDetailDTO?
    let statusLine: String
    let canViewLocation: Bool
    let isEscaped: Bool
    var onClose: () -> Void
    var onViewLocation: () -> Void

    @State private var showsFullPassport = false
    @State private var blockedNotice = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text(participant.travelerName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))

                if isEscaped {
                    Text("이탈")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 10)
                        .frame(height: 20)
                        .background(Color(hex: "#FCE5E5"))
                        .cornerRadius(4)
                        .padding(.top, 2)
                }

                Spacer()

                Button(action: onClose) {
                    Text("✕")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)

            infoRow("국가", profile?.country ?? "—")
                .padding(.top, 22)
            passportRow
                .padding(.top, 12)
            infoRow("전화번호", profile?.phone ?? "—")
                .padding(.top, 12)
            infoRow("상태", statusLine, valueColor: Color(hex: "#EF4444"))
                .padding(.top, 12)

            HStack(spacing: 12) {
                Button { call() } label: {
                    Text("전화걸기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(hasPhone ? Color(hex: "#333840") : Color(hex: "#9CA3AF"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!hasPhone)

                Button {
                    if canViewLocation { onViewLocation() } else { blockedNotice = true }
                } label: {
                    Text("위치보기")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canViewLocation ? Color(hex: "#2563EB") : Color(hex: "#C3CDDA"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)

            if !hasPhone {
                Text("연락처가 등록되지 않았어요")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.top, 8)
            } else if blockedNotice {
                Text("위험 상태의 관광객만 위치를 볼 수 있어요")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        // Figma 320x300 카드
        .frame(width: 320, height: 300, alignment: .top)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(_ label: String, _ value: String, valueColor: Color = Color(hex: "#111827")) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 66, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(valueColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 여권번호 — 기본 마스킹, 👁 탭 시 3초만 공개
    private var passportRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("여권번호")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 66, alignment: .leading)

            Text(hasPassport
                 ? (showsFullPassport ? (profile?.passportNumber ?? "") : (profile?.maskedPassport ?? ""))
                 : "—")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))

            // 여권번호가 비어 있으면 눈 아이콘도 숨깁니다 (서버에 값이 없을 수 있습니다)
            if hasPassport {
                Button { revealPassport() } label: {
                    Text("👁")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
        }
    }

    private func revealPassport() {
        showsFullPassport = true
        // 3초 뒤 자동으로 다시 가립니다 (개인정보 열람 최소화)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showsFullPassport = false }
    }

    private var hasPassport: Bool {
        guard let passport = profile?.passportNumber else { return false }
        return !passport.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var hasPhone: Bool {
        guard let phone = profile?.phone else { return false }
        return !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func call() {
        guard let phone = profile?.phone else { return }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
