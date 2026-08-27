import SwiftUI

// MARK: - HiTrip Typography System
/// Pretendard 기반 폰트 토큰
///
/// 프로젝트에 Pretendard 폰트 파일(.ttf/.otf)을 추가하고
/// Info.plist의 UIAppFonts 배열에 등록하면 자동 적용.
/// 등록 전까지는 시스템 폰트로 폴백.
///
/// 사용 예시:
/// ```
/// Text("안녕").font(HiTripFont.title1)
/// Text("본문").font(HiTripFont.body)
/// ```

enum HiTripFont {

    // MARK: - Font Names

    private static let regular    = "Pretendard-Regular"
    private static let medium     = "Pretendard-Medium"
    private static let semiBold   = "Pretendard-SemiBold"
    private static let bold       = "Pretendard-Bold"

    // MARK: - Display / Title

    /// 28pt Bold — 스플래시 로고, 최상위 헤더
    static let display   = font(bold, size: 28)
    /// 22pt Bold — 탭 화면 메인 타이틀
    static let title1    = font(bold, size: 22)
    /// 18pt SemiBold — 섹션 헤더, 네비게이션 바 타이틀
    static let title2    = font(semiBold, size: 18)
    /// 17pt SemiBold — 채팅방 헤더 이름
    static let title3    = font(semiBold, size: 17)

    // MARK: - Body

    /// 16pt SemiBold — 강조 본문, 버튼 텍스트
    static let bodyLBold = font(semiBold, size: 16)
    /// 16pt Regular — 일반 본문
    static let bodyL     = font(regular, size: 16)
    /// 15pt Medium — 채팅 말풍선 텍스트
    static let bodyM     = font(medium, size: 15)
    /// 14pt SemiBold — 카드 제목, 목록 항목 제목
    static let bodyBold  = font(semiBold, size: 14)
    /// 14pt Regular — 일반 본문 (소)
    static let body      = font(regular, size: 14)
    /// 13pt Medium — 카테고리 칩, 뱃지
    static let labelM    = font(medium, size: 13)
    /// 13pt Regular — 보조 텍스트
    static let label     = font(regular, size: 13)

    // MARK: - Caption / Small

    /// 12pt Medium — 타임스탬프, 카운터
    static let captionM  = font(medium, size: 12)
    /// 12pt Regular — placeholder, 최소 텍스트
    static let caption   = font(regular, size: 12)
    /// 11pt Bold — 뱃지 숫자
    static let badge     = font(bold, size: 11)

    // MARK: - Private Helper

    private static func font(_ name: String, size: CGFloat) -> Font {
        Font.custom(name, size: size)
    }
}

// MARK: - Font + Weight Convenience (system fallback 직접 지정 시)

extension Font {
    /// Pretendard 미등록 환경에서 직접 사이즈+굵기로 생성
    static func pretendard(_ weight: Font.Weight, size: CGFloat) -> Font {
        let name: String
        switch weight {
        case .bold:       name = "Pretendard-Bold"
        case .semibold:   name = "Pretendard-SemiBold"
        case .medium:     name = "Pretendard-Medium"
        default:          name = "Pretendard-Regular"
        }
        return .custom(name, size: size)
    }
}
