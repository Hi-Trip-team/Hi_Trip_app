import Foundation
import Security

// MARK: - KeychainManager
/// iOS Keychain Services 래퍼
///
/// 설계 의도:
/// - 토큰(accessToken, refreshToken)은 민감 데이터이므로
///   UserDefaults가 아닌 Keychain에 암호화 저장
/// - Keychain은 iOS의 하드웨어 기반 암호화(Secure Enclave)를 활용
/// - 앱 삭제 후에도 데이터가 남을 수 있으므로 logout 시 명시적 삭제 필요
///
/// 면접 포인트:
/// "왜 UserDefaults 대신 Keychain을 쓰셨나요?"
/// → "UserDefaults는 plist 파일로 평문 저장되어 탈옥된 기기에서 읽힐 수 있습니다.
///    Keychain은 iOS의 하드웨어 기반 암호화를 사용하므로
///    토큰 같은 민감 데이터에 적합합니다."
///
/// Keychain API 흐름:
/// - 저장: SecItemAdd (기존 값 삭제 후 추가)
/// - 조회: SecItemCopyMatching
/// - 삭제: SecItemDelete

final class KeychainManager {

    // MARK: - Singleton

    static let shared = KeychainManager()

    // MARK: - Keychain Key 상수

    /// 키 이름에 번들 ID prefix를 붙여 다른 앱과 충돌 방지
    private enum Keys {
        static let accessToken  = "com.hitrip.accessToken"
        static let refreshToken = "com.hitrip.refreshToken"
        static let userId       = "com.hitrip.userId"
        static let userType     = "com.hitrip.userType"
        static let userName     = "com.hitrip.userName"
        static let userEmail    = "com.hitrip.userEmail"
        static let tokenExpiry  = "com.hitrip.tokenExpiry"
    }

    /// 자동 로그인 체크 여부 — 민감정보가 아니라 UserDefaults에 둡니다.
    /// 앱을 지웠다 깔면 UserDefaults만 사라지므로, 남은 Keychain 토큰도 자동 로그인하지 않습니다.
    private static let autoLoginDefaultsKey = "com.hitrip.autoLogin"

    private init() {}

    // MARK: - Token CRUD

    /// Access Token 저장
    func saveToken(_ token: String) {
        save(key: Keys.accessToken, value: token)
    }

    /// Access Token 조회 (nil이면 미로그인 상태)
    func getToken() -> String? {
        load(key: Keys.accessToken)
    }

    // MARK: - User Info

    func saveUserId(_ id: String) {
        save(key: Keys.userId, value: id)
    }

    func getUserId() -> String? {
        load(key: Keys.userId)
    }

    func saveUserType(_ type: String) {
        save(key: Keys.userType, value: type)
    }

    func getUserType() -> String? {
        load(key: Keys.userType)
    }

    func saveUserName(_ name: String) {
        save(key: Keys.userName, value: name)
    }

    func getUserName() -> String? {
        load(key: Keys.userName)
    }

    func saveUserEmail(_ email: String) {
        save(key: Keys.userEmail, value: email)
    }

    // MARK: - 토큰 만료 / 자동 로그인

    /// 관광객 토큰 만료 시각 (서버 expires_at, ISO8601) — 여행 종료 + 3일
    func saveTokenExpiry(_ iso8601: String) {
        save(key: Keys.tokenExpiry, value: iso8601)
    }

    func getTokenExpiry() -> Date? {
        guard let raw = load(key: Keys.tokenExpiry) else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: raw) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: raw)
    }

    var isAutoLoginEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.autoLoginDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.autoLoginDefaultsKey) }
    }

    // MARK: - 로그인 상태 확인

    /// Access Token 존재 여부로 로그인 상태 판단
    var isLoggedIn: Bool {
        getToken() != nil
    }

    // MARK: - 전체 삭제 (로그아웃)

    /// 저장된 모든 인증 정보 삭제
    func clearAll() {
        [Keys.accessToken, Keys.refreshToken, Keys.userId, Keys.userType,
         Keys.userName, Keys.userEmail, Keys.tokenExpiry]
            .forEach { delete(key: $0) }
    }

    // MARK: - Private: Keychain CRUD 구현

    /// Keychain에 문자열 저장
    ///
    /// 동작 흐름:
    /// 1. String → Data 변환 (Keychain은 Data만 저장 가능)
    /// 2. 기존 값 삭제 (중복 방지 — Keychain은 같은 키에 중복 저장 허용)
    /// 3. SecItemAdd로 새 값 저장
    ///
    /// kSecAttrAccessible 옵션:
    /// - kSecAttrAccessibleAfterFirstUnlock: 첫 잠금 해제 후 접근 가능
    ///   → 백그라운드에서도 토큰 사용 가능 (푸시 처리 등)
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key) // 기존 값 삭제 후 저장

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Keychain에서 문자열 조회
    ///
    /// kSecReturnData: true → 실제 데이터 반환
    /// kSecMatchLimit: kSecMatchLimitOne → 하나만 반환 (여러 개일 때 첫 번째)
    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Keychain에서 항목 삭제
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
