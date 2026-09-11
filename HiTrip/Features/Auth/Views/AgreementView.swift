import SwiftUI
import SafariServices
import CoreLocation
import RxSwift

// MARK: - AgreementView
/// 약관/권한 동의 화면
///
/// Figma 0827 수정본 — 기본 12381:6078 / 위치 거부 팝업 12381:5737
///
/// - 관광객: 필수 4(서비스·개인정보·위치·건강정보) + 선택 1(푸시 알림 수신)
/// - 안내사: 필수 3 + 선택 1 (건강정보 행 없음)
/// - 건강정보는 개인정보보호법상 민감정보라 개인정보 동의와 분리된 별도 행입니다.
/// - [다음] → OS 권한 순차 요청(위치 → 알림 → 헬스) → 동의 저장 → 역할별 홈

struct AgreementView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var vm: AgreementViewModel
    @State private var viewingTerms: TermsKind?

    // Figma 색상 (약관·권한 동의 12381:6078)
    private let titleColor = Color(hex: "#111827")
    private let bodyColor = Color(hex: "#333840")
    private let subColor = Color(hex: "#6B7280")
    private let cardGray = Color(hex: "#F3F4F6")
    private let checkBlue = Color(hex: "#2563EB")

    init(userType: UserType) {
        _vm = StateObject(wrappedValue: AgreementViewModel(userType: userType))
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("약관에 동의해주세요")
                    .font(.pretendard(.bold, size: 22))
                    .foregroundColor(titleColor)
                    .padding(.top, 33)

                Text("모든 정보는 여행 종료 3일 후 자동 파기됩니다.")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundColor(subColor)
                    .padding(.top, 10)

                allAgreeRow
                    .padding(.top, 18)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(vm.items) { kind in
                        termsRow(kind)
                    }
                }
                .padding(.top, 18)

                Spacer()

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.pretendard(.regular, size: 12))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                }

                nextButton
                    .padding(.horizontal, -4)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)

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
            HStack(spacing: 10) {
                checkBox(vm.allChecked)
                Text("전체 동의")
                    .font(.pretendard(.bold, size: 16))
                    .foregroundColor(titleColor)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(cardGray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 개별 행 (행 간격 52pt, 체크박스 x=40)

    private func termsRow(_ kind: TermsKind) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button { vm.toggle(kind) } label: {
                HStack(alignment: .top, spacing: 10) {
                    checkBox(vm.checked.contains(kind))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("[\(vm.isRequired(kind) ? "필수" : "선택")] \(kind.title)")
                            .font(.pretendard(.regular, size: 14))
                            .foregroundColor(bodyColor)
                            .padding(.top, 1)
                        if let note = kind.note {
                            Text(note)
                                .font(.pretendard(.regular, size: 11))
                                .foregroundColor(subColor)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { viewingTerms = kind } label: {
                Text("보기 >")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundColor(subColor)
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .frame(minHeight: 52, alignment: .top)
        .padding(.bottom, kind.note == nil ? 0 : 24)
    }

    /// 20pt 원형 체크박스 — 체크 시 #2563EB 채움 + 흰 ✓
    private func checkBox(_ on: Bool) -> some View {
        ZStack {
            Circle()
                .fill(on ? checkBlue : Color.white)
                .overlay(Circle().stroke(on ? checkBlue : Color(hex: "#D1D5DB"), lineWidth: 1.5))
            if on {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 20, height: 20)
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
                        .font(.pretendard(.medium, size: 16))
                        .tracking(0.16)
                        .foregroundColor(vm.canProceed ? Color(hex: "#F8F8F8") : HiTripColor.buttonDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(vm.canProceed ? Color(hex: "#0C46C0") : HiTripColor.buttonDisabled)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .disabled(!vm.canProceed || vm.isProcessing)
    }

    // MARK: - 위치 거부 안내 (12381:5737)

    private var locationDeniedPopup: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                Text("위치 권한이 없으면 안전 서비스\n(위치 확인·이탈 보호)를 이용할 수 없습니다")
                    .font(.pretendard(.bold, size: 14))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)

                Text("설정에서 언제든지 변경할 수 있어요")
                    .font(.pretendard(.regular, size: 12))
                    .foregroundColor(subColor)
                    .padding(.top, 8)

                HStack(spacing: 10) {
                    Button { vm.resolveLocationPopup(openSettings: false) } label: {
                        Text("나중에")
                            .font(.pretendard(.medium, size: 14))
                            .foregroundColor(bodyColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(cardGray)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button { vm.resolveLocationPopup(openSettings: true) } label: {
                        Text("설정으로 이동")
                            .font(.pretendard(.bold, size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(checkBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .frame(width: 310)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - TermsKind 표시 정보

extension TermsKind {
    var title: String {
        switch self {
        case .service:  return "서비스 이용약관"
        case .privacy:  return "개인정보 수집·이용 동의"
        case .location: return "위치기반서비스 이용약관"
        case .health:   return "건강정보(민감정보) 수집·이용 동의"
        case .push:     return "푸시 알림 수신"
        }
    }

    var note: String? {
        switch self {
        case .health: return "심박수·산소포화도 수집 — 안전관리 목적"
        default:      return nil
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
