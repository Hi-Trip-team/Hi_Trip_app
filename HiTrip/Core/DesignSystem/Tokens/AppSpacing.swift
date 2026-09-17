import CoreFoundation

// MARK: - AppSpacing
/// 간격 토큰 — 자주 쓰는 단위만 토큰으로 두고,
/// Figma 한 화면에만 있는 수치(6, 14 등)는 해당 화면에서 숫자로 씁니다.

enum AppSpacing {
    /// 4
    static let xxs: CGFloat = 4
    /// 8
    static let xs: CGFloat = 8
    /// 12
    static let sm: CGFloat = 12
    /// 16
    static let md: CGFloat = 16
    /// 20
    static let lg: CGFloat = 20
    /// 24 — 화면 좌우 기본 여백
    static let xl: CGFloat = 24
    /// 32
    static let xxl: CGFloat = 32
}

// MARK: - AppRadius
/// 모서리 반경 토큰

enum AppRadius {
    /// 6 — 작은 뱃지
    static let xs: CGFloat = 6
    /// 8 — 작은 카드·칩
    static let sm: CGFloat = 8
    /// 10 — 팝업 버튼
    static let md: CGFloat = 10
    /// 12 — 카드·입력칸
    static let lg: CGFloat = 12
    /// 16 — 팝업·큰 카드
    static let xl: CGFloat = 16
    /// 20 — pill
    static let xxl: CGFloat = 20
}
