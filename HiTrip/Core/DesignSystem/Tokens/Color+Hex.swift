import SwiftUI

// MARK: - Color Hex Initializer

extension Color {

    /// Hex 문자열로 Color 생성
    ///
    /// 사용 예시:
    /// ```
    /// Color(hex: "0C46C0")     // 6자리 (RGB)
    /// Color(hex: "#0C46C0")    // # prefix 자동 제거
    /// Color(hex: "FF0C46C0")   // 8자리 (ARGB)
    /// ```
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (알파 255 기본값)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - HiTrip Design System Colors
/// 디자인 시스템 컬러 토큰
///
/// Figma 컬러 가이드 기반 — 모든 View에서 `HiTripColor.xxx`로 참조
///
/// 사용 예시:
/// ```
/// .background(HiTripColor.screenBackground)
/// .foregroundColor(HiTripColor.primary800)
/// ```
///
/// 컬러 체계:
/// - Primary (900~800): 진한 네이비~블루 — 핵심 브랜딩
/// - Secondary (700~100): 밝은 블루 스펙트럼 — 보조 요소
/// - Gray (500~100): 텍스트, 테두리, 배경
/// - Semantic: 용도별 별칭 (buttonPrimary, error 등)

enum HiTripColor {

    // MARK: - Primary Blue

    /// #062360 — 가장 어두운 네이비 (텍스트 강조, 헤더)
    static let primary900 = Color(hex: "062360")
    /// #0C46C0 — 메인 브랜드 블루 (스플래시 배경, 주요 버튼)
    static let primary800 = Color(hex: "0C46C0")

    // MARK: - Secondary Blue

    /// #3371F2 — 밝은 블루 (로고 텍스트, 링크)
    static let secondary700 = Color(hex: "3371F2")
    /// #547FF3
    static let secondary600 = Color(hex: "547FF3")
    /// #6B8EF5
    static let secondary500 = Color(hex: "6B8EF5")
    /// #7F9DF6
    static let secondary400 = Color(hex: "7F9DF6")
    /// #90ACF7
    static let secondary300 = Color(hex: "90ACF7")
    /// #A0BCF8
    static let secondary200 = Color(hex: "A0BCF8")
    /// #ECF2FE — 가장 밝은 블루 (배경, 카드)
    static let secondary100 = Color(hex: "ECF2FE")

    // MARK: - Text Colors

    /// #000000 — 기본 텍스트
    static let textBlack = Color(hex: "000000")
    /// #333333 — 본문 텍스트
    static let textGrayA = Color(hex: "333333")

    // MARK: - Gray Scale

    /// #666666 — 보조 텍스트
    static let gray500 = Color(hex: "666666")
    /// #999999 — placeholder, 비활성 텍스트
    static let gray400 = Color(hex: "999999")
    /// #BEBEBE — 테두리, 구분선
    static let gray300 = Color(hex: "BEBEBE")
    /// #CECECE — 비활성 버튼 배경
    static let gray200 = Color(hex: "CECECE")
    /// #F7F7F7 — 스크린 배경, 인풋 배경
    static let gray100 = Color(hex: "F7F7F7")

    // MARK: - Semantic Aliases (용도별 별칭)

    /// 스플래시 배경색
    static let splashBackground = primary800
    /// 메인 버튼 배경 (로그인, 다음, 완료)
    static let buttonPrimary = primary800
    /// 비활성 버튼 배경
    static let buttonDisabled = gray200
    /// 비활성 버튼 텍스트
    static let buttonDisabledText = gray400
    /// 로고 텍스트 컬러
    static let logoText = secondary700
    /// 강조 링크 / 이동 링크 (#0C46C0)
    static let accentLink = primary800
    /// 스크린 기본 배경 #F9F9F9
    static let screenBackground = Color(hex: "F9F9F9")

    /// 카드 드롭 섀도우 컬러 #B4BCC91F (12% opacity)
    static let cardShadow = Color(hex: "B4BCC9").opacity(0.12)
    /// 인풋 필드 배경
    static let inputBackground = Color.white
    /// 에러 (빨간 테두리, 경고 텍스트)
    static let error = Color(hex: "E53E3E")
    /// 읽음/성공 표시 (초록 체크)
    static let readCheck = Color(hex: "4CAF50")

    // MARK: - Section Tag

    /// #F4F3F9 — 체크리스트 섹션 태그 배경 (연보라)
    static let sectionTagBackground = Color(hex: "F4F3F9")

    // MARK: - Dot Indicator (회원가입 플로우)

    /// 도트 인디케이터 비활성
    static let dotInactive = gray300
    /// 도트 인디케이터 활성
    static let dotActive = primary800

    // MARK: - Semantic Alert Colors (알림 센터)

    /// 위험 — #E53E3E (심박수 이상, 긴급)
    static let danger         = Color(hex: "E53E3E")
    /// 위험 배경 — #FFF5F5
    static let dangerBg       = Color(hex: "FFF5F5")
    /// 이탈 (주황) — #DD6B20
    static let caution        = Color(hex: "DD6B20")
    /// 이탈 배경 — #FFFAF0
    static let cautionBg      = Color(hex: "FFFAF0")
    /// 경고 (노랑) — #D69E2E
    static let warningYellow  = Color(hex: "D69E2E")
    /// 경고 배경 — #FFFFF0
    static let warningBg      = Color(hex: "FFFFF0")
    /// 알반(일반) — Gray500과 동일
    static let normalAlert    = gray500

    // MARK: - Map / Zone

    /// 안전 구역 경계선 — #E53E3E (빨간 점선 원)
    static let safeZoneBorder = Color(hex: "E53E3E")
    /// 안전 구역 내부 채움 — #FFF5F5 10% opacity
    static let safeZoneFill   = Color(hex: "FFF5F5").opacity(0.35)
    /// GPS 정확도 낮음 칩 — #DD6B20
    static let gpsLowAccuracy = Color(hex: "DD6B20")

    // MARK: - Advantage Card

    /// 어드벤티지 카드 배경 — secondary100
    static let advantageBg    = secondary100
    /// 어드벤티지 카드 강조 텍스트 — primary800
    static let advantageAccent = primary800

    // MARK: - Chat

    /// 내 말풍선 배경 — primary800
    static let bubbleMine     = primary800
    /// 상대 말풍선 배경 — #F2F2F2
    static let bubbleOther    = Color(hex: "F2F2F2")
    /// 전송 실패 — danger와 동일
    static let sendFailed     = danger
    /// 활동중 dot — #48BB78 (초록)
    static let onlineGreen    = Color(hex: "48BB78")
    /// 읽음 체크 — #48BB78
    static let readCheckGreen = Color(hex: "48BB78")
}
