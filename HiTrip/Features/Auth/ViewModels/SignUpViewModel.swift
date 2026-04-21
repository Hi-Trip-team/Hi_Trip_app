import Foundation
import RxSwift
import RxCocoa

// MARK: - SignUpViewModel
/// 회원가입 5단계 플로우 관리 ViewModel
///
/// 회원가입 단계 (피그마 기준):
/// ```
/// Step 1: 닉네임 설정 → 중복 확인 API
/// Step 2: 아이디 설정 → 중복 확인 API
/// Step 3: 비밀번호 설정 → 일치 검증 → 회원가입 API
/// Step 4: 약관 동의 → 필수 약관 체크
///       → 완료 화면
/// ```
///
/// 설계 포인트:
/// - 각 단계의 입력값을 @Published로 관리
/// - currentStep으로 단계 전환 (SwiftUI 애니메이션 연동)
/// - 뒤로가기 시 이전 단계로 복귀 (입력값 유지)

final class SignUpViewModel: ObservableObject {

    // MARK: - Step 정의

    /// 회원가입 단계 enum
    /// 피그마 순서: 닉네임 → 아이디 → 비밀번호 → 약관 → 완료
    enum Step: Int, CaseIterable, Equatable {
        case nickname = 0   // 닉네임 설정
        case userId = 1     // 아이디 설정
        case password = 2   // 비밀번호 설정
        case terms = 3      // 약관 동의
        case complete = 4   // 가입 완료

        /// 프로그레스 바 진행률 (0.0 ~ 1.0)
        var progress: Double {
            if self == .complete { return 1.0 }
            return Double(rawValue) / Double(Step.allCases.count - 1)
        }

        /// 각 단계의 타이틀 (네비게이션 바에 표시)
        var title: String {
            switch self {
            case .nickname: return "닉네임 설정"
            case .userId:   return "아이디 설정"
            case .password: return "비밀번호 설정"
            case .terms:    return "약관 동의"
            case .complete: return "가입 완료"
            }
        }
    }

    // MARK: - Flow State (단계 관리)

    @Published var currentStep: Step = .nickname

    // MARK: - Step 1: 닉네임

    @Published var nickname: String = ""
    @Published var isNicknameChecked: Bool = false
    @Published var nicknameMessage: String?
    @Published var isNicknameAvailable: Bool = false

    // MARK: - Step 2: 아이디

    @Published var userId: String = ""
    /// 아이디 중복 확인 완료 여부
    @Published var isUserIdChecked: Bool = false
    /// 아이디 상태 메시지 ("사용 가능한 아이디입니다" 등)
    @Published var userIdMessage: String?
    /// 아이디가 사용 가능한지 여부 (메시지 색상 결정용)
    @Published var isUserIdAvailable: Bool = false

    // MARK: - Step 3: 비밀번호

    @Published var password: String = ""
    @Published var passwordConfirm: String = ""

    // MARK: - Step 4: 약관 동의

    @Published var agreeAll: Bool = false
    @Published var agreeService: Bool = false
    @Published var agreePrivacy: Bool = false
    @Published var agreeMarketing: Bool = false

    // MARK: - Common State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var signUpCompleted: Bool = false

    // MARK: - Dependencies

    private let signUpUseCase: SignUpUseCase
    private let disposeBag = DisposeBag()

    init(signUpUseCase: SignUpUseCase) {
        self.signUpUseCase = signUpUseCase
    }

    // MARK: - Step Navigation

    func goToNextStep() {
        guard let nextRaw = Step(rawValue: currentStep.rawValue + 1) else { return }
        errorMessage = nil
        currentStep = nextRaw
    }

    func goToPreviousStep() {
        guard let prevRaw = Step(rawValue: currentStep.rawValue - 1) else { return }
        errorMessage = nil
        currentStep = prevRaw
    }

    // MARK: - Step 1: 닉네임 중복 확인

    func resetNicknameCheck() {
        isNicknameChecked = false
        isNicknameAvailable = false
        nicknameMessage = nil
    }

    func checkNickname() {
        isLoading = true
        errorMessage = nil

        // TODO: 백엔드 연동 시 실제 닉네임 중복 확인 API 호출
        // 현재는 Mock으로 항상 사용 가능 처리 (UI 확인용)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.isNicknameChecked = true
            self?.isNicknameAvailable = true
            self?.nicknameMessage = "사용 가능한 닉네임입니다."
        }

        // ── 원본 API 호출 코드 (백엔드 연동 시 위 Mock 삭제 후 아래 주석 해제) ──
        // signUpUseCase.checkNickname(nickname)
        //     .observe(on: MainScheduler.instance)
        //     .subscribe(
        //         onSuccess: { [weak self] response in
        //             self?.isLoading = false
        //             self?.isNicknameChecked = true
        //             self?.isNicknameAvailable = response.isAvailable
        //             if response.isAvailable {
        //                 self?.nicknameMessage = "사용 가능한 닉네임입니다."
        //             } else {
        //                 self?.nicknameMessage = "이미 사용 중인 닉네임입니다."
        //             }
        //         },
        //         onFailure: { [weak self] error in
        //             self?.isLoading = false
        //             self?.isNicknameChecked = false
        //             self?.isNicknameAvailable = false
        //             self?.nicknameMessage = error.localizedDescription
        //         }
        //     )
        //     .disposed(by: disposeBag)
    }

    // MARK: - Step 2: 아이디 중복 확인

    /// 아이디 변경 시 확인 상태 초기화
    func resetUserIdCheck() {
        isUserIdChecked = false
        isUserIdAvailable = false
        userIdMessage = nil
    }

    /// 아이디 중복 확인 API 호출
    /// 닉네임 중복 확인과 동일한 패턴
    func checkUserId() {
        guard isUserIdFormatValid else { return }

        isLoading = true
        errorMessage = nil

        // TODO: 백엔드 연동 시 실제 아이디 중복 확인 API 호출
        // 현재는 Mock으로 항상 사용 가능 처리
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.isUserIdChecked = true
            self?.isUserIdAvailable = true
            self?.userIdMessage = "사용 가능한 아이디입니다."
        }
    }

    /// 아이디 형식 유효성 (4자 이상)
    var isUserIdFormatValid: Bool {
        !userId.trimmed.isEmpty && userId.trimmed.count >= 4
    }

    // MARK: - Step 3: 비밀번호 유효성

    /// 비밀번호 유효성 (영문, 숫자, 특수문자 포함 8자 이상)
    var isPasswordValid: Bool {
        password.count >= 8
    }

    /// 비밀번호 확인 일치 여부
    var isPasswordMatch: Bool {
        !passwordConfirm.isEmpty && password == passwordConfirm
    }

    /// 비밀번호 단계 전체 유효성
    var isPasswordStepValid: Bool {
        isPasswordValid && isPasswordMatch
    }

    // MARK: - Step 4: 약관 동의 로직

    func toggleAgreeAll() {
        agreeAll.toggle()
        agreeService = agreeAll
        agreePrivacy = agreeAll
        agreeMarketing = agreeAll
    }

    func updateAgreeAll() {
        agreeAll = agreeService && agreePrivacy && agreeMarketing
    }

    var isRequiredTermsAgreed: Bool {
        agreeService && agreePrivacy
    }

    // MARK: - 회원가입 실행

    /// 약관 동의 후 최종 회원가입 API 호출
    func signUp() {
        isLoading = true
        errorMessage = nil

        // TODO: 백엔드 연동 시 실제 회원가입 API 호출
        // 현재는 Mock으로 항상 성공 처리 (UI 확인용)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            self?.signUpCompleted = true
            self?.currentStep = .complete
        }

        // ── 원본 API 호출 코드 (백엔드 연동 시 위 Mock 삭제 후 아래 주석 해제) ──
        // signUpUseCase.execute(
        //     nickname: nickname,
        //     userId: userId,
        //     password: password,
        //     passwordConfirm: passwordConfirm
        // )
        // .observe(on: MainScheduler.instance)
        // .subscribe(
        //     onSuccess: { [weak self] _ in
        //         self?.isLoading = false
        //         self?.signUpCompleted = true
        //         self?.currentStep = .complete
        //     },
        //     onFailure: { [weak self] error in
        //         self?.isLoading = false
        //         self?.errorMessage = error.localizedDescription
        //     }
        // )
        // .disposed(by: disposeBag)
    }
}
