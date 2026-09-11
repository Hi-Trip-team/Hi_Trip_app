import SwiftUI

// MARK: - HomeView
/// 로그인 후 진입점 — 탭바 없이 userType 기반 분기
///
/// - tourist: TripListView (전체 일정)
/// - staff/guide: StaffDashboardView (전체 일정)
///
/// 두 홈 모두 위치 권한이 거부돼 있으면 상단에 "안전 서비스 제한 중" 배너를 띄웁니다.

struct HomeView: View {

    @EnvironmentObject var router: AppRouter

    var body: some View {
        VStack(spacing: 0) {
            SafetyRestrictionBanner()

            if router.userType == .tourist {
                TripListView()
            } else {
                StaffDashboardView()
            }
        }
        .task {
            // "한 번 허용"을 골랐던 경우 다음 실행에서 다시 물어봅니다.
            let permissions = PermissionCoordinator.shared
            if permissions.isLocationUndetermined {
                _ = await permissions.requestLocation()
            }
        }
    }
}
