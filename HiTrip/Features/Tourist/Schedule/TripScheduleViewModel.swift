import Foundation
import RxSwift

// MARK: - TripScheduleViewModel
/// 전체일정 화면 — 공용 일정 + 개인 일정
///
/// - GET  /api/v1/tourist/home/                여행 정보 + 서버가 계산한 오늘 일정
/// - GET  /api/v1/tourist/schedules/           여행사 공용 일정 전체
/// - GET  /api/v1/tourist/personal-schedules/  내가 추가한 일정
/// - POST /api/v1/tourist/personal-schedules/  개인 일정 추가
///
/// 판정은 서버 값을 그대로 씁니다. 앱에서 다시 계산하지 않습니다.
/// - 오늘이 몇 일차인지        → home.today_day_number
/// - 오늘 일정                → home.today_schedules
/// - 공용 일정과의 시간 겹침    → personal_schedule.overlap_warning

@MainActor
final class TripScheduleViewModel: ObservableObject {

    /// 하루치 일정 — 공용/개인을 시간순으로 합쳐서 보여줍니다.
    struct DaySection: Identifiable {
        let id: Int              // dayNumber
        let dayNumber: Int
        let date: String         // "yyyy-MM-dd"
        let items: [ScheduleItem]
    }

    enum ScheduleItem: Identifiable {
        case shared(TravelerScheduleDTO)
        case personal(TravelerPersonalScheduleDTO)

        var id: String {
            switch self {
            case .shared(let s):   return "s\(s.id)"
            case .personal(let p): return "p\(p.id)"
            }
        }
        var startTime: String {
            switch self {
            case .shared(let s):   return s.startTime
            case .personal(let p): return p.startTime
            }
        }
    }

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    /// 홈 요약 — 여행 정보와 서버가 계산한 오늘 일정이 함께 들어 있습니다.
    @Published private(set) var home: TravelerHomeDTO?
    @Published private(set) var days: [DaySection] = []
    @Published var expandedDay: Int?

    /// 개인 일정 저장 중
    @Published private(set) var isSaving = false
    /// 저장 실패 메시지 — 표시 후 nil로 되돌립니다.
    @Published var saveError: String?
    /// 방금 저장한 일정이 공용 일정과 겹쳤을 때 안내
    @Published var overlapNotice: String?

    /// 저장 성공 토스트 문구
    @Published var toast: String?

    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()

    private var shared: [TravelerScheduleDTO] = []
    private var personal: [TravelerPersonalScheduleDTO] = []

    init(repository: TravelerRepositoryProtocol = AppDIContainer.shared.travelerRepositoryForHome) {
        self.repository = repository
    }

    // MARK: - Load

    func load() {
        guard state != .loading else { return }
        state = .loading

        // 여행 정보와 "오늘"은 홈 응답에 함께 들어 있어 trip을 따로 부르지 않습니다.
        Single.zip(
            repository.fetchHome(),
            repository.fetchSchedules(),
            repository.fetchPersonalSchedules()
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] home, schedules, personals in
                guard let self else { return }
                self.home = home
                self.shared = schedules
                self.personal = personals
                self.rebuild()
                self.state = .loaded
            },
            onFailure: { [weak self] error in
                self?.state = .failed(Self.message(for: error))
            }
        )
        .disposed(by: disposeBag)
    }

    /// 공용·개인을 일차별로 묶고 시작 시간순 정렬
    private func rebuild() {
        var byDay: [Int: [ScheduleItem]] = [:]
        var dateByDay: [Int: String] = [:]

        for s in shared {
            byDay[s.dayNumber, default: []].append(.shared(s))
            if let d = s.scheduleDate { dateByDay[s.dayNumber] = d }
        }
        for p in personal {
            byDay[p.dayNumber, default: []].append(.personal(p))
            dateByDay[p.dayNumber] = dateByDay[p.dayNumber] ?? p.scheduleDate
        }

        days = byDay.keys.sorted().map { day in
            DaySection(
                id: day,
                dayNumber: day,
                date: dateByDay[day] ?? "",
                items: (byDay[day] ?? []).sorted { $0.startTime < $1.startTime }
            )
        }

        // 처음 열 때는 오늘 일차를, 없으면 첫 일차를 펼칩니다.
        if expandedDay == nil {
            expandedDay = todayDayNumber ?? days.first?.dayNumber
        }
    }

    // MARK: - 개인 일정 추가

    /// - Parameters:
    ///   - start/end: "HH:mm" 형식
    func addPersonalSchedule(
        dayNumber: Int,
        title: String,
        start: String,
        end: String,
        memo: String?,
        onSuccess: @escaping () -> Void
    ) {
        guard let date = days.first(where: { $0.dayNumber == dayNumber })?.date, !date.isEmpty else {
            saveError = "일정을 추가할 날짜를 찾지 못했습니다"
            return
        }
        isSaving = true

        let request = TravelerPersonalScheduleRequest(
            dayNumber: dayNumber,
            scheduleDate: date,
            title: title,
            startTime: Self.withSeconds(start),
            endTime: Self.withSeconds(end),
            memo: memo
        )

        repository.createPersonalSchedule(request)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] created in
                    guard let self else { return }
                    self.isSaving = false
                    self.personal.append(created)
                    self.rebuild()
                    self.expandedDay = dayNumber
                    self.toast = "일정이 추가되었어요"
                    onSuccess()
                },
                onFailure: { [weak self] error in
                    // 실패하면 시트를 닫지 않습니다. 입력값을 그대로 두고 재시도할 수 있어야 합니다.
                    self?.isSaving = false
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    /// 개인 일정 수정 — 스와이프 > 수정
    func updatePersonalSchedule(
        id: Int,
        dayNumber: Int,
        title: String,
        start: String,
        end: String,
        memo: String?,
        onSuccess: @escaping () -> Void
    ) {
        guard let date = days.first(where: { $0.dayNumber == dayNumber })?.date, !date.isEmpty else {
            saveError = "일정을 수정할 날짜를 찾지 못했습니다"
            return
        }
        isSaving = true

        let request = TravelerPersonalScheduleRequest(
            dayNumber: dayNumber,
            scheduleDate: date,
            title: title,
            startTime: Self.withSeconds(start),
            endTime: Self.withSeconds(end),
            memo: memo
        )

        repository.updatePersonalSchedule(id: id, request)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] updated in
                    guard let self else { return }
                    self.isSaving = false
                    if let idx = self.personal.firstIndex(where: { $0.id == id }) {
                        self.personal[idx] = updated
                    }
                    self.rebuild()
                    self.toast = "일정이 수정되었어요"
                    onSuccess()
                },
                onFailure: { [weak self] error in
                    self?.isSaving = false
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    /// 입력 중 겹침 경고 — 저장 전에 공용 일정과 시간이 겹치는지 미리 봅니다.
    /// 서버도 저장 시 overlap_warning을 돌려주지만, 기획상 경고는 입력 중에 떠야 합니다.
    func overlapsSharedSchedule(dayNumber: Int, start: String, end: String) -> Bool {
        guard let s = AppDate.minutes(start), let e = AppDate.minutes(end), s < e else { return false }
        return shared
            .filter { $0.dayNumber == dayNumber }
            .contains { item in
                guard let ss = AppDate.minutes(item.startTime), let se = AppDate.minutes(item.endTime) else { return false }
                return s < se && ss < e
            }
    }

    func deletePersonalSchedule(id: Int) {
        repository.deletePersonalSchedule(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    guard let self else { return }
                    self.personal.removeAll { $0.id == id }
                    self.rebuild()
                },
                onFailure: { [weak self] error in
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 표시용

    var tripTitle: String { home?.trip.title ?? "" }

    /// "2025.04.24 - 04.26"
    var tripPeriod: String {
        guard let trip = home?.trip else { return "" }
        let start = trip.startDate.replacingOccurrences(of: "-", with: ".")
        let endParts = trip.endDate.split(separator: "-")
        let end = endParts.count >= 3 ? "\(endParts[1]).\(endParts[2])" : trip.endDate
        return "\(start) - \(end)"
    }

    // MARK: - 오늘의 일정 (서버 계산값)

    /// 오늘이 몇 일차인지 — 서버가 판정해 내려줍니다.
    var todayDayNumber: Int? { home?.todayDayNumber }

    /// 오늘 일정 — 서버가 골라 준 것을 그대로 씁니다.
    /// 홈 화면과 같은 값을 쓰므로 두 화면이 서로 다른 "오늘"을 보여줄 일이 없습니다.
    var todaySchedules: [TravelerScheduleDTO] {
        (home?.todaySchedules ?? []).sorted { $0.startTime < $1.startTime }
    }

    /// 여행이 오늘을 포함하는지 — 상단 "오늘의 일정" 섹션 표시 여부
    var isTripToday: Bool { todayDayNumber != nil && !todaySchedules.isEmpty }

    /// 지금 진행 중인 일정. 없으면 다음 예정 일정, 오늘 일정이 끝났으면 nil.
    var todayCurrentSchedule: TravelerScheduleDTO? {
        let now = AppDate.minutesNow
        if let ongoing = todaySchedules.first(where: { s in
            guard let st = AppDate.minutes(s.startTime), let et = AppDate.minutes(s.endTime) else { return false }
            return st <= now && now < et
        }) {
            return ongoing
        }
        return todaySchedules
            .filter { (AppDate.minutes($0.startTime) ?? 0) > now }
            .min { (AppDate.minutes($0.startTime) ?? 0) < (AppDate.minutes($1.startTime) ?? 0) }
    }

    /// 오늘 일정 전체 구간에서 지금까지의 경과 비율 (0...1)
    var todayProgress: Double {
        let starts = todaySchedules.compactMap { AppDate.minutes($0.startTime) }
        let ends   = todaySchedules.compactMap { AppDate.minutes($0.endTime) }
        guard let first = starts.min(), let last = ends.max(), last > first else { return 0 }
        return min(max(Double(AppDate.minutesNow - first) / Double(last - first), 0), 1)
    }

    /// "1일차 2025.04.24" 헤더용
    func dayLabel(_ section: DaySection) -> String {
        section.date.isEmpty
            ? "\(section.dayNumber)일차"
            : "\(section.dayNumber)일차  \(section.date.replacingOccurrences(of: "-", with: "."))"
    }

    static func timeRange(_ start: String, _ end: String) -> String {
        "\(AppDate.hhmm(start)) - \(AppDate.hhmm(end))"
    }

    // MARK: - Private

    private static func withSeconds(_ hhmm: String) -> String {
        hhmm.split(separator: ":").count == 2 ? "\(hhmm):00" : hhmm
    }

    /// 겹치는 공용 일정 이름을 넣어 안내 문구를 만듭니다.
    private static func overlapMessage(
        for personal: TravelerPersonalScheduleDTO,
        shared: [TravelerScheduleDTO]
    ) -> String {
        let names = shared
            .filter { personal.overlapWithSharedScheduleIds.contains($0.id) }
            .compactMap { s -> String? in
                guard let name = s.placeName ?? s.mainContent else { return nil }
                return "\(AppDate.hhmm(s.startTime)) \(name)"
            }
        return names.isEmpty
            ? "공용 일정과 시간이 겹칩니다"
            : "공용 일정과 겹칩니다 (\(names.joined(separator: ", ")))"
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "네트워크에 연결되어 있지 않습니다"
            case .timeout:                  return "서버 응답이 없습니다"
            case .validationFailed:         return "입력한 내용을 다시 확인해주세요"
            default:                        break
            }
        }
        return "일정을 불러오지 못했습니다"
    }
}
