import Foundation
import CoreLocation
import RxSwift

// MARK: - AgreementViewModel

@MainActor
final class AgreementViewModel: ObservableObject {

    let userType: UserType
    let items: [TermsKind]

    @Published var checked: Set<TermsKind> = []
    @Published private(set) var isProcessing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var showLocationDeniedPopup = false

    private var locationPopupContinuation: CheckedContinuation<Void, Never>?
    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()

    init(userType: UserType, repository: TravelerRepositoryProtocol = AppDIContainer.shared.makeTravelerRepository()) {
        self.userType = userType
        self.repository = repository
        self.items = userType == .tourist
            ? [.service, .privacy, .location, .health, .push]
            : [.service, .privacy, .location, .push]
    }

    func isRequired(_ kind: TermsKind) -> Bool { kind != .push }

    var allChecked: Bool { Set(items).isSubset(of: checked) }

    var canProceed: Bool { items.filter(isRequired).allSatisfy(checked.contains) }

    func toggleAll() {
        checked = allChecked ? [] : Set(items)
    }

    func toggle(_ kind: TermsKind) {
        if checked.contains(kind) { checked.remove(kind) } else { checked.insert(kind) }
    }

    // MARK: - 다음

    /// 권한을 순서대로 요청하고 동의를 저장합니다. 성공 시 true.
    func proceed() async -> Bool {
        guard canProceed, !isProcessing else { return false }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        let permissions = PermissionCoordinator.shared

        // ① 위치 — 방금 "허용 안 함"을 고른 경우에만 앱 안내 팝업
        let wasUndetermined = permissions.isLocationUndetermined
        let location = await permissions.requestLocation()
        if wasUndetermined, location == .denied || location == .restricted {
            await withCheckedContinuation { continuation in
                locationPopupContinuation = continuation
                showLocationDeniedPopup = true
            }
        }

        // ② 알림  ③ 헬스(관광객) — 거부해도 진행
        let notification = await permissions.requestNotification()
        if userType == .tourist {
            _ = await permissions.requestHealth()
        }

        // 동의 이력 저장
        let locationGranted = location == .authorizedWhenInUse || location == .authorizedAlways
        do {
            if userType == .tourist {
                try await saveTouristAgreement(location: locationGranted, notification: notification)
            }
            AgreementRecordStore.record(optionalAccepted: checked.contains(.push))
            return true
        } catch {
            errorMessage = "동의 내용을 저장하지 못했어요. 다시 시도해주세요."
            return false
        }
    }

    func resolveLocationPopup(openSettings: Bool) {
        showLocationDeniedPopup = false
        if openSettings { PermissionCoordinator.shared.openSettings() }
        locationPopupContinuation?.resume()
        locationPopupContinuation = nil
    }

    /// POST /api/v1/tourist/agreements/ — 동의 일시는 서버 accepted_at으로 남습니다
    private func saveTouristAgreement(location: Bool, notification: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            repository.updateAgreements(
                termsAccepted: true,
                locationAccepted: location,
                notificationAccepted: notification
            )
            .subscribe(
                onSuccess: { _ in continuation.resume() },
                onFailure: { continuation.resume(throwing: $0) }
            )
            .disposed(by: disposeBag)
        }
    }
}
