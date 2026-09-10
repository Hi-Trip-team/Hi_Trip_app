import SwiftUI
import SafariServices
import CoreLocation
import RxSwift

// MARK: - AgreementView
/// 약관/권한 동의 화면
///
/// - 관광객: 필수 4(서비스·개인정보·위치·건강정보) + 선택 1
/// - 안내사: 필수 3 + 선택 1 (건강정보 행 없음)
/// - 건강정보는 개인정보보호법상 민감정보라 개인정보 동의와 분리된 별도 행입니다.
/// - [다음] → OS 권한 순차 요청(위치 → 알림 → 헬스) → 동의 저장 → 역할별 홈

struct AgreementView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var vm: AgreementViewModel
    @State private var viewingTerms: TermsKind?

    init(userType: UserType) {
        _vm = StateObject(wrappedValue: AgreementViewModel(userType: userType))
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("서비스 이용을 위해\n약관에 동의해주세요")
                    .font(HiTripFont.title1)
                    .foregroundColor(HiTripColor.textBlack)
                    .lineSpacing(4)
                    .padding(.top, 60)
                    .padding(.horizontal, HiTripSpacing.xl)

                allAgreeRow
                    .padding(.top, 36)
                    .padding(.horizontal, HiTripSpacing.pagePadding)

                VStack(spacing: 0) {
                    ForEach(vm.items) { kind in
                        termsRow(kind)
                    }
                }
                .padding(.top, HiTripSpacing.sm)
                .padding(.horizontal, HiTripSpacing.pagePadding)

                Spacer()

                if let error = vm.errorMessage {
                    Text(error)
                        .font(HiTripFont.caption)
                        .foregroundColor(HiTripColor.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, HiTripSpacing.sm)
                }

                nextButton
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.bottom, HiTripSpacing.xl)
            }

            if vm.showLocationDeniedPopup {
                locationDeniedPopup
            }
        }
        .sheet(item: $viewingTerms) { kind in
            TermsDocumentView(kind: kind)
        }
    }

    // MARK: - 전체 동의

    private var allAgreeRow: some View {
        Button { vm.toggleAll() } label: {
            HStack(spacing: HiTripSpacing.md) {
                checkIcon(vm.allChecked, size: 24)
                Text("전체 동의")
                    .font(HiTripFont.bodyLBold)
                    .foregroundColor(HiTripColor.textBlack)
                Spacer()
            }
            .padding(HiTripSpacing.lg)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 개별 행

    private func termsRow(_ kind: TermsKind) -> some View {
        HStack(spacing: HiTripSpacing.md) {
            Button { vm.toggle(kind) } label: {
                HStack(alignment: .top, spacing: HiTripSpacing.md) {
                    checkIcon(vm.checked.contains(kind), size: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        (Text(vm.isRequired(kind) ? "[필수] " : "[선택] ")
                            .foregroundColor(vm.isRequired(kind) ? HiTripColor.primary800 : HiTripColor.gray500)
                         + Text(kind.title)
                            .foregroundColor(HiTripColor.textBlack))
                            .font(HiTripFont.body)
                        if let note = kind.note {
                            Text(note)
                                .font(HiTripFont.caption)
                                .foregroundColor(HiTripColor.gray400)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { viewingTerms = kind } label: {
                HStack(spacing: 2) {
                    Text("보기")
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                }
                .font(HiTripFont.caption)
                .foregroundColor(HiTripColor.gray500)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, HiTripSpacing.md)
        .padding(.horizontal, HiTripSpacing.xs)
    }

    private func checkIcon(_ on: Bool, size: CGFloat) -> some View {
        Image(systemName: on ? "checkmark.circle.fill" : "circle")
            .font(.system(size: size))
            .foregroundColor(on ? HiTripColor.primary800 : HiTripColor.gray300)
    }

    // MARK: - 다음

    private var nextButton: some View {
        Button {
            Task {
                if await vm.proceed() { router.navigateToHomeAs(vm.userType) }
            }
        } label: {
            ZStack {
                if vm.isProcessing {
                    ProgressView().tint(.white)
                } else {
                    Text("다음")
                        .font(HiTripFont.bodyLBold)
                        .foregroundColor(vm.canProceed ? .white : HiTripColor.buttonDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(vm.canProceed ? HiTripColor.primary800 : HiTripColor.buttonDisabled)
            .cornerRadius(HiTripRadius.card)
        }
        .buttonStyle(.plain)
        .disabled(!vm.canProceed || vm.isProcessing)
    }

    // MARK: - 위치 거부 안내 (앱 자체 팝업)

    private var locationDeniedPopup: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: HiTripSpacing.md) {
                Text("위치 권한이 꺼져 있어요")
                    .font(HiTripFont.title3)
                    .foregroundColor(HiTripColor.textBlack)
                Text("위치 권한이 없으면 일정 이탈 알림 등\n안전 서비스가 제한됩니다.")
                    .font(HiTripFont.body)
                    .foregroundColor(HiTripColor.gray500)
                    .multilineTextAlignment(.center)

                HStack(spacing: HiTripSpacing.sm) {
                    Button { vm.resolveLocationPopup(openSettings: false) } label: {
                        Text("나중에")
                            .font(HiTripFont.bodyBold)
                            .foregroundColor(HiTripColor.gray500)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(HiTripColor.gray100)
                            .cornerRadius(HiTripRadius.card)
                    }
                    Button { vm.resolveLocationPopup(openSettings: true) } label: {
                        Text("설정으로 이동")
                            .font(HiTripFont.bodyBold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(HiTripColor.primary800)
                            .cornerRadius(HiTripRadius.card)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, HiTripSpacing.sm)
            }
            .padding(HiTripSpacing.xl)
            .background(Color.white)
            .cornerRadius(HiTripRadius.lg)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - TermsKind 표시 정보

extension TermsKind {
    var title: String {
        switch self {
        case .service:   return "서비스 이용약관 동의"
        case .privacy:   return "개인정보 수집·이용 동의"
        case .location:  return "위치기반서비스 이용약관 동의"
        case .health:    return "건강정보(민감정보) 수집·이용 동의"
        case .marketing: return "마케팅 정보 수신 동의"
        }
    }

    var note: String? {
        switch self {
        case .privacy: return "보유기간: 여행 종료 후 3일"
        case .health:  return "워치로 측정한 심박수·산소포화도"
        default:       return nil
        }
    }
}

// MARK: - 약관 전문 (웹뷰)

private struct TermsDocumentView: View {
    let kind: TermsKind

    var body: some View {
        if let url = AppLinks.terms(kind) {
            SafariView(url: url).ignoresSafeArea()
        } else {
            VStack(spacing: HiTripSpacing.md) {
                Text(kind.title)
                    .font(HiTripFont.title3)
                Text("약관 전문 주소가 아직 등록되지 않았습니다.")
                    .font(HiTripFont.body)
                    .foregroundColor(HiTripColor.gray500)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

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
            ? [.service, .privacy, .location, .health, .marketing]
            : [.service, .privacy, .location, .marketing]
    }

    func isRequired(_ kind: TermsKind) -> Bool { kind != .marketing }

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
            let userId = KeychainManager.shared.getUserId() ?? "0"
            AgreementRecordStore.record(userId: userId, userType: userType, optionalAccepted: checked.contains(.marketing))
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
