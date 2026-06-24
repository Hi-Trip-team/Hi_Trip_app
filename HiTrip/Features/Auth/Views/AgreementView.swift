import SwiftUI
import RxSwift

// MARK: - AgreementView
/// 약관 동의 화면 — 로그인 후 requiresAgreement == true 일 때 표시
///
/// POST /api/traveler/agreements/ 로 동의 저장 후 홈으로 이동.

struct AgreementView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var vm = AgreementViewModel()

    var body: some View {
        ZStack {
            HiTripColor.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("서비스 이용 약관")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
                    .padding(.top, 60)

                Text("원활한 서비스 이용을 위해\n아래 약관에 동의해 주세요.")
                    .font(.system(size: 15))
                    .foregroundColor(HiTripColor.gray500)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 16) {
                    agreementRow(title: "서비스 이용약관 동의 (필수)", isChecked: $vm.termsAccepted)
                    agreementRow(title: "위치 정보 수집 동의 (선택)",  isChecked: $vm.locationAccepted)
                    agreementRow(title: "알림 수신 동의 (선택)",       isChecked: $vm.notificationAccepted)
                }
                .padding(.horizontal, 24)

                Spacer()

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                }

                Button {
                    vm.submit { router.navigateToHome() }
                } label: {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("동의하고 시작하기")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(vm.termsAccepted ? HiTripColor.primary800 : HiTripColor.gray300)
                .cornerRadius(14)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .disabled(!vm.termsAccepted || vm.isLoading)
            }
        }
    }

    private func agreementRow(title: String, isChecked: Binding<Bool>) -> some View {
        Button { isChecked.wrappedValue.toggle() } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isChecked.wrappedValue ? HiTripColor.primary800 : HiTripColor.gray300)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(HiTripColor.textBlack)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AgreementViewModel

final class AgreementViewModel: ObservableObject {

    @Published var termsAccepted: Bool = false
    @Published var locationAccepted: Bool = false
    @Published var notificationAccepted: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()

    init(repository: TravelerRepositoryProtocol = APIEnvironment.current.useMock ? MockTravelerRepository() : TravelerRepository()) {
        self.repository = repository
    }

    func submit(onSuccess: @escaping () -> Void) {
        isLoading = true
        errorMessage = nil

        repository.updateAgreements(
            termsAccepted: termsAccepted,
            locationAccepted: locationAccepted,
            notificationAccepted: notificationAccepted
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] _ in
                self?.isLoading = false
                TripDataStore.shared.reload()
                onSuccess()
                print("✅ [Agreement] 약관 동의 완료")
            },
            onFailure: { [weak self] error in
                self?.isLoading = false
                self?.errorMessage = "약관 저장에 실패했습니다. 다시 시도해 주세요."
                print("⚠️ [Agreement] 약관 동의 실패: \(error.localizedDescription)")
            }
        )
        .disposed(by: disposeBag)
    }
}
