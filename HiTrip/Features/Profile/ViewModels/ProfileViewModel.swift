import Foundation
import Combine

// MARK: - ProfileViewModel
/// 프로필 화면의 ViewModel
///
/// 유저 정보(이름, 이메일)와 통계 수치를 중앙 관리.
/// KeychainManager에서 유저 기본 정보를 읽고,
/// 프로필 수정 시 저장까지 담당한다.
///
/// 추후 API 연동 시 UserRepository를 주입받아
/// 서버에서 프로필 데이터를 fetch/update하도록 확장한다.

final class ProfileViewModel: ObservableObject {

    // MARK: - Published: 프로필 표시 데이터

    @Published var userName: String = ""
    @Published var userEmail: String = ""

    // MARK: - Published: 통계 (추후 API로 대체)

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

    // MARK: - Init

    init() {
        loadProfile()
    }

    // MARK: - Load Profile

    /// Keychain + Mock 통계 데이터 로드
    /// 추후 API 연동 시 이 메서드 내부를 서버 호출로 교체
    func loadProfile() {
        // 유저 기본 정보 (Keychain에서 읽기)
        userName = keychain.getUserName() ?? keychain.getUserId() ?? "사용자"
        userEmail = keychain.getUserEmail() ?? "이메일 없음"

        // 통계 데이터 (추후 API 응답으로 대체)
        // TODO: UserRepository.fetchStats() → points, tripCount, bucketListCount
        points = 50
        tripCount = TripDataStore.shared.trips.count
        bucketListCount = 200

        // 편집 폼 초기값 세팅
        editNickname = userName
    }

    // MARK: - Save Profile

    /// 프로필 수정 저장
    /// 추후 API 연동 시 UserRepository.updateProfile()로 교체
    func saveProfile() {
        // Keychain에 업데이트
        if !editNickname.trimmed.isEmpty {
            keychain.saveUserName(editNickname.trimmed)
        }

        // 로컬 상태 반영
        userName = editNickname.trimmed.isEmpty ? userName : editNickname.trimmed

        // TODO: API 연동 시 서버에도 저장
        // userRepository.updateProfile(nickname: editNickname, birthday: editBirthday, ...)

        showSaveAlert = true
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
