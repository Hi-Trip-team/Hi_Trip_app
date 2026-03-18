import Foundation
import RxSwift

// MARK: - ScheduleRepositoryProtocol
/// 일정 데이터 접근 인터페이스 (Domain 레이어)
///
/// CRUD 4가지 동작을 Protocol로 정의
/// - 실제 구현은 Data 레이어의 ScheduleRepository에서 담당
/// - 테스트 시 MockScheduleRepository로 교체 가능
///
/// AuthRepositoryProtocol과 동일한 설계 패턴:
/// - Domain은 Protocol만 알고, 구현체는 모름 (DIP)
/// - UseCase가 이 Protocol에 의존

protocol ScheduleRepositoryProtocol {

    /// [C] 일정 생성 — 새 일정을 저장소에 추가
    func create(schedule: Schedule) -> Single<Schedule>

    /// [R] 전체 일정 조회 — 저장된 모든 일정을 반환
    func fetchAll() -> Single<[Schedule]>

    /// [R] 단일 일정 조회 — ID로 특정 일정 조회
    func fetchById(id: UUID) -> Single<Schedule>

    /// [U] 일정 수정 — 기존 일정의 내용을 업데이트
    func update(schedule: Schedule) -> Single<Schedule>

    /// [D] 일정 삭제 — ID로 특정 일정 삭제
    func delete(id: UUID) -> Single<Void>
}
