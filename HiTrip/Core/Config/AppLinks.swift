import Foundation

// MARK: - AppLinks
/// 외부로 여는 링크 모음
///
/// ⚠️ 아래 값은 기획에서 "확정 필요"로 남아 있습니다. 확정되면 여기만 채우면 됩니다.
/// nil이면 해당 버튼은 눌러도 아무 곳으로도 이동하지 않습니다.

enum AppLinks {

    /// 고객센터 전화 — 로그인 [문의하기]와 긴급 통역 연결이 같은 번호를 씁니다 (기획 확정 2026-09-14)
    /// ⚠️ 번호 전달 대기 — 채우면 두 버튼이 바로 전화를 겁니다.
    static let supportPhone: String? = nil

    /// 긴급 통역 연결 기관 (기획 확정 2026-09-14)
    static let supportOrganization = "주식회사 픽토리얼"

    /// 로그인 화면 [문의하기] — 전화 앱으로 연결합니다
    static var inquiry: URL? { telURL(supportPhone) }

    /// App Store 페이지 — 강제 업데이트 팝업 [업데이트] (앱 출시 후 생성)
    static let appStore: URL? = nil

    /// 전화번호 → tel URL (숫자와 +만 남깁니다)
    static func telURL(_ number: String?) -> URL? {
        guard let digits = number?.filter({ $0.isNumber || $0 == "+" }), !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    /// 약관 전문 (웹뷰)
    static func terms(_ kind: TermsKind) -> URL? {
        switch kind {
        case .service, .privacy, .location, .health, .push:
            return nil
        }
    }
}

/// 약관 종류
enum TermsKind: String, CaseIterable, Identifiable {
    case service, privacy, location, health, push
    var id: String { rawValue }
}
