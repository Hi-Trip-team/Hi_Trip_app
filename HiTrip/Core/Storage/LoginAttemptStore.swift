import Foundation

// MARK: - LoginAttemptStore
/// 로그인 실패 횟수 / 잠금 해제 시각 (아이디별)
///
/// 잠금의 기준은 서버입니다(기기를 바꿔도 유지). 서버가 429로 잠그면 그 시간을 그대로 씁니다.
/// 다만 현재 서버는 실패 횟수를 응답에 주지 않아 "(n/5)" 표시는 이 기기의 기록으로 셉니다.
/// 서버가 remaining_attempts를 주기 시작하면 그 값이 우선합니다.

enum LoginAttemptStore {

    static let maxAttempts = 5

    /// 서버가 잠금 시간을 알려주지 않을 때의 기본값 (기획: 10분)
    static let defaultLockSeconds = 600

    private static let defaults = UserDefaults.standard
    private static func countKey(_ id: String) -> String { "com.hitrip.loginFail.\(id.lowercased())" }
    private static func lockKey(_ id: String) -> String { "com.hitrip.loginLock.\(id.lowercased())" }

    static func failures(for id: String) -> Int {
        defaults.integer(forKey: countKey(id))
    }

    @discardableResult
    static func recordFailure(for id: String) -> Int {
        let next = failures(for: id) + 1
        defaults.set(next, forKey: countKey(id))
        return next
    }

    static func setFailures(_ count: Int, for id: String) {
        defaults.set(count, forKey: countKey(id))
    }

    static func lockedUntil(for id: String) -> Date? {
        guard let date = defaults.object(forKey: lockKey(id)) as? Date else { return nil }
        if date <= Date() { reset(for: id); return nil }
        return date
    }

    static func lock(_ id: String, seconds: Int) {
        defaults.set(Date().addingTimeInterval(TimeInterval(seconds)), forKey: lockKey(id))
    }

    /// 로그인 성공 또는 잠금 해제 시 초기화
    static func reset(for id: String) {
        defaults.removeObject(forKey: countKey(id))
        defaults.removeObject(forKey: lockKey(id))
    }
}
