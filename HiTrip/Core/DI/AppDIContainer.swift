import Foundation

// MARK: - AppDIContainer
/// 수동 의존성 주입(DI) 컨테이너
///
/// 설계 의도:
/// - Swinject 같은 DI 프레임워크 없이 Swift 생성자 주입으로 구현
/// - 모든 의존성 생성과 조립을 한 곳에서 관리
///
/// 의존성 조립 순서 (아래에서 위로):
/// ```
/// NetworkService (싱글턴)
///      ↓
/// AuthRepository (Protocol 구현체)
///      ↓
/// LoginUseCase / SignUpUseCase (비즈니스 로직)
///      ↓
/// LoginViewModel / SignUpViewModel (UI 바인딩)
/// ```
///
/// 면접 포인트:
/// "왜 Swinject를 안 쓰셨나요?"
/// → "의존성 주입의 원리를 직접 이해하기 위해 수동 구현했습니다.
///    프레임워크 없이도 Protocol + Init Injection으로
///    충분히 깔끔하게 DI를 구성할 수 있습니다."
///
/// "DI Container의 장점은 무엇인가요?"
/// → "객체 생성 로직을 한 곳에 모아서:
///    1) 의존성 그래프를 한눈에 파악 가능
///    2) 테스트 시 Mock으로 쉽게 교체
///    3) 객체 생명주기(싱글턴 vs 매번 생성) 중앙 관리"

final class AppDIContainer {

    // MARK: - Singleton (프로덕션)

    static let shared = AppDIContainer()

    // MARK: - Infrastructure

    private let networkService: NetworkService

    // MARK: - Repositories (lazy: 필요할 때 생성)

    /// lazy var + Protocol 타입으로 선언
    /// → 실제 타입(AuthRepository)은 초기화 시점에만 노출
    private lazy var authRepository: AuthRepositoryProtocol = {
        AuthRepository(networkService: networkService)
    }()

    /// 일정 Repository — 현재 메모리 저장, 나중에 서버 연동으로 교체
    private lazy var scheduleRepository: ScheduleRepositoryProtocol = {
        ScheduleRepository()
    }()

    // MARK: - Init

    /// 프로덕션용 — 싱글턴으로만 사용
    private init() {
        self.networkService = .shared
    }

    /// 테스트용 — Mock 의존성 주입
    ///
    /// 사용 예시:
    /// ```
    /// let mockRepo = MockAuthRepository()
    /// let container = AppDIContainer(
    ///     networkService: NetworkService(baseURL: "http://test"),
    ///     authRepository: mockRepo
    /// )
    /// let viewModel = container.makeLoginViewModel()
    /// ```
    init(
        networkService: NetworkService,
        authRepository: AuthRepositoryProtocol? = nil
    ) {
        self.networkService = networkService
        if let authRepository {
            self.authRepository = authRepository
        }
    }

    // MARK: - UseCase Factory

    func makeLoginUseCase() -> LoginUseCase {
        LoginUseCase(repository: authRepository)
    }

    func makeSignUpUseCase() -> SignUpUseCase {
        SignUpUseCase(repository: authRepository)
    }

    func makeScheduleUseCase() -> ScheduleUseCase {
        ScheduleUseCase(repository: scheduleRepository)
    }

    // MARK: - ViewModel Factory

    /// RootView에서 호출하여 LoginView에 주입
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(loginUseCase: makeLoginUseCase())
    }

    /// RootView에서 호출하여 SignUpFlowView에 주입
    func makeSignUpViewModel() -> SignUpViewModel {
        SignUpViewModel(signUpUseCase: makeSignUpUseCase())
    }

    /// HomeView의 일정 탭에서 사용
    func makeScheduleViewModel() -> ScheduleViewModel {
        ScheduleViewModel(scheduleUseCase: makeScheduleUseCase())
    }
}
