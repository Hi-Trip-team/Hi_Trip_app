import Foundation
import RxSwift

// MARK: - ScheduleRepository
/// 일정 저장소 구현체 (메모리 저장)
///
/// 현재: 앱 메모리(배열)에 저장 — 앱 종료 시 데이터 사라짐
/// 나중에: NetworkService를 사용하여 서버 API로 교체
///
/// ScheduleRepositoryProtocol을 구현하므로,
/// UseCase는 이 클래스의 존재를 모름 (DIP)
///
/// 메모리 저장 → 서버 저장으로 변경할 때:
/// - 이 파일의 내부 구현만 수정
/// - UseCase, ViewModel, View는 수정 불필요

final class ScheduleRepository: ScheduleRepositoryProtocol {

    // MARK: - 저장소

    /// 메모리 기반 일정 저장소
    /// - 배열에 Schedule을 저장하고, CRUD 메서드에서 이 배열을 조작
    /// - private: 외부에서 직접 접근 불가 (반드시 메서드를 통해서만 접근)
    private var schedules: [Schedule] = []

    // MARK: - [C] Create

    /// 일정을 배열에 추가하고, 추가된 일정을 반환
    func create(schedule: Schedule) -> Single<Schedule> {
        return Single.create { [weak self] single in
            self?.schedules.append(schedule)
            single(.success(schedule))
            return Disposables.create()
        }
    }

    // MARK: - [R] Read

    /// 전체 일정을 날짜순(최신순)으로 정렬하여 반환
    func fetchAll() -> Single<[Schedule]> {
        return Single.create { [weak self] single in
            let sorted = self?.schedules.sorted { $0.date > $1.date } ?? []
            single(.success(sorted))
            return Disposables.create()
        }
    }

    /// ID로 특정 일정 조회
    /// - 찾으면 해당 일정 반환, 못 찾으면 notFound 에러
    func fetchById(id: UUID) -> Single<Schedule> {
        return Single.create { [weak self] single in
            if let schedule = self?.schedules.first(where: { $0.id == id }) {
                single(.success(schedule))
            } else {
                single(.failure(ScheduleError.notFound))
            }
            return Disposables.create()
        }
    }

    // MARK: - [U] Update

    /// 배열에서 같은 ID를 가진 일정을 찾아 교체
    /// - 못 찾으면 notFound 에러
    func update(schedule: Schedule) -> Single<Schedule> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(ScheduleError.notFound))
                return Disposables.create()
            }

            // 같은 ID의 일정 위치(index) 찾기
            if let index = self.schedules.firstIndex(where: { $0.id == schedule.id }) {
                // 해당 위치의 일정을 새 데이터로 교체
                self.schedules[index] = schedule
                single(.success(schedule))
            } else {
                single(.failure(ScheduleError.notFound))
            }
            return Disposables.create()
        }
    }

    // MARK: - [D] Delete

    /// 배열에서 같은 ID를 가진 일정을 제거
    /// - 못 찾으면 notFound 에러
    func delete(id: UUID) -> Single<Void> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(ScheduleError.notFound))
                return Disposables.create()
            }

            if let index = self.schedules.firstIndex(where: { $0.id == id }) {
                self.schedules.remove(at: index)
                single(.success(()))
            } else {
                single(.failure(ScheduleError.notFound))
            }
            return Disposables.create()
        }
    }
}
