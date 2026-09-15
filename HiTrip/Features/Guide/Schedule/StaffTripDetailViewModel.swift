import Foundation
import RxSwift

// MARK: - StaffTripDetailViewModel
/// 전체일정 확인·수정 — Figma 12381:5209
///
/// - GET    /api/trips/{id}/schedules/       일정 목록
/// - POST   /api/trips/{id}/schedules/       일정 추가
/// - PATCH  /api/trips/{id}/schedules/{sid}/ 시간 변경·메모 수정
/// - DELETE /api/trips/{id}/schedules/{sid}/ 삭제
///
/// 수정은 즉시 서버에 저장합니다. 실패하면 목록을 되돌리고 재시도를 안내합니다.

@MainActor
final class StaffTripDetailViewModel: ObservableObject {

    struct DaySection: Identifiable {
        let dayNumber: Int
        let date: String
        let items: [StaffScheduleDTO]
        var id: Int { dayNumber }
    }

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var trip: StaffTripDTO?
    @Published private(set) var schedules: [StaffScheduleDTO] = []
    @Published var expandedDay: Int?
    @Published private(set) var isSaving = false
    @Published var saveError: String?
    @Published var toast: String?

    private let repository: StaffRepositoryProtocol
    private let disposeBag = DisposeBag()

    /// 처음 펼칠 일차 — 홈에서 누른 일정의 일차 (nil이면 오늘 → 첫 일차)
    private let focusDay: Int?

    init(
        focusDay: Int? = nil,
        repository: StaffRepositoryProtocol = AppDIContainer.shared.staffRepositoryForGuide
    ) {
        self.focusDay = focusDay
        self.repository = repository
    }

    // MARK: - Load

    func load() {
        guard state != .loading else { return }
        state = .loading

        repository.fetchTrips()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] trips in
                    guard let self else { return }
                    guard let trip = trips.current else {
                        self.state = .loaded
                        return
                    }
                    self.trip = trip
                    self.refresh()
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)
    }

    /// SaaS·안내사 수정분을 반영하려면 화면에 들어올 때마다 다시 받습니다
    func refresh() {
        guard let tripId = trip?.id else { return }

        repository.fetchSchedules(tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] list in
                    guard let self else { return }
                    self.schedules = list
                    self.state = .loaded
                    if self.expandedDay == nil { self.expandedDay = self.focusDay ?? self.todayDayNumber ?? self.days.first?.dayNumber }
                },
                onFailure: { [weak self] error in
                    if self?.schedules.isEmpty ?? true {
                        self?.state = .failed(Self.message(for: error))
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 목록

    var days: [DaySection] {
        let grouped = Dictionary(grouping: schedules, by: \.dayNumber)
        return grouped.keys.sorted().map { day in
            DaySection(
                dayNumber: day,
                date: dateText(for: day),
                items: (grouped[day] ?? []).sorted { $0.startTime < $1.startTime }
            )
        }
    }

    /// 오늘이 며칠째인지 — 여행지 날짜 기준 TripClock (여행 기간이 아니면 nil)
    /// (서버 today_day_number는 UTC라 새벽에 하루 어긋남)
    var todayDayNumber: Int? {
        trip.flatMap { TripClock(startDate: $0.startDate, endDate: $0.endDate, timeZoneID: $0.timezone) }?.todayDayNumber
    }

    var tripTitle: String { trip?.title ?? "" }

    /// "2025.04.24 - 04.26 · 참여 인원 10명"
    var tripSubtitle: String {
        guard let trip else { return "" }
        let start = trip.startDate.replacingOccurrences(of: "-", with: ".")
        let endParts = trip.endDate.split(separator: "-")
        let end = endParts.count >= 3 ? "\(endParts[1]).\(endParts[2])" : trip.endDate
        return "\(start) - \(end) · 참여 인원 \(trip.participantCount)명"
    }

    /// 일차 헤더의 날짜 — 시작일 + (일차 - 1)
    private func dateText(for dayNumber: Int) -> String {
        guard let start = AppDate.day(trip?.startDate),
              let date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: start)
        else { return "" }

        return AppDate.string(date, "yyyy.MM.dd")
    }

    func toggle(day: Int) {
        expandedDay = (expandedDay == day) ? nil : day
    }

    // MARK: - 수정

    /// 기존 일정과 시간이 겹치는지 — 추가·시간 변경 전에 경고합니다
    func overlaps(dayNumber: Int, start: String, end: String, excluding id: Int? = nil) -> Bool {
        guard let s = AppDate.minutes(start), let e = AppDate.minutes(end), s < e else { return false }
        return schedules
            .filter { $0.dayNumber == dayNumber && $0.id != id }
            .contains { item in
                guard let ss = AppDate.minutes(item.startTime), let ee = AppDate.minutes(item.endTime) else { return false }
                return s < ee && ss < e
            }
    }

    // MARK: - 장소 검색

    /// 일정 추가 시트의 카카오 장소 검색 결과
    @Published private(set) var placeResults: [KakaoPlaceResultDTO] = []
    @Published private(set) var isSearchingPlace = false

    /// 서버 adopt가 검색어 2자 이상을 요구합니다
    func searchPlaces(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { placeResults = []; return }
        isSearchingPlace = true
        repository.searchKakaoPlaces(query: q)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in self?.placeResults = $0; self?.isSearchingPlace = false },
                onFailure: { [weak self] error in
                    self?.isSearchingPlace = false
                    self?.toast = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    func clearPlaceResults() { placeResults = [] }

    // MARK: - 장소 상세

    /// 일정을 누르면 여는 장소 상세 — 장소가 없는 일정은 열지 않습니다
    @Published var selectedPlace: StaffPlaceDTO?

    func openPlace(of item: StaffScheduleDTO) {
        guard let placeId = item.place else { return }
        repository.fetchPlace(id: placeId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in self?.selectedPlace = $0 },
                onFailure: { [weak self] error in self?.toast = Self.message(for: error) }
            )
            .disposed(by: disposeBag)
    }

    func addSchedule(
        dayNumber: Int, title: String, start: String, end: String,
        place: KakaoPlaceResultDTO? = nil, placeQuery: String = "",
        onSuccess: @escaping () -> Void
    ) {
        guard let tripId = trip?.id else { return }
        isSaving = true

        // 장소를 골랐으면 서버 장소로 먼저 등록해 place_id를 받습니다 (서버는 place_id로만 받음)
        let placeId: Single<Int?> = place.map { p in
            repository.adoptKakaoPlace(query: placeQuery, providerObjectId: p.providerObjectId).map { Optional($0) }
        } ?? .just(nil)

        placeId.flatMap { [repository] placeId in
            repository.createSchedule(
                tripId: tripId, dayNumber: dayNumber,
                startTime: Self.withSeconds(start), endTime: Self.withSeconds(end),
                content: title, placeId: placeId
            )
        }
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] _ in
                self?.isSaving = false
                self?.expandedDay = dayNumber
                self?.toast = "일정을 추가했어요"
                self?.refresh()
                onSuccess()
            },
            onFailure: { [weak self] error in
                self?.isSaving = false
                self?.saveError = Self.message(for: error)
            }
        )
        .disposed(by: disposeBag)
    }

    func updateTime(_ item: StaffScheduleDTO, start: String, end: String, onSuccess: @escaping () -> Void) {
        update(item, start: Self.withSeconds(start), end: Self.withSeconds(end), content: nil, onSuccess: onSuccess)
    }

    func updateMemo(_ item: StaffScheduleDTO, content: String, onSuccess: @escaping () -> Void) {
        update(item, start: nil, end: nil, content: content, onSuccess: onSuccess)
    }

    private func update(
        _ item: StaffScheduleDTO,
        start: String?, end: String?, content: String?,
        onSuccess: @escaping () -> Void
    ) {
        guard let tripId = trip?.id else { return }
        isSaving = true

        repository.updateSchedule(tripId: tripId, id: item.id, startTime: start, endTime: end, content: content)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isSaving = false
                    self?.toast = "저장했어요"
                    self?.refresh()
                    onSuccess()
                },
                onFailure: { [weak self] error in
                    self?.isSaving = false
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    func delete(_ item: StaffScheduleDTO) {
        guard let tripId = trip?.id else { return }

        repository.deleteSchedule(tripId: tripId, id: item.id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    self?.toast = "일정을 삭제했어요"
                    self?.refresh()
                },
                onFailure: { [weak self] error in
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 헬퍼

    /// 카드 제목 — 장소가 있으면 장소, 없으면 메모를 씁니다
    static func title(of item: StaffScheduleDTO) -> String {
        if let place = item.placeName, !place.isEmpty { return place }
        return item.mainContent ?? "일정"
    }

    static func timeRange(_ start: String, _ end: String) -> String {
        "\(AppDate.hhmm(start)) - \(AppDate.hhmm(end))"
    }

    private static func withSeconds(_ hhmm: String) -> String {
        hhmm.count == 5 ? "\(hhmm):00" : hhmm
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "연결을 확인해주세요"
            default:                        break
            }
        }
        return "저장하지 못했어요"
    }
}
