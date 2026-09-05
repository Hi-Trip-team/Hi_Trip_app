import Foundation
import RxSwift

// MARK: - TripScheduleViewModel
/// 전체일정 화면 — 공용 일정 + 개인 일정
///
/// - GET  /api/v1/tourist/trip/                여행 정보(제목·기간)
/// - GET  /api/v1/tourist/schedules/           여행사 공용 일정 전체
/// - GET  /api/v1/tourist/personal-schedules/  내가 추가한 일정
/// - POST /api/v1/tourist/personal-schedules/  개인 일정 추가
///
/// 공용 일정과의 시간 겹침은 서버가 판정해 `overlap_warning`으로 내려줍니다.
/// 앱에서 다시 계산하지 않습니다.

@MainActor
final class TripScheduleViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

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
    @Published private(set) var trip: TravelerTripDTO?
    @Published private(set) var days: [DaySection] = []
    @Published var expandedDay: Int?

    /// 개인 일정 저장 중
    @Published private(set) var isSaving = false
    /// 저장 실패 메시지 — 표시 후 nil로 되돌립니다.
    @Published var saveError: String?
    /// 방금 저장한 일정이 공용 일정과 겹쳤을 때 안내
    @Published var overlapNotice: String?

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

        Single.zip(
            repository.fetchTrip(),
            repository.fetchSchedules(),
            repository.fetchPersonalSchedules()
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] trip, schedules, personals in
                guard let self else { return }
                self.trip = trip
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
    func addPersonalSchedule(dayNumber: Int, title: String, start: String, end: String, memo: String?) {
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
                    if created.overlapWarning {
                        self.overlapNotice = Self.overlapMessage(for: created, shared: self.shared)
                    }
                },
                onFailure: { [weak self] error in
                    self?.isSaving = false
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
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

    var tripTitle: String { trip?.title ?? "" }

    /// "2025.04.24 - 04.26"
    var tripPeriod: String {
        guard let trip else { return "" }
        let start = trip.startDate.replacingOccurrences(of: "-", with: ".")
        let endParts = trip.endDate.split(separator: "-")
        let end = endParts.count >= 3 ? "\(endParts[1]).\(endParts[2])" : trip.endDate
        return "\(start) - \(end)"
    }

    /// 오늘 날짜 "yyyy-MM-dd"
    private static var todayString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        return df.string(from: Date())
    }

    /// 오늘이 몇 일차인지 — 오늘 날짜와 일치하는 일정이 없으면 nil
    ///
    /// d_day나 일차 번호로 계산하지 않고 각 일정의 schedule_date를 오늘 날짜와
    /// 직접 맞춥니다. 일차 번호는 날짜와 어긋날 수 있어(여행이 이미 끝났는데도
    /// "2일차"가 나오는 식) 오늘이 아닌 일정을 오늘로 보여주게 됩니다.
    var todayDayNumber: Int? {
        let today = Self.todayString
        return shared.first { $0.scheduleDate == today }?.dayNumber
    }

    // MARK: - 오늘의 일정 (상단 요약)

    /// 오늘 날짜에 해당하는 일정만. 여행 기간 밖이면 비어 있습니다.
    var todaySchedules: [TravelerScheduleDTO] {
        let today = Self.todayString
        return shared
            .filter { $0.scheduleDate == today }
            .sorted { $0.startTime < $1.startTime }
    }

    /// 여행이 오늘을 포함하는지 — 상단 "오늘의 일정" 섹션 표시 여부
    var isTripToday: Bool { !todaySchedules.isEmpty }

    /// 지금 진행 중인 일정. 없으면 다음 예정 일정, 오늘 일정이 끝났으면 nil.
    var todayCurrentSchedule: TravelerScheduleDTO? {
        let now = Self.minutesNow()
        if let ongoing = todaySchedules.first(where: { s in
            guard let st = Self.minutes(s.startTime), let et = Self.minutes(s.endTime) else { return false }
            return st <= now && now < et
        }) {
            return ongoing
        }
        return todaySchedules
            .filter { (Self.minutes($0.startTime) ?? 0) > now }
            .min { (Self.minutes($0.startTime) ?? 0) < (Self.minutes($1.startTime) ?? 0) }
    }

    /// 오늘 일정 전체 구간에서 지금까지의 경과 비율 (0...1)
    var todayProgress: Double {
        let starts = todaySchedules.compactMap { Self.minutes($0.startTime) }
        let ends   = todaySchedules.compactMap { Self.minutes($0.endTime) }
        guard let first = starts.min(), let last = ends.max(), last > first else { return 0 }
        return min(max(Double(Self.minutesNow() - first) / Double(last - first), 0), 1)
    }

    private static func minutes(_ time: String) -> Int? {
        let p = time.split(separator: ":").compactMap { Int($0) }
        guard p.count >= 2 else { return nil }
        return p[0] * 60 + p[1]
    }

    private static func minutesNow() -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// "1일차 2025.04.24" 헤더용
    func dayLabel(_ section: DaySection) -> String {
        section.date.isEmpty
            ? "\(section.dayNumber)일차"
            : "\(section.dayNumber)일차  \(section.date.replacingOccurrences(of: "-", with: "."))"
    }

    static func hhmm(_ time: String) -> String {
        time.split(separator: ":").prefix(2).joined(separator: ":")
    }

    static func timeRange(_ start: String, _ end: String) -> String {
        "\(hhmm(start)) - \(hhmm(end))"
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
                return "\(hhmm(s.startTime)) \(name)"
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
