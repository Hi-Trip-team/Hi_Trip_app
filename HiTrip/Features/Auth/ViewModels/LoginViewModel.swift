import Foundation
import RxSwift
import RxCocoa

// MARK: - LoginViewModel
/// 로그인 화면의 ViewModel
///
/// 두 가지 바인딩 방식을 모두 지원:
/// 1. RxSwift Input/Output 패턴 — UIKit 또는 RxCocoa 기반 View에서 사용
/// 2. SwiftUI @Published 바인딩 — SwiftUI View에서 직접 사용
///
/// 면접 포인트:
/// "Input/Output 패턴이 뭔가요?"
/// → "ViewModel의 입력(사용자 액션)과 출력(UI 상태)을 struct로 명시적으로 분리하여
///    단방향 데이터 흐름을 만드는 패턴입니다.
///    View → Input → transform → Output → View 순서로 흐릅니다."

final class LoginViewModel: ObservableObject {

    // MARK: - RxSwift Input/Output

    /// View에서 들어오는 사용자 액션
    struct Input {
        let idText: Observable<String>          // ID 텍스트 변화
        let passwordText: Observable<String>    // 비밀번호 텍스트 변화
        let loginTapped: Observable<Void>       // 로그인 버튼 탭
    }

    /// View에 전달할 UI 상태
    struct Output {
        let isLoginEnabled: Driver<Bool>        // 로그인 버튼 활성화 여부
        let isLoading: Driver<Bool>             // 로딩 인디케이터
        let errorMessage: Driver<String?>       // 에러 메시지 (nil이면 숨김)
        let loginSuccess: Driver<UserInfo>      // 로그인 성공 시 유저 정보
    }

    // MARK: - SwiftUI @Published Properties

    @Published var id: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var loginSuccess: Bool = false

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCase
    private let disposeBag = DisposeBag()

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    // MARK: - RxSwift Transform

    /// Input을 받아서 Output으로 변환
    ///
    /// 동작 흐름:
    /// 1. idText + passwordText 결합 → 둘 다 비어있지 않으면 버튼 활성화
    /// 2. loginTapped → 최신 id/pw 가져와서 UseCase 호출
    /// 3. 성공 → loginSuccess 방출, 실패 → errorMessage 방출
    ///
    /// Driver를 사용하는 이유:
    /// - MainScheduler에서 방출 보장 (UI 업데이트 안전)
    /// - error 이벤트가 없음 (스트림 끊김 방지)
    /// - replay(1)로 구독 즉시 마지막 값 전달
    func transform(input: Input) -> Output {
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = BehaviorRelay<String?>(value: nil)
        let loginSuccess = PublishRelay<UserInfo>()

        // 버튼 활성화: ID, PW 모두 입력되었을 때
        let isLoginEnabled = Observable
            .combineLatest(input.idText, input.passwordText)
            .map { !$0.0.trimmed.isEmpty && !$0.1.trimmed.isEmpty }
            .asDriver(onErrorJustReturn: false)

        // 로그인 실행
        input.loginTapped
            .withLatestFrom(
                Observable.combineLatest(input.idText, input.passwordText)
            )
            .do(onNext: { _ in
                isLoading.accept(true)
                errorMessage.accept(nil)
            })
            .flatMapLatest { [weak self] id, pw -> Observable<UserInfo> in
                guard let self else { return .empty() }
                return self.loginUseCase.execute(id: id, password: pw)
                    .asObservable()
                    .catch { error in
                        errorMessage.accept(error.localizedDescription)
                        isLoading.accept(false)
                        return .empty()
                    }
            }
            .do(onNext: { _ in isLoading.accept(false) })
            .bind(to: loginSuccess)
            .disposed(by: disposeBag)

        return Output(
            isLoginEnabled: isLoginEnabled,
            isLoading: isLoading.asDriver(),
            errorMessage: errorMessage.asDriver(),
            loginSuccess: loginSuccess.asDriver(onErrorDriveWith: .empty())
        )
    }

    // MARK: - SwiftUI 직접 호출

    /// SwiftUI View에서 버튼 탭 시 호출
    ///
    /// RxSwift transform과 동일한 로직을 @Published로 구현:
    /// - isLoading → ProgressView 표시
    /// - errorMessage → 에러 텍스트 표시
    /// - loginSuccess → AppRouter가 화면 전환
    func login() {
        isLoading = true
        errorMessage = nil

        loginUseCase.execute(id: id, password: password)
            .observe(on: MainScheduler.instance) // UI 업데이트는 반드시 메인 스레드
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    self?.loginSuccess = true
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }
}
