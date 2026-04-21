import SwiftUI

// MARK: - ScheduleTabView
/// 하단 탭바에서 "일정" 탭을 눌렀을 때 바로 보여주는 래퍼 뷰
///
/// TripDetailView는 Trip 파라미터가 필수이므로,
/// TripDataStore에서 첫 번째 여행을 자동으로 선택하여 표시한다.
/// 여행이 없으면 빈 상태 안내를 보여준다.

struct ScheduleTabView: View {

    @ObservedObject private var store = TripDataStore.shared

    /// Store의 첫 번째 여행 (정렬 기준: 날짜순)
    private var firstTrip: Trip? {
        store.sortedTrips.first
    }

    var body: some View {
        NavigationStack {
            if let trip = firstTrip {
                TripDetailView(trip: trip)
            } else {
                emptyState
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(HiTripColor.gray300)

            Text("등록된 일정이 없습니다")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Text("여행 일정을 추가해보세요!")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)

            Spacer()
        }
        .navigationTitle("일정")
        .navigationBarTitleDisplayMode(.inline)
    }
}
