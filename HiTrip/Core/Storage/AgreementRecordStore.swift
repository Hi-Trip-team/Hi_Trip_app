import Foundation

// MARK: - AgreementRecordStore
/// 약관·권한 동의 이력 — 기기 단위
///
/// 약관·권한 화면은 이 기기에서 처음 로그인할 때 한 번만 보여줍니다.
/// 같은 기기에서 다른 계정으로 로그인해도 다시 묻지 않습니다.
/// (앱을 지웠다 다시 설치하면 UserDefaults가 비워지므로 다시 묻습니다.)
///
/// 관광객 계정은 서버에도 동의 상태가 있어, 기기는 동의했지만 서버가
/// requires_agreement=true를 주면 여기 기록된 값으로 조용히 저장합니다.

enum AgreementRecordStore {

    /// 약관 문서 버전 — 약관 전문이 바뀌면 올려서 재동의를 받습니다
    static let currentVersion = "2025.1"

    private static let key = "com.hitrip.agreement.device"
    private static let defaults = UserDefaults.standard

    /// 이 기기에서 현재 버전 약관에 동의했는지
    static var hasAgreedOnDevice: Bool {
        (defaults.dictionary(forKey: key)?["version"] as? String) == currentVersion
    }

    /// 선택 항목(푸시 알림 수신) 동의 여부
    static var optionalAccepted: Bool {
        defaults.dictionary(forKey: key)?["optionalAccepted"] as? Bool ?? false
    }

    static func record(optionalAccepted: Bool) {
        defaults.set([
            "version": currentVersion,
            "agreedAt": ISO8601DateFormatter().string(from: Date()),
            "optionalAccepted": optionalAccepted
        ], forKey: key)
    }
}
