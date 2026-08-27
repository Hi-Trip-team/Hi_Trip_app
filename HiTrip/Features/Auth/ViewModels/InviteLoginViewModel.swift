import Foundation
import RxSwift

// MARK: - InviteLoginViewModel
/// 관광객 로그인 ViewModel
///
/// POST /api/v1/tourist/auth/login/
/// Request: username, password
/// Response: TravelerAuthResponse (token + TravelerPublic + TravelerTrip)

final class InviteLoginViewModel: ObservableObject {

    // MARK: - Input Fields

    @Published var username: String = ""
    @Published var password: String = ""

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var loginSuccess: Bool = false
    @Published var requiresAgreement: Bool = false

    // MARK: - Dependencies

    private let repository: TravelerRepositoryProtocol
    private let keychain: KeychainManager
    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(
        repository: TravelerRepositoryProtocol = TravelerRepository(),
        keychain: KeychainManager = .shared
    ) {
        self.repository = repository
        self.keychain = keychain
    }

    // MARK: - Validation

    var isUsernameValid: Bool { !username.trimmingCharacters(in: .whitespaces).isEmpty }
    var isPasswordValid: Bool { password.count >= 4 }
    var isFormValid: Bool { isUsernameValid && isPasswordValid }

    // MARK: - Login

    func login() {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = nil

        repository.travelerLogin(username: username.trimmed, password: password, tripId: nil)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] response in
                    guard let self else { return }
                    self.isLoading = false

                    self.keychain.saveToken(response.token)

                    let traveler = response.traveler
                    self.keychain.saveUserName(traveler.fullNameKr)
                    self.keychain.saveUserEmail(traveler.email)
                    self.keychain.saveUserType("tourist")
                    self.keychain.saveUserId(String(traveler.id))

                    if response.requiresAgreement {
                        self.requiresAgreement = true
                        print("✅ [Login] 로그인 성공 (약관 동의 필요): \(traveler.fullNameKr)")
                    } else {
                        TripDataStore.shared.reload {
                            self.loginSuccess = true
                        }
                        print("✅ [Login] 로그인 성공: \(traveler.fullNameKr)")
                    }
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    let htError = ErrorHandler.classify(error)
                    if case .unauthorized = htError {
                        self?.errorMessage = "아이디 또는 비밀번호가 올바르지 않습니다."
                    } else if case .validationFailed(let detail) = htError {
                        self?.errorMessage = detail.userMessage ?? "입력 정보를 확인해주세요."
                    } else {
                        self?.errorMessage = htError.localizedDescription
                    }
                    print("❌ [Login] 로그인 실패: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }
}
