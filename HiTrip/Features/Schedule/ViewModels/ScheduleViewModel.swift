import Foundation
import Combine

// MARK: - ScheduleViewModel
/// 서버 공식 일정 화면 ViewModel
///
/// 데이터 흐름:
///   TravelerRepository → TripDataStore.officialSchedules → ScheduleViewModel → ScheduleListView
///
/// 여행객 앱에서 일정은 서버에서 내려오는 읽기 전용 데이터입니다.
/// 직접 로컬 CRUD를 하지 않고 TripDataStore를 관찰합니다.

final class ScheduleViewModel: ObservableObject {

    // MARK: - Published

    @Published var schedulesByDay: [Int: [TripOfficialSchedule]] = [:]
    @Published var selectedDayNumber: Int = 1
    @Published var isLoading: Bool = false

    // MARK: - Computed

    var sortedDayNumbers: [Int] {
        schedulesByDay.keys.sorted()
    }

    var schedulesForSelectedDay: [TripOfficialSchedule] {
        (schedulesByDay[selectedDayNumber] ?? []).sorted { $0.startTime < $1.startTime }
    }

    var totalDays: Int {
        schedulesByDay.keys.max() ?? 1
    }

    var isEmpty: Bool {
        schedulesByDay.isEmpty
    }

    // MARK: - Dependencies

    private let store = TripDataStore.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        store.$currentPackage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        store.$isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$isLoading)

        refresh()

        // 오늘 일차로 초기 선택
        selectedDayNumber = store.currentPackage?.currentDay() ?? 1
    }

    // MARK: - Refresh

    func refresh() {
        let byDay = store.officialSchedulesByDay()
        schedulesByDay = byDay
        if !byDay.isEmpty && !byDay.keys.contains(selectedDayNumber) {
            selectedDayNumber = byDay.keys.sorted().first ?? 1
        }
    }

    // MARK: - Helpers

    func dayLabel(_ dayNumber: Int) -> String { "\(dayNumber)일차" }

    func scheduleTimeRange(_ schedule: TripOfficialSchedule) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "\(fmt.string(from: schedule.startTime)) ~ \(fmt.string(from: schedule.endTime))"
    }
}
