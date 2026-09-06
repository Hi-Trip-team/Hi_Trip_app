import SwiftUI

struct StaffDashboardView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = TripListViewModel()

    @State private var isInteractive = false
    @State private var showMapRange = false
    @State private var showSafety = false
    @State private var showTouristLocation = false
    @State private var showChat = false
    @State private var showNotification = false
    @State private var showFullSchedule = false
    @State private var showNotice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    headerSection

                    // 오늘의 일정
                    todayScheduleSection

                    // 전체일정 링크
                    Button { showFullSchedule = true } label: {
                        Text("전체일정 확인 및 일정 수정하기  >")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#2563EB"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 22)

                    // 퀵 메뉴 그리드
                    quickMenuGrid
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                        .disabled(!isInteractive)

                    // 안전 현황 카드
                    safetyStatusCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .disabled(!isInteractive)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { isInteractive = true }
            }
            .navigationDestination(isPresented: $showMapRange) { MapRangeSettingView() }
            .navigationDestination(isPresented: $showSafety) {
                SafetyManagementView(onDismiss: { showSafety = false })
            }
            .navigationDestination(isPresented: $showTouristLocation) { TouristLocationView() }
            .navigationDestination(isPresented: $showChat) {
                StaffChatListView()
            }
            .navigationDestination(isPresented: $showNotification) { NotificationCenterView() }
            .navigationDestination(isPresented: $showFullSchedule) { StaffTripDetailView() }
            .navigationDestination(isPresented: $showNotice) { NoticeSettingView() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("뉴진스 바다여행")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                Text("안내사 김안내")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            Spacer()
            ZStack(alignment: .topTrailing) {
                Text("🔔")
                    .font(.system(size: 18))
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                    Text("2")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 6, y: -4)
            }
            .onTapGesture { showNotification = true }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - 오늘의 일정

    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘의 일정")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.horizontal, 24)

            // 진행률 바
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer().frame(width: 137)
                    Text("🚌")
                        .font(.system(size: 16))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#2563EB"))
                        .frame(width: 137, height: 4)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 10)

            // 일정 아이템들
            VStack(spacing: 8) {
                scheduleItem(title: "숙소로 이동", time: "15:00 - 16:00", height: 56)
                scheduleItem(title: "자유시간", time: "16:00 - 23:00", height: 48)
            }
            .padding(.horizontal, 24)
        }
    }

    private func scheduleItem(title: String, time: String, height: CGFloat) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Spacer()
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
    }

    // MARK: - 퀵 메뉴 그리드

    private var quickMenuGrid: some View {
        HStack(spacing: 12) {
            VStack(spacing: 12) {
                quickMenuCard(emoji: "📢", title: "공지글 설정") { showNotice = true }
                quickMenuCard(emoji: "📍", title: "지도 범위 설정") { showMapRange = true }
            }
            VStack(spacing: 12) {
                quickMenuCard(emoji: "💬", title: "고객 관리") { showChat = true }
                quickMenuCard(emoji: "🛡️", title: "안전 관리") { showSafety = true }
            }
        }
    }

    private func quickMenuCard(emoji: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(emoji)
                    .font(.system(size: 24))
                    .padding(.bottom, 18)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(height: 106)
            .background(Color(hex: "#F3F4F6"))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 안전 현황 카드

    private var safetyStatusCard: some View {
        Button { showSafety = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("오늘의 안전 현황")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#2563EB"))
                Text("전체 12명 · 경고 2 · 위험 1 · 이탈 1")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                Text("안전 관리에서 자세히 보기  >")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(Color(hex: "#E8F0FF"))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
