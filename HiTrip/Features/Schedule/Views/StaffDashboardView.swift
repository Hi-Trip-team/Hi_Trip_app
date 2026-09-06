import SwiftUI

// MARK: - StaffDashboardView
/// 안내사 홈 — Figma 12381:5370
///
/// 여행명·안내사명 / 오늘의 일정(진행바 + 현재·다음 일정) /
/// 퀵 메뉴 2×2 / 오늘의 안전 현황
///
/// 안전 현황은 30초마다 갱신합니다 (화면이 보이는 동안만).

struct StaffDashboardView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = StaffHomeViewModel()

    @State private var showMapRange = false
    @State private var showSafety = false
    @State private var showChat = false
    @State private var showNotification = false
    @State private var showFullSchedule = false
    @State private var showNotice = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case .noTrip:
                    noTripView
                case .failed(let message):
                    errorView(message)
                case .loaded:
                    content
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .task { viewModel.load() }
            .onAppear { viewModel.startPolling() }
            .onDisappear { viewModel.stopPolling() }
            .navigationDestination(isPresented: $showMapRange) { MapRangeSettingView() }
            .navigationDestination(isPresented: $showSafety) {
                SafetyManagementView(onDismiss: { showSafety = false })
            }
            .navigationDestination(isPresented: $showChat) { StaffChatListView() }
            .navigationDestination(isPresented: $showNotification) { NotificationCenterView() }
            .navigationDestination(isPresented: $showFullSchedule) { StaffTripDetailView() }
            .navigationDestination(isPresented: $showNotice) { NoticeSettingView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                todayScheduleSection

                Button { showFullSchedule = true } label: {
                    Text("전체일정 확인 및 일정 수정하기  >")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 18)

                quickMenuGrid
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)

                safetyStatusCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .refreshable { viewModel.refreshSafety() }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.tripTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                Text(viewModel.managerText)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            Spacer()

            // 알림 센터 — 안전 경고·위험·이탈의 단일 수신 창구
            Button { showNotification = true } label: {
                ZStack(alignment: .topTrailing) {
                    Text("🔔")
                        .font(.system(size: 18))
                        .padding(.top, 6)

                    if viewModel.unreadAlertCount > 0 {
                        Text("\(min(viewModel.unreadAlertCount, 99))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color(hex: "#EF4444"))
                            .clipShape(Circle())
                            .offset(x: 8, y: 0)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    // MARK: - 오늘의 일정

    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("오늘의 일정")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.horizontal, 24)

            // 진행바 + 버스 — 관광객 홈과 같은 규칙(당일 시각 비율)
            GeometryReader { geo in
                let filled = geo.size.width * viewModel.todayProgress
                VStack(alignment: .leading, spacing: 2) {
                    Text("🚌")
                        .font(.system(size: 16))
                        .offset(x: max(filled - 8, 0))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "#E5E7EB"))
                            .frame(height: 4)
                        Capsule()
                            .fill(Color(hex: "#2563EB"))
                            .frame(width: filled, height: 4)
                    }
                }
            }
            .frame(height: 40)
            .padding(.horizontal, 24)
            .padding(.top, 4)

            if let current = viewModel.currentSchedule {
                scheduleRow(current, height: 56, titleSize: 14)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            } else {
                Text(viewModel.todaySchedules.isEmpty
                     ? "오늘은 등록된 일정이 없어요"
                     : "오늘 일정이 모두 끝났어요")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }

            if let next = viewModel.nextSchedule {
                scheduleRow(next, height: 48, titleSize: 13)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
        }
    }

    private func scheduleRow(_ item: StaffScheduleDTO, height: CGFloat, titleSize: CGFloat) -> some View {
        HStack {
            Text(item.placeName)
                .font(.system(size: titleSize, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Spacer()
            Text(StaffHomeViewModel.timeRange(item.startTime, item.endTime))
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { showFullSchedule = true }
    }

    // MARK: - 퀵 메뉴 2×2

    private var quickMenuGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                menuCard("📢", "공지글 설정") { showNotice = true }
                menuCard("💬", "고객 관리", badge: viewModel.unreadMessageCount > 0
                         ? viewModel.unreadMessageBadgeText : nil) { showChat = true }
            }
            HStack(spacing: 12) {
                menuCard("📍", "지도 범위 설정") { showMapRange = true }
                menuCard("🛡", "안전 관리", showsDot: viewModel.hasSafetyIssue) { showSafety = true }
            }
        }
    }

    private func menuCard(
        _ emoji: String,
        _ title: String,
        badge: String? = nil,
        showsDot: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(emoji)
                        .font(.system(size: 24))
                    Spacer(minLength: 0)
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#111827"))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 106)
                .background(Color(hex: "#F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Color(hex: "#EF4444"))
                        .clipShape(Capsule())
                        .padding(10)
                } else if showsDot {
                    // 경고·위험 인원이 있으면 빨간 점
                    Circle()
                        .fill(Color(hex: "#EF4444"))
                        .frame(width: 8, height: 8)
                        .padding(14)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 오늘의 안전 현황

    private var safetyStatusCard: some View {
        Button { showSafety = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("오늘의 안전 현황")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#2563EB"))
                    .padding(.top, 14)

                Text(viewModel.safetySummaryText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.top, 14)

                Text("안전 관리에서 자세히 보기  >")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.top, 10)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 90, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#E8F0FF"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("여행 정보를 불러오는 중이에요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 배정된 여행이 없을 때
    private var noTripView: some View {
        VStack(spacing: 10) {
            Text("🧭").font(.system(size: 34))
            Text("배정된 여행이 없습니다")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            Text("SaaS에서 확인해주세요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text("🧭").font(.system(size: 34))
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
                .multilineTextAlignment(.center)
            Button { viewModel.load() } label: {
                Text("다시 시도")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
