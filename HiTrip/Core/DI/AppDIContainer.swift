import Foundation

// MARK: - AppDIContainer
/// 수동 의존성 주입(DI) 컨테이너
///
/// 의존성 조립 순서:
///   NetworkService
///     ↓
///   Repository (Protocol 구현체) — Auth / Traveler / Chat / Emergency / Spot
///     ↓
///   UseCase (Auth / Chat / Emergency / Spot)
///     ↓
///   ViewModel
///
/// TravelerRepository는 TripDataStore / ProfileViewModel / AgreementViewModel이 공유.
/// Chat은 스레드 기반 별도 패턴이므로 ChatRepository로 독립.

final class AppDIContainer {

    // MARK: - Singleton

    static let shared = AppDIContainer()

    // MARK: - Infrastructure

    private let networkService: NetworkService

    // MARK: - Repositories

    private lazy var authRepository: AuthRepositoryProtocol = {
        AuthRepository(networkService: networkService)
    }()

    /// 여행객 전용 API 저장소 — TripDataStore, ProfileVM, AgreementVM이 공유
    private lazy var travelerRepository: TravelerRepositoryProtocol = {
        TravelerRepository(networkService: networkService)
    }()


    /// 문의 스레드 + 메시지 — 스레드 기반이므로 별도 Repository
    private lazy var chatRepository: ChatRepositoryProtocol = {
        ChatRepository(networkService: networkService)
    }()

    /// 로컬 긴급 연락처 (프리셋 + 개인 저장)
    private lazy var emergencyRepository: EmergencyRepositoryProtocol = {
        EmergencyRepository()
    }()

    /// TourAPI 관광지 검색
    private lazy var spotRepository: SpotRepositoryProtocol = {
        SpotRepository()
    }()

    // MARK: - Init

    private init() {
        self.networkService = .shared
    }

    /// 테스트용 — Mock Repository 주입
    init(
        networkService: NetworkService,
        authRepository: AuthRepositoryProtocol? = nil,
        travelerRepository: TravelerRepositoryProtocol? = nil
    ) {
        self.networkService = networkService
        if let auth = authRepository     { self.authRepository     = auth }
        if let traveler = travelerRepository { self.travelerRepository = traveler }
    }

    // MARK: - Repository Access (테스트 / 직접 주입용)

    func makeTravelerRepository() -> TravelerRepositoryProtocol { travelerRepository }

    // MARK: - UseCase Factory

    func makeLoginUseCase()     -> LoginUseCase     { LoginUseCase(repository: authRepository) }
    func makeSignUpUseCase()    -> SignUpUseCase    { SignUpUseCase(repository: authRepository) }
    func makeChatUseCase()      -> ChatUseCase      { ChatUseCase(repository: chatRepository) }
    func makeEmergencyUseCase() -> EmergencyUseCase { EmergencyUseCase(repository: emergencyRepository) }
    func makeSpotUseCase()      -> SpotUseCase      { SpotUseCase(repository: spotRepository) }

    // MARK: - ViewModel Factory

    func makeLoginViewModel()    -> LoginViewModel    { LoginViewModel(loginUseCase: makeLoginUseCase()) }
    func makeSignUpViewModel()   -> SignUpViewModel   { SignUpViewModel(signUpUseCase: makeSignUpUseCase()) }
    func makeScheduleViewModel() -> ScheduleViewModel { ScheduleViewModel() }
    func makeChatViewModel()     -> ChatViewModel     { ChatViewModel(chatUseCase: makeChatUseCase()) }
    func makeEmergencyViewModel()-> EmergencyViewModel{ EmergencyViewModel(emergencyUseCase: makeEmergencyUseCase()) }
    func makeSpotViewModel()     -> SpotViewModel     { SpotViewModel(spotUseCase: makeSpotUseCase()) }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(repository: travelerRepository)
    }
}
