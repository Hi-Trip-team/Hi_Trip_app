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
    /// 스크린 기본 배경
    static let screenBackground = gray100
    /// 인풋 필드 배경
    static let inputBackground = Color.white
    /// 에러 (빨간 테두리, 경고 텍스트)
    static let error = Color(hex: "E53E3E")
    /// 읽음/성공 표시 (초록 체크)
    static let readCheck = Color(hex: "4CAF50")
}
