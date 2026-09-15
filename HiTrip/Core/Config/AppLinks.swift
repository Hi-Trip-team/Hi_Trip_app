import Foundation

// MARK: - AppLinks
/// 외부로 여는 링크 모음
///
/// 번호·주소 값은 AppContacts.swift(커밋 제외)에 있습니다. 여기서는 URL로 바꾸기만 합니다.
/// 값이 비어 있으면 nil이 되고, 해당 버튼은 눌러도 아무 곳으로도 이동하지 않습니다.

enum AppLinks {

    /// 긴급 즉시 연락 — 통역 연결 번호
    static var interpreterPhone: String? { nonEmpty(AppContacts.interpreterPhone) }

    /// 로그인 화면 [문의하기] 번호
    static var inquiryPhone: String? { nonEmpty(AppContacts.inquiryPhone) }

    /// 긴급 통역 연결 기관 (기획 확정 2026-09-14)
    static let supportOrganization = "주식회사 픽토리얼"

    /// 로그인 화면 [문의하기] — 전화 앱으로 연결합니다
    static var inquiry: URL? { telURL(inquiryPhone) }

    /// App Store 페이지 — 강제 업데이트 팝업 [업데이트] (앱 출시 후 생성)
    static let appStore: URL? = nil

    /// 전화번호 → tel URL (숫자와 +만 남깁니다)
    static func telURL(_ number: String?) -> URL? {
        guard let digits = number?.filter({ $0.isNumber || $0 == "+" }), !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    /// 약관 전문 (웹뷰)
    /// 위치기반서비스 약관은 서비스 이용약관 문서에 함께 있습니다. 푸시 수신은 별도 문서가 없습니다.
    static func terms(_ kind: TermsKind) -> URL? {
        switch kind {
        case .service, .location: return url(AppContacts.termsURL)
        case .privacy:            return url(AppContacts.privacyURL)
        case .health, .push:      return nil
        }
    }

    /// 개인정보처리방침
    static var privacyPolicy: URL? { url(AppContacts.privacyURL) }

    private static func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func url(_ value: String) -> URL? {
        nonEmpty(value).flatMap(URL.init(string:))
    }
}

/// 약관 종류
enum TermsKind: String, CaseIterable, Identifiable {
    case service, privacy, location, health, push
    var id: String { rawValue }
}
