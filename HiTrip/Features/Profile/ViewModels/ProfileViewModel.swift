import Foundation
import Combine
import RxSwift

// MARK: - ProfileViewModel
/// 프로필 화면의 ViewModel
///
/// 1차: Keychain에서 로그인 시 저장한 유저 정보를 즉시 표시
/// 2차: 서버 GET /api/auth/profile/ 호출하여 최신 정보로 갱신
/// 프로필 수정 시 서버 PUT /api/auth/profile/ + Keychain 동기화

final class ProfileViewModel: ObservableObject {

    // MARK: - Published: 프로필 표시 데이터

    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userPhone: String = ""
    @Published var userRole: String = ""

    // MARK: - Published: 통계

    @Published var points: Int = 0
    @Published var tripCount: Int = 0
    @Published var bucketListCount: Int = 0

    // MARK: - Published: 편집 폼 상태

    @Published var editNickname: String = ""
    @Published var editBirthday: Date = Date()
    @Published var showBirthdayPicker: Bool = false
    @Published var editCountry: String = "대한민국"
    @Published var editCountryCode: String = "+82"
    @Published var editPhoneNumber: String = ""

    /// 저장 완료 알림
    @Published var showSaveAlert: Bool = false

    // MARK: - Dependencies

    private let keychain = KeychainManager.shared
    private let networkService = NetworkService.shared
    private let disposeBag = DisposeBag()

    // MARK: - Init

    init() {
        loadProfile()
    }

    // MARK: - Load Profile

    /// 1) Keychain 캐시에서 즉시 로드 (빠른 표시)
    /// 2) 서버에서 최신 프로필 가져와서 갱신
    func loadProfile() {
        // 1차: Keychain 캐시 (즉시 표시)
        userName = keychain.getUserName() ?? "사용자"
        userEmail = keychain.getUserEmail() ?? "이메일 없음"
        userRole = keychain.getUserType() ?? ""

        // 통계 데이터
        points = 50
        tripCount = TripDataStore.shared.trips.count
        bucketListCount = 200

        // 편집 폼 초기값
        editNickname = userName

        // 2차: 서버에서 최신 프로필 갱신
        fetchProfileFromServer()
    }

    /// 서버 GET /api/auth/profile/ 호출하여 최신 유저 정보로 갱신
    private func fetchProfileFromServer() {
        networkService.request(.profile(), type: ProfileDTO.self)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dto in
                    guard let self else { return }
                    let name = dto.fullNameKr ?? dto.username ?? self.userName
                    let email = dto.email ?? self.userEmail

                    // UI 갱신
                    self.userName = name
                    self.userEmail = email
                    self.userPhone = dto.phone ?? ""
                    self.userRole = dto.role ?? ""
                    self.editNickname = name
                    self.editPhoneNumber = dto.phone ?? ""

                    // Keychain 동기화 (다른 화면에서도 최신 정보 사용)
                    self.keychain.saveUserName(name)
                    self.keychain.saveUserEmail(email)
                    if let role = dto.role {
                        self.keychain.saveUserType(role)
                    }

                    print("✅ [Profile] 서버 프로필 갱신: \(name), \(email)")
                },
                onFailure: { error in
                    // 서버 실패 시 Keychain 캐시 데이터 유지 (오프라인 대응)
                    print("⚠️ [Profile] 서버 프로필 조회 실패, 캐시 사용: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Save Profile

    /// 프로필 수정 저장 — 서버 + Keychain 동기화
    func saveProfile() {
        let newName = editNickname.trimmed.isEmpty ? userName : editNickname.trimmed

        // 서버에 프로필 업데이트
        let body: [String: Any] = [
            "first_name_kr": newName,
            "phone": editPhoneNumber
        ]

        networkService.request(.profileUpdate(body: body), type: ProfileDTO.self)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dto in
                    guard let self else { return }
                    let updatedName = dto.fullNameKr ?? dto.username ?? newName
                    self.userName = updatedName
                    self.keychain.saveUserName(updatedName)
                    if let email = dto.email {
                        self.keychain.saveUserEmail(email)
                    }
                    self.showSaveAlert = true
                    print("✅ [Profile] 프로필 수정 완료: \(updatedName)")
                },
                onFailure: { [weak self] error in
                    // 서버 실패 시 로컬만 업데이트
                    print("⚠️ [Profile] 서버 프로필 수정 실패, 로컬 저장: \(error.localizedDescription)")
                    self?.userName = newName
                    self?.keychain.saveUserName(newName)
                    self?.showSaveAlert = true
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Computed

    /// 통계 표시용 포맷된 문자열
    var pointsText: String { "\(points)" }
    var tripCountText: String { "\(tripCount)" }
    var bucketListCountText: String { "\(bucketListCount)" }

    /// 생년월일 표시 텍스트
    var birthdayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: editBirthday)
    }

    /// 생년월일이 기본값(오늘)인지 여부 — placeholder 표시용
    var isBirthdayDefault: Bool {
        Calendar.current.isDateInToday(editBirthday)
    }
}
