import Foundation

// MARK: - AgreementRecordStore
/// 약관 동의 이력 (동의 일시·버전)
///
/// 관광객은 POST /api/v1/tourist/agreements/ 로 서버에도 저장됩니다(동의 일시는 서버 accepted_at).
/// 안내사는 동의 저장 API가 없고, 서버 스키마에 약관 버전 필드도 없어 버전은 이 기기에만 기록합니다.
/// ⚠️ 서버에 안내사 동의 API / 버전 필드가 생기면 그쪽으로 옮겨야 합니다.

enum AgreementRecordStore {

    /// 약관 문서 버전 — 약관 전문이 바뀌면 올려서 재동의를 받습니다
    static let currentVersion = "2025.1"

    private static let defaults = UserDefaults.standard
    private static func key(_ userId: String, _ type: UserType) -> String {
        "com.hitrip.agreement.\(type.rawValue).\(userId)"
    }

    static func hasAgreed(userId: String, userType: UserType) -> Bool {
        guard let record = defaults.dictionary(forKey: key(userId, userType)) else { return false }
        return record["version"] as? String == currentVersion
    }

    static func record(userId: String, userType: UserType, optionalAccepted: Bool) {
        defaults.set([
            "version": currentVersion,
            "agreedAt": ISO8601DateFormatter().string(from: Date()),
            "optionalAccepted": optionalAccepted
        ], forKey: key(userId, userType))
    }
}
