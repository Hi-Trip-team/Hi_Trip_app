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
                        .font(AppFont.labelMedium)
                        .foregroundColor(AppColor.accent)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, 18)

                quickMenuGrid
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, 28)

                safetyStatusCard
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxl)
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

    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("오늘의 일정")
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.xl)

            // 진행바 + 버스 — 관광객 홈과 같은 규칙(당일 시각 비율)
            GeometryReader { geo in
                let filled = geo.size.width * viewModel.todayProgress
                VStack(alignment: .leading, spacing: 2) {
                    Text("🚌")
                        .font(AppFont.bodyL)
                        .offset(x: max(filled - 8, 0))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColor.divider)
                            .frame(height: 4)
                        Capsule()
                            .fill(AppColor.accent)
                            .frame(width: filled, height: 4)
                    }
                }
            }
            .frame(height: 40)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxs)

            if let current = viewModel.currentSchedule {
                scheduleRow(current, height: 56, titleSize: 14)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xxs)
            } else {
                Text(viewModel.todaySchedules.isEmpty
                     ? "오늘은 등록된 일정이 없어요"
                     : "오늘 일정이 모두 끝났어요")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.lg)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xxs)
            }

            if let next = viewModel.nextSchedule {
                scheduleRow(next, height: 48, titleSize: 13)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }

    private func scheduleRow(_ item: StaffScheduleDTO, height: CGFloat, titleSize: CGFloat) -> some View {
        HStack {
            // 장소가 없는 일정(앱에서 추가한 것)은 메모를 제목으로 씁니다
            Text(item.placeName?.isEmpty == false ? (item.placeName ?? "") : (item.mainContent ?? "일정"))
                .font(.pretendard(.medium, size: titleSize))
                .foregroundColor(AppColor.textPrimary)
            Spacer()
            Text(StaffHomeViewModel.timeRange(item.startTime, item.endTime))
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: height)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.lg)
        .contentShape(Rectangle())
        .onTapGesture { showFullSchedule = true }
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

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 90, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.accentSubtle)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text("여행 정보를 불러오는 중이에요")
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        VStack(spacing: 14) {
            Text("🧭").font(AppFont.emojiXL)
            Text(message)
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Button { viewModel.load() } label: {
                Text("다시 시도")
                    .font(AppFont.bodyBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .frame(height: 44)
                    .background(AppColor.accent)
                    .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
