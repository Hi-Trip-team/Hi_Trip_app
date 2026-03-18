import Foundation
import RxSwift

// MARK: - ScheduleViewModel
/// 일정 CRUD 화면의 ViewModel
///
/// LoginViewModel과 동일한 패턴:
/// - @Published로 View와 양방향 바인딩
/// - UseCase를 통해 비즈니스 로직 실행
/// - View는 ViewModel의 @Published만 관찰
///
/// CRUD 대응:
/// - [C] createSchedule() → 새 일정 생성
/// - [R] fetchSchedules() → 목록 조회 (화면 진입 시 자동 호출)
/// - [U] updateSchedule() → 기존 일정 수정
/// - [D] deleteSchedule() → 일정 삭제

final class ScheduleViewModel: ObservableObject {

    // MARK: - 목록 상태 (Read)

    /// 일정 목록 — ScheduleListView에서 ForEach로 표시
    @Published var schedules: [Schedule] = []

    // MARK: - 입력 폼 상태 (Create / Update)

    /// 제목 입력 — TextField와 바인딩
    @Published var title: String = ""

    /// 설명 입력 — TextEditor와 바인딩
    @Published var description: String = ""

    /// 날짜 선택 — DatePicker와 바인딩
    @Published var date: Date = Date()

    /// 장소 입력 — TextField와 바인딩
    @Published var location: String = ""

    // MARK: - UI 상태

    /// 로딩 중 여부
    @Published var isLoading: Bool = false

    /// 에러 메시지 (nil이면 에러 없음)
    @Published var errorMessage: String?

    /// 작업 완료 여부 (생성/수정/삭제 성공 시 true → View가 화면 닫기)
    @Published var isCompleted: Bool = false

    // MARK: - Dependencies

    private let scheduleUseCase: ScheduleUseCase
    private let disposeBag = DisposeBag()

    init(scheduleUseCase: ScheduleUseCase) {
        self.scheduleUseCase = scheduleUseCase
    }

    // MARK: - [R] Read — 목록 조회

    /// 전체 일정 목록 불러오기
    /// - 화면 진입 시 (.onAppear) 호출
    func fetchSchedules() {
        isLoading = true

        scheduleUseCase.fetchAll()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] schedules in
                    self?.isLoading = false
                    self?.schedules = schedules
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - [C] Create — 일정 생성

    /// 입력 폼의 데이터로 새 일정 생성
    func createSchedule() {
        let newSchedule = Schedule(
            title: title.trimmed,
            description: description.trimmed,
            date: date,
            location: location.trimmed
        )

        isLoading = true
        errorMessage = nil

        scheduleUseCase.create(schedule: newSchedule)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    self?.isCompleted = true
                    self?.resetForm()
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - [U] Update — 일정 수정

    /// 기존 일정의 데이터를 수정
    /// - Parameter schedule: 수정할 일정 (id가 동일한 기존 일정을 찾아 교체)
    func updateSchedule(_ schedule: Schedule) {
        let updatedSchedule = Schedule(
            id: schedule.id,
            title: title.trimmed,
            description: description.trimmed,
            date: date,
            location: location.trimmed,
            createdAt: schedule.createdAt
        )

        isLoading = true
        errorMessage = nil

        scheduleUseCase.update(schedule: updatedSchedule)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    self?.isCompleted = true
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - [D] Delete — 일정 삭제

    /// ID로 일정 삭제
    func deleteSchedule(id: UUID) {
        isLoading = true
        errorMessage = nil

        scheduleUseCase.delete(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    // 목록에서도 즉시 제거 (서버 재조회 없이 로컬 반영)
                    self?.schedules.removeAll { $0.id == id }
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 폼 관련 헬퍼

    /// 입력 폼 초기화 (생성 완료 후 호출)
    func resetForm() {
        title = ""
        description = ""
        date = Date()
        location = ""
        isCompleted = false
        errorMessage = nil
    }

    /// 수정 화면 진입 시, 기존 일정 데이터를 폼에 채워넣기
    func loadScheduleForEdit(_ schedule: Schedule) {
        title = schedule.title
        description = schedule.description
        date = schedule.date
        location = schedule.location
    }

    /// 제목이 입력되었는지 확인 (버튼 활성화용)
    var isTitleValid: Bool {
        !title.trimmed.isEmpty
    }
}
