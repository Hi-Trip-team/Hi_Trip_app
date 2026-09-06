import CoreFoundation

// MARK: - HiTrip Spacing & Radius Tokens
/// 간격·모서리 반경 디자인 토큰
///
/// 사용 예시:
/// ```
/// .padding(.horizontal, HiTripSpacing.pagePadding)
/// .cornerRadius(HiTripRadius.card)
/// ```

enum HiTripSpacing {
    /// 4pt — 가장 작은 내부 여백
    static let xs:           CGFloat = 4
    /// 6pt — 작은 내부 여백
    static let xxs:          CGFloat = 6
    /// 8pt — 소형 여백 (칩 내부 등)
    static let sm:           CGFloat = 8
    /// 10pt — 중소 여백
    static let smd:          CGFloat = 10
    /// 12pt — 중간 여백
    static let md:           CGFloat = 12
    /// 14pt — 중상 여백
    static let mdl:          CGFloat = 14
    /// 16pt — 기본 섹션 여백
    static let lg:           CGFloat = 16
    /// 20pt — 페이지 좌우 패딩 (기본값)
    static let pagePadding:  CGFloat = 20
    /// 24pt — 큰 여백
    static let xl:           CGFloat = 24
    /// 32pt — 최대 여백 (바텀 세이프 영역 등)
    static let xxl:          CGFloat = 32

    // MARK: - Component-specific

    /// 채팅 말풍선 수평 패딩
    static let bubbleH:      CGFloat = 14
    /// 채팅 말풍선 수직 패딩
    static let bubbleV:      CGFloat = 10
    /// 카드 내부 패딩
    static let cardPadding:  CGFloat = 12
    /// 네비게이션 바 높이
    static let navBarHeight: CGFloat = 56
    /// 하단 입력창 패딩
    static let inputBarV:    CGFloat = 12
}

enum HiTripRadius {
    /// 6pt — 소형 칩, 뱃지
    static let chip:    CGFloat = 6
    /// 8pt — 작은 카드
    static let sm:      CGFloat = 8
    /// 10pt — 줌 버튼 등
    static let md:      CGFloat = 10
    /// 12pt — 일반 카드, 검색바
    static let card:    CGFloat = 12
    /// 14pt — 버튼
    static let button:  CGFloat = 14
    /// 16pt — 큰 카드
    static let lg:      CGFloat = 16
    /// 20pt — 카테고리 칩 pill
    static let pill:    CGFloat = 20
    /// 999pt — 완전 원형
    static let circle:  CGFloat = 999
}

enum HiTripShadow {
    /// 카드 그림자 반경
    static let cardRadius:  CGFloat = 8
    /// 카드 그림자 Y 오프셋
    static let cardY:       CGFloat = 2
    /// 버튼/컨트롤 그림자 반경
    static let controlRadius: CGFloat = 6
    static let controlY:      CGFloat = 2
}
