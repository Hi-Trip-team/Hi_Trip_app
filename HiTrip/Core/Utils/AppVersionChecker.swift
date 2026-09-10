import Foundation

// MARK: - AppVersionChecker
/// 최소 지원 버전 확인 (스플래시)
///
/// ⚠️ 서버에 최소 지원 버전을 알려주는 API가 아직 없습니다.
/// 지금은 항상 "업데이트 불필요"로 통과합니다. API가 생기면 `minimumVersion()`만 채우면
/// 스플래시의 강제 업데이트 팝업이 그대로 동작합니다.

enum AppVersionChecker {

    /// 설치된 앱 버전 (MARKETING_VERSION)
    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// 서버가 요구하는 최소 버전 — 미지원이라 nil
    static func minimumVersion() async -> String? {
        nil
    }

    static func isUpdateRequired() async -> Bool {
        guard let minimum = await minimumVersion() else { return false }
        return isVersion(currentVersion, lowerThan: minimum)
    }

    /// "1.2.10" < "1.10.0" 같은 비교를 숫자 단위로 합니다
    static func isVersion(_ a: String, lowerThan b: String) -> Bool {
        a.compare(b, options: .numeric) == .orderedAscending
    }
}
