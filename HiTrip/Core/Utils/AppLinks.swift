import Foundation

// MARK: - AppLinks
/// 외부로 여는 링크 모음
///
/// ⚠️ 아래 값은 기획에서 "확정 필요"로 남아 있습니다. 확정되면 여기만 채우면 됩니다.
/// nil이면 해당 버튼은 눌러도 아무 곳으로도 이동하지 않습니다.

enum AppLinks {

    /// 로그인 화면 [문의하기] — 외부 브라우저로 엽니다 [문구·채널 확정 필요]
    static let inquiry: URL? = nil

    /// App Store 페이지 — 강제 업데이트 팝업 [업데이트]
    static let appStore: URL? = nil

    /// 약관 전문 (웹뷰)
    static func terms(_ kind: TermsKind) -> URL? {
        switch kind {
        case .service, .privacy, .location, .health, .marketing:
            return nil
        }
    }
}

/// 약관 종류
enum TermsKind: String, CaseIterable, Identifiable {
    case service, privacy, location, health, marketing
    var id: String { rawValue }
}
