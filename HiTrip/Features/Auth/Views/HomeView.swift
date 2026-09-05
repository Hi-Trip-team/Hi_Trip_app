import SwiftUI

// MARK: - HomeView
/// 로그인 후 진입점 — 탭바 없이 userType 기반 분기
///
/// - tourist: TripListView (전체 일정)
/// - staff/guide: StaffDashboardView (전체 일정)

struct HomeView: View {

    @EnvironmentObject var router: AppRouter

    var body: some View {
        if router.userType == .tourist {
            TripListView()
        } else {
            StaffDashboardView()
        }
    }
}
