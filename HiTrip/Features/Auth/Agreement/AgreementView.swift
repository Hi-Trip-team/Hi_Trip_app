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
    private let titleColor = AppColor.textPrimary
    private let bodyColor = AppColor.textBody
    private let subColor = AppColor.textSecondary
    private let cardGray = AppColor.surface
    private let checkBlue = AppColor.accent

    init(userType: UserType) {
        _vm = StateObject(wrappedValue: AgreementViewModel(userType: userType))
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("약관에 동의해주세요")
                    .font(AppFont.title1Bold)
                    .foregroundColor(titleColor)
                    .padding(.top, 33)

                Text("모든 정보는 여행 종료 3일 후 자동 파기됩니다.")
                    .font(AppFont.label)
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
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, AppSpacing.xs)
                }

                nextButton
                    .padding(.horizontal, -4)
                    .padding(.bottom, AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.xl)

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
                    .font(AppFont.bodyLBold)
                    .foregroundColor(titleColor)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 52)
            .background(cardGray)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 개별 행 (행 간격 52pt, 체크박스 x=40)

    private func termsRow(_ kind: TermsKind) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button { vm.toggle(kind) } label: {
                HStack(alignment: .top, spacing: 10) {
                    checkBox(vm.checked.contains(kind))
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("[\(vm.isRequired(kind) ? "필수" : "선택")] \(kind.title)")
                            .font(AppFont.body)
                            .foregroundColor(bodyColor)
                            .padding(.top, 1)
                        if let note = kind.note {
                            Text(note)
                                .font(AppFont.caption2)
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
                    .font(AppFont.label)
                    .foregroundColor(subColor)
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, AppSpacing.md)
        .frame(minHeight: 52, alignment: .top)
        .padding(.bottom, kind.note == nil ? 0 : 24)
    }

    /// 20pt 원형 체크박스 — 체크 시 #2563EB 채움 + 흰 ✓
    private func checkBox(_ on: Bool) -> some View {
        ZStack {
            Circle()
                .fill(on ? checkBlue : Color.white)
                .overlay(Circle().stroke(on ? checkBlue : AppColor.borderStrong, lineWidth: 1.5))
            if on {
                Image(systemName: "checkmark")
                    .font(AppFont.microBold)
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
                        .font(AppFont.bodyLMedium)
                        .tracking(0.16)
                        .foregroundColor(vm.canProceed ? AppColor.onBrand : AppColor.buttonDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(vm.canProceed ? AppColor.brand : AppColor.buttonDisabled)
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
                    .font(AppFont.bodyBold)
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)

                Text("설정에서 언제든지 변경할 수 있어요")
                    .font(AppFont.caption)
                    .foregroundColor(subColor)
                    .padding(.top, AppSpacing.xs)

                HStack(spacing: 10) {
                    Button { vm.resolveLocationPopup(openSettings: false) } label: {
                        Text("나중에")
                            .font(AppFont.bodyMedium)
                            .foregroundColor(bodyColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(cardGray)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    Button { vm.resolveLocationPopup(openSettings: true) } label: {
                        Text("설정으로 이동")
                            .font(AppFont.bodyBold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(checkBlue)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.md)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .frame(width: 310)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
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
            VStack(spacing: AppSpacing.sm) {
                Text(kind.title)
                    .font(AppFont.headlineSemiBold)
                Text("약관 전문 주소가 아직 등록되지 않았습니다.")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textGray)
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
