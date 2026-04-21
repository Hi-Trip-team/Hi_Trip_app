import SwiftUI

// MARK: - HomeView
/// 메인 홈 화면 — 5탭 네비게이션 구조
///
/// 탭 구성:
/// - 홈: TripListView (주간 캘린더 + 내 일정 카드 + 긴급 연락 바로가기)
/// - 캘린더: ScheduleTabView (할일/캘린더 탭 — TripDetailView 래퍼)
/// - 검색: SpotListView (TourAPI 관광지 검색)
/// - 메시지: ChatListView (1:1 메시지)
/// - 마이페이지: ProfileView (프로필 조회 + 로그아웃)
///
/// 긴급 연락은 홈 화면에서 바로가기로 접근 가능

struct HomeView: View {

    @EnvironmentObject var router: AppRouter
    @State private var selectedTab: Tab = .home

    // MARK: - Tab Definition

    enum Tab: String, CaseIterable {
        case home      = "홈"
        case calendar  = "캘린더"
        case search    = "검색"
        case message   = "메시지"
        case mypage    = "마이페이지"

        var icon: String {
            switch self {
            case .home:     return "house.fill"
            case .calendar: return "calendar"
            case .search:   return "magnifyingglass"
            case .message:  return "bubble.left.and.bubble.right"
            case .mypage:   return "person.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            TripListView()
                .tabItem { Label(Tab.home.rawValue, systemImage: Tab.home.icon) }
                .tag(Tab.home)

            ScheduleTabView()
                .tabItem { Label(Tab.calendar.rawValue, systemImage: Tab.calendar.icon) }
                .tag(Tab.calendar)

            SpotListView(
                    viewModel: AppDIContainer.shared.makeSpotViewModel()
                )
                .tabItem { Label(Tab.search.rawValue, systemImage: Tab.search.icon) }
                .tag(Tab.search)

            ChatListView(
                    viewModel: AppDIContainer.shared.makeChatViewModel()
                )
                .tabItem { Label(Tab.message.rawValue, systemImage: Tab.message.icon) }
                .tag(Tab.message)

            ProfileView()
                .tabItem { Label(Tab.mypage.rawValue, systemImage: Tab.mypage.icon) }
                .tag(Tab.mypage)
        }
        .tint(HiTripColor.primary800)
    }
}
