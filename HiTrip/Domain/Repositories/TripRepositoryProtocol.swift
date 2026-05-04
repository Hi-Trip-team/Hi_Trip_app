import Foundation
import RxSwift

// MARK: - TripRepositoryProtocol
/// 여행 데이터 접근 인터페이스 (Domain 레이어)
///
/// TripDataStore가 이 Protocol을 통해 데이터를 읽고 쓴다.
/// 현재는 MockTripRepository(메모리)를 사용하지만,
/// API 연동 시 RemoteTripRepository로 교체하면 된다.
///
/// TripDataStore는 Repository에서 받은 데이터를 @Published에 저장하고,
/// 여러 ViewModel이 Store를 구독하여 UI를 갱신한다.

protocol TripRepositoryProtocol {

    // MARK: - TripPackage

    /// 현재 사용자에게 배정된 여행 패키지 조회
    /// (여행사가 등록 후 고객을 추가하면 해당 고객에게 노출)
    func fetchCurrentPackage() -> Single<TripPackage?>

    /// 전체 패키지 목록 (여행사 관리용)
    func fetchPackages() -> Single<[TripPackage]>

    // MARK: - Trip

    /// 전체 여행 목록 조회
    func fetchTrips() -> Single<[Trip]>

    /// 여행 추가
    func createTrip(_ trip: Trip) -> Single<Trip>

    /// 여행 삭제
    func deleteTrip(id: UUID) -> Single<Void>

    // MARK: - Todo

    /// 특정 여행의 전체 할일 조회
    func fetchTodos(tripId: UUID) -> Single<[TripTodo]>

    /// 할일 추가
    func createTodo(_ todo: TripTodo) -> Single<TripTodo>

    /// 할일 수정 (제목 변경, 완료 토글 등)
    func updateTodo(_ todo: TripTodo) -> Single<TripTodo>

    /// 할일 삭제
    func deleteTodo(id: UUID) -> Single<Void>

    // MARK: - Event

    /// 특정 여행의 전체 이벤트 조회
    func fetchEvents(tripId: UUID) -> Single<[TripEvent]>

    /// 이벤트 추가
    func createEvent(_ event: TripEvent) -> Single<TripEvent>

    /// 이벤트 수정
    func updateEvent(_ event: TripEvent) -> Single<TripEvent>

    /// 이벤트 삭제
    func deleteEvent(id: UUID) -> Single<Void>
}
