import Foundation
import RxSwift

// MARK: - HiTripAPIService
/// Hi Trip 자체 백엔드 API 호출 서비스
///
/// NetworkService를 래핑하여 도메인별 편의 메서드를 제공.
/// ViewModel이나 UseCase에서 직접 사용하거나,
/// Repository에서 호출할 수 있다.
///
/// TourAPIService가 한국관광공사 API 전용이라면,
/// 이 서비스는 Hi Trip 자체 백엔드 전용.

final class HiTripAPIService {

    // MARK: - Singleton

    static let shared = HiTripAPIService()

    private let network: NetworkService

    private init() {
        self.network = .shared
    }

    /// 테스트용
    init(networkService: NetworkService) {
        self.network = networkService
    }

    // MARK: - Trips

    /// 여행 목록 조회
    func fetchTrips() -> Single<[TripDTO]> {
        network.request(.tripsList(), type: [TripDTO].self)
            .catch { error in
                print("❌ [HiTrip API] fetchTrips 실패: \(error.localizedDescription)")
                return .just([])
            }
    }

    /// 여행 상세 조회
    func fetchTrip(id: Int) -> Single<TripDTO> {
        network.request(.tripsRetrieve(id: id), type: TripDTO.self)
    }

    // MARK: - Schedules

    /// 특정 여행의 일정 목록 조회
    func fetchSchedules(tripPk: Int) -> Single<[ScheduleDTO]> {
        network.request(.schedulesList(tripPk: tripPk), type: [ScheduleDTO].self)
            .catch { error in
                print("❌ [HiTrip API] fetchSchedules 실패: \(error.localizedDescription)")
                return .just([])
            }
    }

    // MARK: - Places

    /// 장소 목록 조회
    func fetchPlaces() -> Single<[PlaceDTO]> {
        network.request(.placesList(), type: [PlaceDTO].self)
            .catch { error in
                print("❌ [HiTrip API] fetchPlaces 실패: \(error.localizedDescription)")
                return .just([])
            }
    }

    /// 장소 상세 조회
    func fetchPlace(id: Int) -> Single<PlaceDTO> {
        network.request(.placesRetrieve(id: id), type: PlaceDTO.self)
    }

    // MARK: - Recommendations

    /// AI 추천 장소 목록
    func fetchRecommendations() -> Single<[RecommendationDTO]> {
        network.request(.recommendationsList(), type: [RecommendationDTO].self)
            .catch { error in
                print("❌ [HiTrip API] fetchRecommendations 실패: \(error.localizedDescription)")
                return .just([])
            }
    }

    // MARK: - Categories

    /// 카테고리 목록 조회
    func fetchCategories() -> Single<[CategoryDTO]> {
        network.request(.categoriesList(), type: [CategoryDTO].self)
            .catch { error in
                print("❌ [HiTrip API] fetchCategories 실패: \(error.localizedDescription)")
                return .just([])
            }
    }

    // MARK: - Auth

    /// 로그인
    func login(username: String, password: String) -> Single<AuthLoginResponse> {
        network.request(.login(username: username, password: password), type: AuthLoginResponse.self)
    }

    /// 프로필 조회
    func fetchProfile() -> Single<ProfileDTO> {
        network.request(.profile(), type: ProfileDTO.self)
    }

    /// 회원가입
    func register(username: String, password: String, email: String) -> Single<ProfileDTO> {
        network.request(.register(username: username, password: password, email: email), type: ProfileDTO.self)
    }

    // MARK: - Health

    /// 서버 상태 확인
    func healthCheck() -> Single<[String: String]> {
        network.request(
            APIEndpoint(path: "/api/health/"),
            type: [String: String].self
        )
        .catch { _ in .just(["status": "unreachable"]) }
    }
}
