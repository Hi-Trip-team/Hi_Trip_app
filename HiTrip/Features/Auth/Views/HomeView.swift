import SwiftUI

// MARK: - HomeView
/// 메인 홈 화면 — 5탭 네비게이션 구조
///
/// 탭 구성:
/// - 홈: 로그인 성공 확인 + 로그아웃
/// - 일정: ScheduleListView (CRUD)
/// - 채팅: ChatListView (1:1 메시지)
/// - 스팟 추천: Phase 4에서 구현
/// - 긴급 연락: EmergencyView (긴급 전화 + 연락처 관리)
/// - 프로필: ProfileView (프로필 조회 + 로그아웃)
///
/// Phase 1에서는 탭 구조만 잡고,
/// 각 탭의 실제 콘텐츠는 해당 Phase 커밋에서 교체

struct HomeView: View {

    @EnvironmentObject var router: AppRouter
    @State private var selectedTab: Tab = .home

    // MARK: - Tab Definition

    enum Tab: String, CaseIterable {
        case home      = "홈"
        case schedule  = "일정"
        case chat      = "채팅"
        case spots     = "스팟 추천"
        case emergency = "긴급 연락"
        case profile   = "프로필"

        var icon: String {
            switch self {
            case .home:      return "house.fill"
            case .schedule:  return "calendar"
            case .chat:      return "bubble.left.and.bubble.right"
            case .spots:     return "map.fill"
            case .emergency: return "exclamationmark.triangle.fill"
            case .profile:   return "person.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label(Tab.home.rawValue, systemImage: Tab.home.icon) }
                .tag(Tab.home)

            ScheduleListView(
                    viewModel: AppDIContainer.shared.makeScheduleViewModel()
                )
                .tabItem { Label(Tab.schedule.rawValue, systemImage: Tab.schedule.icon) }
                .tag(Tab.schedule)

            ChatListView(
                    viewModel: AppDIContainer.shared.makeChatViewModel()
                )
                .tabItem { Label(Tab.chat.rawValue, systemImage: Tab.chat.icon) }
                .tag(Tab.chat)

            placeholderTab("스팟 추천", icon: "map.fill", phase: 4)
                .tabItem { Label(Tab.spots.rawValue, systemImage: Tab.spots.icon) }
                .tag(Tab.spots)

            EmergencyView(
                    viewModel: AppDIContainer.shared.makeEmergencyViewModel()
                )
                .tabItem { Label(Tab.emergency.rawValue, systemImage: Tab.emergency.icon) }
                .tag(Tab.emergency)

            ProfileView()
                .tabItem { Label(Tab.profile.rawValue, systemImage: Tab.profile.icon) }
                .tag(Tab.profile)
        }
        .tint(HiTripColor.primary800)
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Hi Trip")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(HiTripColor.logoText)

                Text("로그인 성공!")
                    .font(.system(size: 18))
                    .foregroundColor(HiTripColor.gray500)

                // 사용자 타입 배지 (안내사/관광객)
                if let userType = KeychainManager.shared.getUserType() {
                    Label(
                        userType == "guide" ? "안내사" : "관광객",
                        systemImage: userType == "guide"
                            ? "person.badge.shield.checkmark"
                            : "person"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.primary800)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(HiTripColor.secondary100)
                    .cornerRadius(8)
                }

                Spacer()

                // 로그아웃 버튼
                Button {
                    KeychainManager.shared.clearAll()
                    router.navigateToLogin()
                } label: {
                    Text("로그아웃")
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.error)
                }
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Placeholder Tab

    /// Phase 2+ 에서 실제 View로 교체될 임시 탭
    private func placeholderTab(
        _ title: String,
        icon: String,
        phase: Int
    ) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(HiTripColor.gray300)
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(HiTripColor.textGrayA)
                Text("Phase \(phase)에서 구현 예정")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray400)
                Spacer()
            }
        }
    }
}
