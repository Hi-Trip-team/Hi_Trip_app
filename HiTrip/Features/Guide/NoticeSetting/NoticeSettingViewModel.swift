import Foundation
import RxSwift

// MARK: - NoticeSettingViewModel
/// 공지 설정 — Figma 12381:5263
///
/// - GET   /api/v1/notices/                  공지 목록
/// - POST  /api/v1/notices/                  새 공지
/// - PATCH /api/v1/notices/{id}/             공지 수정
/// - POST  /api/v1/notices/{id}/publish/     활성
/// - POST  /api/v1/notices/{id}/archive/     비활성
///
/// 활성 공지는 항상 1건입니다. 다른 공지를 켜면 서버가 기존 것을 내립니다.

@MainActor
final class NoticeSettingViewModel: ObservableObject {

    // MARK: - State

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var notices: [StaffNoticeDTO] = []
    @Published private(set) var isSaving = false
    @Published var saveError: String?
    @Published var toast: String?

    private let repository: StaffRepositoryProtocol
    private let disposeBag = DisposeBag()
    private var tripId: Int?

    init(repository: StaffRepositoryProtocol = AppDIContainer.shared.staffRepositoryForGuide) {
        self.repository = repository
    }

    // MARK: - Load

    func load() {
        guard state != .loading else { return }
        state = .loading

        repository.fetchTrips()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] trips in
                self?.tripId = trips.current?.id
                self?.refresh()
            }, onFailure: { [weak self] error in
                self?.state = .failed(Self.message(for: error))
            })
            .disposed(by: disposeBag)
    }

    func refresh() {
        repository.fetchNotices()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] list in
                    guard let self else { return }
                    // 서버는 담당 여행 전체의 공지를 돌려줍니다.
                    // 이 화면은 지금 보고 있는 여행의 공지만 다뤄야 활성 1건 규칙이 성립합니다.
                    // (전사 공지 scope == "global"은 여행과 무관하므로 함께 보여줍니다)
                    let mine = list.filter { notice in
                        guard let tripId = self.tripId else { return true }
                        return notice.trip == tripId || notice.scope == "global"
                    }
                    self.notices = mine.sorted { a, b in
                        if a.isActive != b.isActive { return a.isActive }
                        return a.createdAt > b.createdAt
                    }
                    self.state = .loaded
                },
                onFailure: { [weak self] error in
                    if self?.notices.isEmpty ?? true {
                        self?.state = .failed(Self.message(for: error))
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    var isEmpty: Bool { notices.isEmpty && state == .loaded }

    // MARK: - 작성 / 수정

    /// 새 공지 — 저장만 하고 활성화는 다음 단계에서 묻습니다
    func create(content: String, onSuccess: @escaping (StaffNoticeDTO) -> Void) {
        isSaving = true
        repository.createNotice(title: Self.title(from: content), content: content, tripId: tripId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] created in
                    self?.isSaving = false
                    self?.refresh()
                    onSuccess(created)
                },
                onFailure: { [weak self] error in
                    self?.isSaving = false
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    func update(id: Int, content: String, onSuccess: @escaping (StaffNoticeDTO) -> Void) {
        isSaving = true
        repository.updateNotice(id: id, title: Self.title(from: content), content: content)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] updated in
                    self?.isSaving = false
                    self?.refresh()
                    onSuccess(updated)
                },
                onFailure: { [weak self] error in
                    self?.isSaving = false
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    /// 서버가 제목을 따로 받으므로 본문 첫 줄을 제목으로 씁니다 (작성 화면에는 제목 입력이 없습니다)
    private static func title(from content: String) -> String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        return String(firstLine.prefix(40))
    }

    // MARK: - 활성 토글

    /// 활성 공지를 다시 누르면 해제됩니다 (전체 비활성 = 관광객 홈 "등록된 공지가 없어요")
    func toggleActive(_ notice: StaffNoticeDTO) {
        let request = notice.isActive
            ? repository.archiveNotice(id: notice.id)
            : repository.publishNotice(id: notice.id)

        request
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.refresh()
                    self?.toast = notice.isActive ? "공지를 내렸어요" : "공지를 활성화했어요"
                },
                onFailure: { [weak self] error in
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    /// 공지 삭제 — 활성 공지를 지우면 자동으로 "공지 없음" 상태가 됩니다
    func delete(_ notice: StaffNoticeDTO) {
        repository.deleteNotice(id: notice.id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    self?.refresh()
                    self?.toast = "공지를 삭제했어요"
                },
                onFailure: { [weak self] error in
                    self?.saveError = Self.message(for: error)
                }
            )
            .disposed(by: disposeBag)
    }

    func activate(id: Int) {
        repository.publishNotice(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] _ in
                self?.refresh()
                self?.toast = "공지를 활성화했어요"
            }, onFailure: { [weak self] error in
                self?.saveError = Self.message(for: error)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - 표시

    /// "04.24 10:20"
    func dateText(_ notice: StaffNoticeDTO) -> String {
        AppDate.string(iso: notice.publishedAt ?? notice.createdAt, "MM.dd HH:mm")
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            // 서버가 아카이브된 공지의 재게시를 막습니다
            case .conflict:                 return "한 번 내린 공지는 다시 활성화할 수 없어요. 새로 작성해주세요"
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "연결을 확인해주세요"
            default:                        break
            }
        }
        return "저장하지 못했어요"
    }
}
