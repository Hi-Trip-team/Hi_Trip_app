import SwiftUI
import UIKit

// MARK: - AppFont
/// 글꼴 토큰 — 크기 단계 + 굵기
///
/// | 단계 | 크기 | 쓰임 |
/// |---|---|---|
/// | display | 48 | 스플래시 로고 |
/// | logo | 40 | 로그인 로고 |
/// | emojiXL / emojiL | 34 / 26 | 큰 이모지 아이콘 |
/// | title0~3 | 24 / 22 / 20 / 18 | 화면·섹션 제목 |
/// | headline | 17 | 헤더 제목 |
/// | bodyL / bodyM / body | 16 / 15 / 14 | 본문 |
/// | label | 13 | 칩·보조 본문 |
/// | caption / caption2 | 12 / 11 | 시각·설명 |
/// | micro / micro2 | 10 / 9 | 뱃지·아주 작은 글자 |
///
/// 굵기는 이름 뒤에 붙습니다 (예: `bodyBold`, `labelMedium`). 붙지 않으면 Regular입니다.

enum AppFont {
    static let displayBold = Font.pretendard(.bold, size: 48)
    static let logoHeavy = Font.pretendard(.heavy, size: 40)
    static let logo = Font.pretendard(.regular, size: 40)
    static let emojiXL = Font.pretendard(.regular, size: 34)
    static let emojiL = Font.pretendard(.regular, size: 26)
    static let title0 = Font.pretendard(.regular, size: 24)
    static let title1Bold = Font.pretendard(.bold, size: 22)
    static let title1Light = Font.pretendard(.light, size: 22)
    static let title1 = Font.pretendard(.regular, size: 22)
    static let title2Bold = Font.pretendard(.bold, size: 20)
    static let title3Bold = Font.pretendard(.bold, size: 18)
    static let title3Medium = Font.pretendard(.medium, size: 18)
    static let title3 = Font.pretendard(.regular, size: 18)
    static let headlineBold = Font.pretendard(.bold, size: 17)
    static let headline = Font.pretendard(.regular, size: 17)
    static let headlineSemiBold = Font.pretendard(.semibold, size: 17)
    static let bodyLBold = Font.pretendard(.bold, size: 16)
    static let bodyLMedium = Font.pretendard(.medium, size: 16)
    static let bodyL = Font.pretendard(.regular, size: 16)
    static let bodyLSemiBold = Font.pretendard(.semibold, size: 16)
    static let bodyMBold = Font.pretendard(.bold, size: 15)
    static let bodyMMedium = Font.pretendard(.medium, size: 15)
    static let bodyBold = Font.pretendard(.bold, size: 14)
    static let bodyMedium = Font.pretendard(.medium, size: 14)
    static let body = Font.pretendard(.regular, size: 14)
    static let bodySemiBold = Font.pretendard(.semibold, size: 14)
    static let labelBold = Font.pretendard(.bold, size: 13)
    static let labelMedium = Font.pretendard(.medium, size: 13)
    static let label = Font.pretendard(.regular, size: 13)
    static let labelSemiBold = Font.pretendard(.semibold, size: 13)
    static let captionBold = Font.pretendard(.bold, size: 12)
    static let captionMedium = Font.pretendard(.medium, size: 12)
    static let caption = Font.pretendard(.regular, size: 12)
    static let captionSemiBold = Font.pretendard(.semibold, size: 12)
    static let caption2Bold = Font.pretendard(.bold, size: 11)
    static let caption2Medium = Font.pretendard(.medium, size: 11)
    static let caption2 = Font.pretendard(.regular, size: 11)
    static let caption2SemiBold = Font.pretendard(.semibold, size: 11)
    static let microBold = Font.pretendard(.bold, size: 10)
    static let microMedium = Font.pretendard(.medium, size: 10)
    static let micro = Font.pretendard(.regular, size: 10)
    static let microSemiBold = Font.pretendard(.semibold, size: 10)
    static let micro2Medium = Font.pretendard(.medium, size: 9)
    static let micro2 = Font.pretendard(.regular, size: 9)

    /// SF Symbol 아이콘 크기 — 글자 단계와 별개로 아이콘 크기를 지정할 때 씁니다
    static func icon(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

// MARK: - Pretendard

extension Font {
    /// Pretendard로 그리되, 폰트 파일이 번들에 없으면 같은 굵기의 시스템 폰트로 대체합니다.
    /// (Font.custom은 폰트가 없으면 굵기를 무시한 Regular로 떨어집니다)
    static func pretendard(_ weight: Font.Weight, size: CGFloat) -> Font {
        let name: String
        switch weight {
        case .black, .heavy: name = "Pretendard-ExtraBold"
        case .bold:          name = "Pretendard-Bold"
        case .semibold:      name = "Pretendard-SemiBold"
        case .medium:        name = "Pretendard-Medium"
        case .light:         name = "Pretendard-Light"
        default:             name = "Pretendard-Regular"
        }
        guard UIFont(name: name, size: size) != nil else {
            return .system(size: size, weight: weight)
        }
        return .custom(name, size: size)
    }
}
