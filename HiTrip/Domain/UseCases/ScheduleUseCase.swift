import Foundation
import RxSwift

// MARK: - ScheduleUseCase
/// 일정 CRUD 비즈니스 로직
///
/// 역할:
/// - 입력값 검증 (제목 빈 값 등)
/// - 검증 통과 시 Repository에 실제 동작 위임
///
/// LoginUseCase와 동일한 패턴:
/// - Protocol에만 의존 (DIP)
/// - 검증 실패 시 Repository 호출하지 않음 (불필요한 저장/네트워크 방지)

final class ScheduleUseCase {

    private let repository: ScheduleRepositoryProtocol

    init(repository: ScheduleRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - [C] Create (생성)

    /// 일정 생성
    ///
    /// 검증: 제목이 비어있으면 에러 반환
    /// 통과: Repository.create() 호출
    func create(schedule: Schedule) -> Single<Schedule> {
        guard !schedule.title.trimmed.isEmpty else {
            return .error(ScheduleError.emptyTitle)
        }

        return repository.create(schedule: schedule)
    }

    // MARK: - [R] Read (조회)

    /// 전체 일정 목록 조회
    /// - 검증 불필요 → 바로 Repository 호출
    func fetchAll() -> Single<[Schedule]> {
        return repository.fetchAll()
    }

    /// 특정 일정 조회
    func fetchById(id: UUID) -> Single<Schedule> {
        return repository.fetchById(id: id)
    }

    // MARK: - [U] Update (수정)

    /// 일정 수정
    ///
    /// 검증: 제목이 비어있으면 에러 반환
    /// 통과: Repository.update() 호출
    func update(schedule: Schedule) -> Single<Schedule> {
        guard !schedule.title.trimmed.isEmpty else {
            return .error(ScheduleError.emptyTitle)
        }

        return repository.update(schedule: schedule)
    }

    // MARK: - [D] Delete (삭제)

    /// 일정 삭제
    /// - 검증 불필요 → 바로 Repository 호출
    func delete(id: UUID) -> Single<Void> {
        return repository.delete(id: id)
    }
}

// MARK: - ScheduleError
/// 일정 관련 에러 정의
enum ScheduleError: LocalizedError, Equatable {
    /// 제목 미입력
    case emptyTitle
    /// 해당 ID의 일정을 찾을 수 없음
    case notFound
    /// 서버 에러
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "일정 제목을 입력해주세요."
        case .notFound:
            return "일정을 찾을 수 없습니다."
        case .serverError(let msg):
            return msg
        }
    }
}
