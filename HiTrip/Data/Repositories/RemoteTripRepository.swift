import Foundation
import RxSwift

// MARK: - RemoteTripRepository
/// 실제 백엔드 API를 호출하는 Trip Repository
///
/// MockTripRepository와 동일한 TripRepositoryProtocol을 구현하므로,
/// AppDIContainer에서 환경에 따라 교체 가능.
///
/// API 연동 흐름:
/// 1. NetworkService로 API 호출
/// 2. TripDTO 응답 수신
/// 3. DTO → 앱 내부 모델(TripPackage, Trip 등)로 변환
/// 4. 변환된 모델 반환

final class RemoteTripRepository: TripRepositoryProtocol {

    // MARK: - Properties

    private let networkService: NetworkService
    /// 서버에서 받은 여행 ID를 캐싱 (UUID ↔ Int 매핑용)
    private var tripIdMap: [UUID: Int] = [:]

    // MARK: - Init

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    // MARK: - TripPackage

    func fetchCurrentPackage() -> Single<TripPackage?> {
        networkService.request(.tripsList(), type: [TripDTO].self)
            .map { [weak self] dtos in
                guard let first = dtos.first(where: { $0.status == "active" || $0.status == "ongoing" }) ?? dtos.first else {
                    return nil
                }
                let pkg = first.toTripPackage()
                self?.tripIdMap[pkg.id] = first.id
                return pkg
            }
            .catch { error in
                print("⚠️ [TripRepo] fetchCurrentPackage 실패: \(error)")
                // 네트워크 에러는 nil 반환 (오프라인 대응), 그 외는 전파
                if let htError = error as? HiTripError, htError.isRetryable {
                    return .just(nil)
                }
                return .error(error)
            }
    }

    func fetchPackages() -> Single<[TripPackage]> {
        networkService.request(.tripsList(), type: [TripDTO].self)
            .map { [weak self] dtos in
                dtos.map { dto in
                    let pkg = dto.toTripPackage()
                    self?.tripIdMap[pkg.id] = dto.id
                    return pkg
                }
            }
            .catch { error in
                print("⚠️ [TripRepo] fetchPackages 실패: \(error)")
                if let htError = error as? HiTripError, htError.isRetryable {
                    return .just([])
                }
                return .error(error)
            }
    }

    // MARK: - Trip

    func fetchTrips() -> Single<[Trip]> {
        networkService.request(.tripsList(), type: [TripDTO].self)
            .map { dtos in dtos.map { $0.toTrip() } }
            .catch { error in
                print("⚠️ [TripRepo] fetchTrips 실패: \(error)")
                if let htError = error as? HiTripError, htError.isRetryable {
                    return .just([])
                }
                return .error(error)
            }
    }

    func createTrip(_ trip: Trip) -> Single<Trip> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return networkService.request(
            .tripsCreate(
                title: trip.title,
                startDate: dateFormatter.string(from: trip.date),
                endDate: dateFormatter.string(from: trip.date),
                destination: trip.location
            ),
            type: TripDTO.self
        )
        .map { $0.toTrip() }
    }

    func deleteTrip(id: UUID) -> Single<Void> {
        guard let serverId = tripIdMap[id] else {
            return .error(HiTripError.notFound(.empty(statusCode: 404)))
        }
        return networkService.request(.tripsDestroy(id: serverId), type: EmptyResponse.self)
            .map { _ in () }
    }

    // MARK: - Todo (로컬 저장 — 서버 API 없음)

    private var localTodos: [TripTodo] = []

    func fetchTodos(tripId: UUID) -> Single<[TripTodo]> {
        .just(localTodos.filter { $0.tripId == tripId })
    }

    func createTodo(_ todo: TripTodo) -> Single<TripTodo> {
        localTodos.append(todo)
        return .just(todo)
    }

    func updateTodo(_ todo: TripTodo) -> Single<TripTodo> {
        if let i = localTodos.firstIndex(where: { $0.id == todo.id }) {
            localTodos[i] = todo
        }
        return .just(todo)
    }

    func deleteTodo(id: UUID) -> Single<Void> {
        localTodos.removeAll { $0.id == id }
        return .just(())
    }

    // MARK: - Event (로컬 저장 — 서버 API 없음)

    private var localEvents: [TripEvent] = []

    func fetchEvents(tripId: UUID) -> Single<[TripEvent]> {
        .just(localEvents.filter { $0.tripId == tripId })
    }

    func createEvent(_ event: TripEvent) -> Single<TripEvent> {
        localEvents.append(event)
        return .just(event)
    }

    func updateEvent(_ event: TripEvent) -> Single<TripEvent> {
        if let i = localEvents.firstIndex(where: { $0.id == event.id }) {
            localEvents[i] = event
        }
        return .just(event)
    }

    func deleteEvent(id: UUID) -> Single<Void> {
        localEvents.removeAll { $0.id == id }
        return .just(())
    }
}

// MARK: - EmptyResponse
/// DELETE 등 빈 응답용

struct EmptyResponse: Decodable {}
