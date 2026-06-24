import Foundation
import RxSwift

// MARK: - InviteLoginViewModel
/// 초대코드 로그인 ViewModel
///
/// POST /api/traveler/login/ 호출
/// Request: phone, birth_date, invite_code
/// Response: TravelerAuthResponse (token + TravelerPublic + TravelerTrip)

final class InviteLoginViewModel: ObservableObject {

    // MARK: - Step Navigation

    enum Step: Int, CaseIterable {
        case phone = 0       // 전화번호 입력
        case birthDate = 1   // 생년월일 입력
        case inviteCode = 2  // 초대코드 입력
    }

    @Published var currentStep: Step = .phone

    // MARK: - Input Fields

    @Published var phone: String = ""
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var inviteCode: String = ""

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

    var isPhoneValid: Bool {
        phone.filter { $0.isNumber }.count >= 10
    }

    var isInviteCodeValid: Bool {
        inviteCode.trimmed.count >= 4
    }

    var isCurrentStepValid: Bool {
        switch currentStep {
        case .phone:      return isPhoneValid
        case .birthDate:  return true
        case .inviteCode: return isInviteCodeValid
        }
    }

    // MARK: - Navigation

    func goNext() {
        if currentStep == .inviteCode {
            login()
        } else if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func goBack() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }

    var stepTitle: String {
        switch currentStep {
        case .phone:      return "전화번호를 입력해주세요"
        case .birthDate:  return "생년월일을 선택해주세요"
        case .inviteCode: return "초대코드를 입력해주세요"
        }
    }

    var stepSubtitle: String {
        switch currentStep {
        case .phone:      return "여행 등록 시 사용한 전화번호"
        case .birthDate:  return "본인 확인을 위해 필요합니다"
        case .inviteCode: return "여행사에서 받은 초대코드를 입력하세요"
        }
    }

    var buttonTitle: String {
        currentStep == .inviteCode ? "로그인" : "다음"
    }

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    // MARK: - Phone Formatting

    /// 숫자만 추출 후 010-XXXX-XXXX 형식으로 변환
    /// 서버가 하이픈 포함 포맷으로 저장된 경우를 위해 사용
    private func formatPhone(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        switch digits.count {
        case 11: // 010-XXXX-XXXX
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(4))-\(digits.dropFirst(7))"
        case 10: // 02-XXXX-XXXX 또는 010-XXX-XXXX
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.dropFirst(6))"
        default:
            return digits
        }
    }

    // MARK: - Birth Date Formatting

    var birthDateString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: birthDate)
    }

    var birthDateDisplayText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "yyyy년 M월 d일"
        return df.string(from: birthDate)
    }

    // MARK: - Login

    func login() {
        isLoading = true
        errorMessage = nil

        let phoneFormatted = formatPhone(phone)

        repository.travelerLogin(
            phone: phoneFormatted,
            birthDate: birthDateString,
            inviteCode: inviteCode.trimmed
        )
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
                    print("✅ [InviteLogin] 로그인 성공 (약관 동의 필요): \(traveler.fullNameKr)")
                } else {
                    TripDataStore.shared.reload()
                    self.loginSuccess = true
                    print("✅ [InviteLogin] 로그인 성공: \(traveler.fullNameKr), trip: \(response.trip.title)")
                }
            },
            onFailure: { [weak self] error in
                self?.isLoading = false
                let htError = ErrorHandler.classify(error)
                if case .validationFailed(let detail) = htError {
                    self?.errorMessage = detail.userMessage ?? "입력 정보를 확인해주세요."
                } else if case .unauthorized = htError {
                    self?.errorMessage = "전화번호, 생년월일 또는 초대코드가 올바르지 않습니다."
                } else {
                    self?.errorMessage = htError.localizedDescription
                }
                print("❌ [InviteLogin] 로그인 실패: \(error)")
            }
        )
        .disposed(by: disposeBag)
    }
}
