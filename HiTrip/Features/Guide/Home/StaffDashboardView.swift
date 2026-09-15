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
    /// 전체 일정에서 처음 펼칠 일차 — nil이면 오늘
    @State private var fullScheduleFocusDay: Int?
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
            .navigationDestination(isPresented: $showChat) { StaffChatListView(currentTripId: viewModel.trip?.id) }
            .navigationDestination(isPresented: $showNotification) { NotificationCenterView() }
            .navigationDestination(isPresented: $showFullSchedule) { StaffTripDetailView(focusDay: fullScheduleFocusDay) }
            .navigationDestination(isPresented: $showNotice) { NoticeSettingView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                todayScheduleSection
                    .padding(.bottom, AppSpacing.xs)

                quickMenuGrid
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, 28)

                safetyStatusCard
                    .padding(.horizontal, AppSpacing.xl)

                LogoutButton()
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xs)
            }
        }
        .refreshable { viewModel.refreshSafety() }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(viewModel.tripTitle)
                    .font(AppFont.headlineBold)
                    .foregroundColor(.black)
                Text(viewModel.managerText)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            // 알림 센터 — 안전 경고·위험·이탈의 단일 수신 창구
            Button { showNotification = true } label: {
                ZStack(alignment: .topTrailing) {
                    Text("🔔")
                        .font(AppFont.title3)
                        .padding(.top, 6)

                    if viewModel.unreadAlertCount > 0 {
                        Text("\(min(viewModel.unreadAlertCount, 99))")
                            .font(AppFont.caption2Bold)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(AppColor.danger)
                            .clipShape(Circle())
                            .offset(x: 8, y: 0)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, 10)
        .padding(.bottom, AppSpacing.xl)
    }

    // MARK: - 오늘의 일정

    /// 여행객 홈과 같은 공통 부품 — 일정을 누르면 그 일차, 링크는 오늘 일차를 펼칩니다
    private var todayScheduleSection: some View {
        TodayScheduleSection(
            phaseMessage: viewModel.phaseMessage,
            current: viewModel.currentItem,
            noCurrentText: viewModel.noCurrentScheduleText,
            next: viewModel.nextItem,
            linkTitle: "전체일정 확인 및 일정 수정하기  >",
            onOpenDay: { day in
                fullScheduleFocusDay = day
                showFullSchedule = true
            }
        ) {
            TripProgressCard(
                progress: viewModel.tripProgress,
                remainingDays: viewModel.remainingDays,
                destination: viewModel.destinationText
            )
        }
    }

    // MARK: - 퀵 메뉴 2×2

    private var quickMenuGrid: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                menuCard("📢", "공지글 설정") { showNotice = true }
                menuCard("💬", "고객 관리", badge: viewModel.unreadMessageCount > 0
                         ? viewModel.unreadMessageBadgeText : nil) { showChat = true }
            }
            HStack(spacing: AppSpacing.sm) {
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
                        .font(AppFont.title0)
                    Spacer(minLength: 0)
                    Text(title)
                        .font(AppFont.bodyBold)
                        .foregroundColor(AppColor.textPrimary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 106)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if let badge {
                    Text(badge)
                        .font(AppFont.caption2Bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(AppColor.danger)
                        .clipShape(Capsule())
                        .padding(10)
                } else if showsDot {
                    // 경고·위험 인원이 있으면 빨간 점
                    Circle()
                        .fill(AppColor.danger)
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
                    .font(AppFont.labelBold)
                    .foregroundColor(AppColor.accent)
                    .padding(.top, 14)

                Text(viewModel.safetySummaryText)
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.top, 14)

                Text("안전 관리에서 자세히 보기  >")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.top, 10)
            }
            // 고정 높이 대신 위아래 같은 여백 — 마지막 줄 아래가 좁아 보이던 문제
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.accentSubtle)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        GuideHomeSkeleton()
    }

    /// 배정된 여행이 없을 때
    private var noTripView: some View {
        VStack(spacing: 10) {
            Text("🧭").font(AppFont.emojiXL)
            Text("배정된 여행이 없습니다")
                .font(AppFont.bodyMBold)
                .foregroundColor(AppColor.textPrimary)
            Text("SaaS에서 확인해주세요")
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) { viewModel.load() }
    }
}
