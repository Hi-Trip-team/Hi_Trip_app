import Foundation
import RxSwift

// MARK: - RemoteScheduleRepository
/// 실제 백엔드 API를 호출하는 Schedule Repository
///
/// API: /api/trips/:trip_pk/schedules/
/// 여행사가 등록한 공식 일정을 서버에서 가져오거나 수정

final class RemoteScheduleRepository: ScheduleRepositoryProtocol {

    // MARK: - Properties

    private let networkService: NetworkService
    /// 현재 활성 여행의 서버 ID (trip_pk)
    /// TripDataStore에서 설정하거나, 첫 trips 조회 시 자동 설정
    var activeTripPk: Int?

    // MARK: - Init

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    // MARK: - CRUD

    func create(schedule: Schedule) -> Single<Schedule> {
        guard let tripPk = activeTripPk else {
            return .error(HiTripError.validationFailed(
                ServerErrorDetail(message: "활성 여행이 없습니다.", fieldErrors: [:], rawBody: nil, statusCode: 400)
            ))
        }

        let body: [String: Any] = [
            "title": schedule.title,
            "day": 1,
            "time_block": "morning",
            "start_time": formatTime(schedule.date),
            "end_time": formatTime(schedule.date),
            "notes": schedule.description
        ]

        return networkService.request(
            .schedulesCreate(tripPk: tripPk, body: body),
            type: ScheduleDTO.self
        )
        .map { $0.toSchedule() }
    }

    func fetchAll() -> Single<[Schedule]> {
        guard let tripPk = activeTripPk else {
            return .just([])
        }

        return networkService.request(
            .schedulesList(tripPk: tripPk),
            type: [ScheduleDTO].self
        )
        .map { dtos in dtos.map { $0.toSchedule() } }
        .catch { error in
            print("⚠️ [ScheduleRepo] fetchAll 실패: \(error)")
            if let htError = error as? HiTripError, htError.isRetryable {
                return .just([])
            }
            return .error(error)
        }
    }

    func fetchById(id: UUID) -> Single<Schedule> {
        return .error(HiTripError.notFound(.empty(statusCode: 404)))
    }

    func update(schedule: Schedule) -> Single<Schedule> {
        // TODO: UUID → Int 매핑 구현 후 서버 호출 연결
        return .just(schedule)
    }

    func delete(id: UUID) -> Single<Void> {
        // TODO: UUID → Int 매핑 구현 후 서버 호출 연결
        return .just(())
    }

    // MARK: - 공식 일정 전용 API

    /// 여행의 공식 일정(TripOfficialSchedule) 목록을 서버에서 가져와 변환
    func fetchOfficialSchedules(tripPk: Int) -> Single<[TripOfficialSchedule]> {
        networkService.request(
            .schedulesList(tripPk: tripPk),
            type: [ScheduleDTO].self
        )
        .map { dtos in
            dtos.map { $0.toOfficialSchedule() }
        }
        .catch { error in
            print("⚠️ [ScheduleRepo] fetchOfficialSchedules 실패: \(error)")
            if let htError = error as? HiTripError, htError.isRetryable {
                return .just([])
            }
            return .error(error)
        }
    }

    /// AI 일정 재조정 요청
    func rebalanceDay(tripPk: Int, day: Int) -> Single<[ScheduleDTO]> {
        networkService.request(
            .schedulesRebalanceDay(tripPk: tripPk, day: day),
            type: [ScheduleDTO].self
        )
    }

    // MARK: - Private

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
