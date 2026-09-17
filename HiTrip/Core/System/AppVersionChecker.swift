import Foundation

// MARK: - AppVersionChecker
/// 최소 지원 버전 확인 (스플래시)
///
/// 서버 공개 설정(`GET /api/publicdata/config/`)의 `min_ios_version`보다 설치 버전이 낮으면
/// 닫을 수 없는 업데이트 팝업을 띄웁니다.
/// 업데이트할 스토어 주소(서버 `store_url` 또는 `AppLinks.appStore`)가 없으면
/// 사용자가 앱을 쓸 수 없게 되므로 팝업을 띄우지 않습니다.
/// 설정을 못 받아온 경우(서버 오류 등)에도 앱 사용을 막지 않습니다.

enum AppVersionChecker {

    /// 설치된 앱 버전 (MARKETING_VERSION)
    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// 업데이트 팝업의 [업데이트] 버튼이 여는 주소 — 서버 값이 있으면 그 값을 씁니다
    private(set) static var storeURL: URL? = AppLinks.appStore

    /// 서버가 요구하는 최소 버전 — 받지 못하면 nil
    static func minimumVersion() async -> String? {
        await fetchConfig()?.minimumVersion
    }

    static func isUpdateRequired() async -> Bool {
        guard let config = await fetchConfig(),
              let minimum = config.minimumVersion else { return false }
        if let serverStoreURL = config.storeURL {
            storeURL = serverStoreURL
        }
        guard storeURL != nil else { return false }
        return isVersion(currentVersion, lowerThan: minimum)
    }

    /// 버전을 점 단위 숫자로 나눠 비교합니다 ("1.2.10" < "1.10.0", "1.0" == "1.0.0")
    ///
    /// 문자열 비교(.numeric)를 쓰면 짧은 쪽이 낮다고 나옵니다.
    /// 앱 버전이 "1.0", 서버 최소 버전이 "1.0.0"일 때 최신 사용자에게도
    /// 강제 업데이트 팝업이 뜨게 되므로 자리 수를 맞춰 비교합니다.
    static func isVersion(_ a: String, lowerThan b: String) -> Bool {
        let left = numbers(of: a)
        let right = numbers(of: b)
        for index in 0..<max(left.count, right.count) {
            let l = index < left.count ? left[index] : 0
            let r = index < right.count ? right[index] : 0
            if l != r { return l < r }
        }
        return false
    }

    /// "1.0.0" → [1, 0, 0] (숫자가 아닌 부분은 0으로 봅니다)
    private static func numbers(of version: String) -> [Int] {
        version.split(separator: ".").map { Int($0.filter(\.isNumber)) ?? 0 }
    }

    // MARK: - Private

    private static func fetchConfig() async -> AppConfigDTO? {
        guard !APIEnvironment.current.useMock else { return nil }
        do {
            // 결과 타입을 명시해 Rx(Single) 오버로드가 아닌 async 버전을 사용합니다
            let config: AppConfigDTO = try await NetworkService.shared.request(.appConfig(), type: AppConfigDTO.self)
            return config
        } catch {
            return nil
        }
    }
}

// MARK: - AppConfigDTO
/// `GET /api/publicdata/config/` 응답 중 앱이 쓰는 값
/// (NetworkService 디코더가 snake_case → camelCase로 변환합니다)
struct AppConfigDTO: Decodable {
    let minIosVersion: String?
    let storeUrl: String?

    var minimumVersion: String? {
        guard let value = minIosVersion?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return nil }
        return value
    }

    var storeURL: URL? {
        guard let value = storeUrl?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return nil }
        return URL(string: value)
    }
}
