import Foundation
import Combine
import RxSwift

// MARK: - ProfileViewModel
/// 프로필 화면 ViewModel
///
/// 데이터 흐름:
///   1차) Keychain 캐시 → 즉시 표시
///   2차) TravelerRepository.fetchMe() → 서버 최신값으로 갱신
///
/// 로그아웃도 Repository를 통해 POST /api/traveler/logout/ 호출.

final class ProfileViewModel: ObservableObject {

    // MARK: - Published

    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userPhone: String = ""
    @Published var userBirthDate: String = ""
    @Published var userGender: String = ""
    @Published var tripCount: Int = 0
    @Published var managerName: String = ""

    @Published var paymentStatusDisplay: String = ""
    @Published var docStatusDisplay: String = ""
    @Published var passportVerified: Bool = false
    @Published var bookingVerified: Bool = false
    @Published var totalAmount: Int = 0
    @Published var paidAmount: Int = 0

    // MARK: - Dependencies

    private let repository: TravelerRepositoryProtocol
    private let keychain: KeychainManager
    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(
        repository: TravelerRepositoryProtocol = APIEnvironment.current.useMock ? MockTravelerRepository() : TravelerRepository(),
        keychain: KeychainManager = .shared
    ) {
        self.repository = repository
        self.keychain = keychain
        loadProfile()
    }

    // MARK: - Load

    func loadProfile() {
        // 1차: Keychain 캐시 즉시 표시
        userName = keychain.getUserName() ?? "여행자"
        userEmail = keychain.getUserEmail() ?? ""
        tripCount = TripDataStore.shared.trips.isEmpty ? 0 : 1

        // 2차: 서버 최신값 갱신
        fetchRemoteProfile()
    }

    private func fetchRemoteProfile() {
        repository.fetchMe()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] me in
                    guard let self else { return }
                    let t = me.traveler

                    self.userName = t.fullNameKr
                    self.userEmail = t.email
                    self.userPhone = t.phone
                    self.userBirthDate = t.birthDate
                    self.userGender = t.gender == "M" ? "남성" : t.gender == "F" ? "여성" : ""
                    self.totalAmount = t.totalAmount
                    self.paidAmount = t.paidAmount
                    self.passportVerified = t.passportVerified
                    self.bookingVerified = t.bookingVerified
                    self.paymentStatusDisplay = t.paymentStatusDisplay
                    self.docStatusDisplay = t.docStatusDisplay
                    self.managerName = me.trip.managerName ?? ""

                    self.keychain.saveUserName(t.fullNameKr)
                    self.keychain.saveUserEmail(t.email)
                    print("✅ [Profile] 프로필 갱신: \(t.fullNameKr)")
                },
                onFailure: { error in
                    print("⚠️ [Profile] 프로필 조회 실패, 캐시 사용: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Logout

    func logout(completion: @escaping () -> Void) {
        repository.logout()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.clearLocalData()
                    completion()
                    print("✅ [Profile] 로그아웃 완료")
                },
                onFailure: { [weak self] _ in
                    // 서버 오류여도 로컬 클리어
                    self?.clearLocalData()
                    completion()
                    print("⚠️ [Profile] 서버 로그아웃 실패, 로컬 클리어")
                }
            )
            .disposed(by: disposeBag)
    }

    private func clearLocalData() {
        keychain.clearAll()
        TripDataStore.shared.clear()
    }

    // MARK: - Computed

    var tripCountText: String { "\(tripCount)" }

    var paymentSummaryText: String {
        guard totalAmount > 0 else { return "" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        let total = fmt.string(from: NSNumber(value: totalAmount)) ?? "\(totalAmount)"
        let paid  = fmt.string(from: NSNumber(value: paidAmount))  ?? "\(paidAmount)"
        return "\(paid)원 / \(total)원"
    }

    var birthDateDisplayText: String {
        guard !userBirthDate.isEmpty else { return "" }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let date = df.date(from: userBirthDate) else { return userBirthDate }
        df.dateFormat = "yyyy년 M월 d일"
        df.locale = Locale(identifier: "ko_KR")
        return df.string(from: date)
    }
}
