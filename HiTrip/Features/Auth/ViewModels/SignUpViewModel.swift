import Foundation
import RxSwift
import RxCocoa

// MARK: - SignUpViewModel
/// 회원가입 4단계 플로우 관리 ViewModel
///
/// 회원가입 단계:
/// ```
/// Step 1: 닉네임 설정 → 중복 확인 API
/// Step 2: 약관 동의 → 필수 약관 체크
/// Step 3: 아이디 설정 → 길이 검증
/// Step 4: 비밀번호 설정 → 일치 검증 → 회원가입 API
///       → 완료 화면
/// ```
///
/// 설계 포인트:
/// - 각 단계의 입력값을 @Published로 관리
/// - currentStep으로 단계 전환 (SwiftUI 애니메이션 연동)
/// - 뒤로가기 시 이전 단계로 복귀 (입력값 유지)
///
/// 면접 포인트:
/// "멀티스텝 폼을 어떻게 관리하셨나요?"
/// → "하나의 ViewModel에서 모든 단계의 상태를 관리합니다.
///    각 단계는 enum Step으로 구분하고, @Published currentStep을
///    변경하면 SwiftUI가 자동으로 해당 단계 View를 렌더링합니다.
///    뒤로가기 시 입력값이 사라지지 않도록 ViewModel이 데이터를 보존합니다."

final class SignUpViewModel: ObservableObject {

    // MARK: - Step 정의

    /// 회원가입 단계 enum
    /// - CaseIterable: 전체 단계 수 계산용 (프로그레스 바)
    /// - Equatable: SwiftUI .animation에서 값 변화 감지용
    enum Step: Int, CaseIterable, Equatable {
        case nickname = 0   // 닉네임 설정
        case terms = 1      // 약관 동의
        case userId = 2     // 아이디 설정
        case password = 3   // 비밀번호 설정
        case complete = 4   // 가입 완료

        /// 프로그레스 바 진행률 (0.0 ~ 1.0)
        /// complete 단계는 1.0 (100%)
        var progress: Double {
            if self == .complete { return 1.0 }
            return Double(rawValue) / Double(Step.allCases.count - 1)
        }

        /// 각 단계의 타이틀 (네비게이션 바에 표시)
        var title: String {
            switch self {
            case .nickname: return "닉네임 설정"
            case .terms:    return "약관 동의"
            case .userId:   return "아이디 설정"
            case .password: return "비밀번호 설정"
            case .complete: return "가입 완료"
            }
        }
    }

    // MARK: - Flow State (단계 관리)

    /// 현재 단계 — View에서 이 값을 관찰하여 화면 전환
    @Published var currentStep: Step = .nickname

    // MARK: - Step 1: 닉네임

    @Published var nickname: String = ""
    /// 닉네임 중복 확인 완료 여부
    /// - true: 서버에서 사용 가능 확인됨 → "다음" 버튼 활성화
    /// - false: 아직 확인 안 됨 또는 중복
    @Published var isNicknameChecked: Bool = false
    /// 닉네임 상태 메시지 ("사용 가능한 닉네임입니다" 등)
    @Published var nicknameMessage: String?
    /// 닉네임이 사용 가능한지 여부 (메시지 색상 결정용)
    @Published var isNicknameAvailable: Bool = false

    // MARK: - Step 2: 약관 동의

    /// 전체 동의 토글
    @Published var agreeAll: Bool = false
    /// [필수] 서비스 이용약관
    @Published var agreeService: Bool = false
    /// [필수] 개인정보 수집 및 이용
    @Published var agreePrivacy: Bool = false
    /// [선택] 마케팅 정보 수신
    @Published var agreeMarketing: Bool = false

    // MARK: - Step 3: 아이디

    @Published var userId: String = ""

    // MARK: - Step 4: 비밀번호

    @Published var password: String = ""
    @Published var passwordConfirm: String = ""

    // MARK: - Common State (공통 UI 상태)

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var signUpCompleted: Bool = false

    // MARK: - Dependencies

    private let signUpUseCase: SignUpUseCase
    private let disposeBag = DisposeBag()

    init(signUpUseCase: SignUpUseCase) {
        self.signUpUseCase = signUpUseCase
    }

    // MARK: - Step Navigation (단계 이동)

    /// 다음 단계로 이동
    /// - complete 단계에서는 더 이상 진행하지 않음
    func goToNextStep() {
        guard let nextRaw = Step(rawValue: currentStep.rawValue + 1) else { return }
        errorMessage = nil
        currentStep = nextRaw
    }

    /// 이전 단계로 이동
    /// - nickname(첫 단계)에서는 더 이상 뒤로가지 않음
    /// - 에러 메시지 초기화
    func goToPreviousStep() {
        guard let prevRaw = Step(rawValue: currentStep.rawValue - 1) else { return }
        errorMessage = nil
        currentStep = prevRaw
    }

    // MARK: - Step 1: 닉네임 중복 확인

    /// 닉네임 변경 시 확인 상태 초기화
    /// - 사용자가 닉네임을 수정하면 이전 확인 결과 무효화
    /// - View의 .onChange(of: nickname)에서 호출
    func resetNicknameCheck() {
        isNicknameChecked = false
        isNicknameAvailable = false
        nicknameMessage = nil
    }

    /// 닉네임 중복 확인 API 호출
    ///
    /// 동작 흐름:
    /// 1. UseCase.checkNickname() → 입력 검증 + API 호출
    /// 2. 성공 → isAvailable 확인 → 메시지 표시
    /// 3. 실패 → 에러 메시지 표시
    func checkNickname() {
        isLoading = true
        errorMessage = nil

        signUpUseCase.checkNickname(nickname)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] response in
                    self?.isLoading = false
                    self?.isNicknameChecked = true
                    self?.isNicknameAvailable = response.isAvailable

                    if response.isAvailable {
                        self?.nicknameMessage = "사용 가능한 닉네임입니다."
                    } else {
                        self?.nicknameMessage = "이미 사용 중인 닉네임입니다."
                    }
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.isNicknameChecked = false
                    self?.isNicknameAvailable = false
                    self?.nicknameMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Step 2: 약관 동의 로직

    /// "전체 동의" 토글 시 호출
    /// - true: 모든 약관 체크
    /// - false: 모든 약관 해제
    func toggleAgreeAll() {
        agreeAll.toggle()
        agreeService = agreeAll
        agreePrivacy = agreeAll
        agreeMarketing = agreeAll
    }

    /// 개별 약관 토글 시 호출
    /// - 모든 개별 약관이 체크되면 agreeAll도 자동으로 true
    /// - 하나라도 해제되면 agreeAll은 false
    func updateAgreeAll() {
        agreeAll = agreeService && agreePrivacy && agreeMarketing
    }

    /// 필수 약관이 모두 동의되었는지 확인
    /// - 서비스 이용약관 + 개인정보 수집 = 필수
    /// - 마케팅은 선택이므로 체크하지 않아도 통과
    var isRequiredTermsAgreed: Bool {
        agreeService && agreePrivacy
    }

    // MARK: - Step 3: 아이디 유효성

    /// 아이디 유효성 검사
    /// - 비어있지 않고, 4자 이상이면 유효
    var isUserIdValid: Bool {
        !userId.trimmed.isEmpty && userId.trimmed.count >= 4
    }

    // MARK: - Step 4: 비밀번호 유효성

    /// 비밀번호 유효성 (6자 이상)
    var isPasswordValid: Bool {
        password.count >= 6
    }

    /// 비밀번호 확인 일치 여부
    var isPasswordMatch: Bool {
        !passwordConfirm.isEmpty && password == passwordConfirm
    }

    /// 비밀번호 단계 전체 유효성
    var isPasswordStepValid: Bool {
        isPasswordValid && isPasswordMatch
    }

    // MARK: - 회원가입 실행

    /// 최종 회원가입 API 호출
    ///
    /// 동작 흐름:
    /// 1. SignUpUseCase.execute() → 전체 입력값 검증 + API 호출
    /// 2. 성공 → signUpCompleted = true → complete 단계로 이동
    /// 3. 실패 → errorMessage 표시 (현재 단계 유지)
    func signUp() {
        isLoading = true
        errorMessage = nil

        signUpUseCase.execute(
            nickname: nickname,
            userId: userId,
            password: password,
            passwordConfirm: passwordConfirm
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] _ in
                self?.isLoading = false
                self?.signUpCompleted = true
                self?.currentStep = .complete
            },
            onFailure: { [weak self] error in
                self?.isLoading = false
                self?.errorMessage = error.localizedDescription
            }
        )
        .disposed(by: disposeBag)
    }
}
