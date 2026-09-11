import SwiftUI

// MARK: - AppColor
/// 색상 토큰 — Figma(0827 수정본)에서 쓰는 값을 의미 이름으로 모았습니다.
///
/// 화면 코드에서는 hex를 직접 쓰지 않고 이 토큰만 사용합니다.
/// 값을 바꾸면 앱 전체에 한 번에 반영됩니다.

enum AppColor {

    // MARK: Brand

    /// #0C46C0 — 메인 브랜드 블루 (스플래시·주요 버튼·로고)
    static let brand = Color(hex: "0C46C0")
    /// #4F7BFF — 진행률 바 등 밝은 브랜드 블루
    static let brandBright = Color(hex: "4F7BFF")
    /// #A0BCF8 — 옅은 브랜드 블루 (지도 범위·보조 채움)
    static let brandLight = Color(hex: "A0BCF8")
    /// #F8F8F8 — 브랜드 버튼 위 글자
    static let onBrand = Color(hex: "F8F8F8")

    // MARK: Accent (선택·링크·강조)

    /// #2563EB — 선택된 칩·체크박스·링크
    static let accent = Color(hex: "2563EB")
    /// #E8F0FF — 강조 영역 배경 (선택된 일차·안전 현황 카드)
    static let accentSubtle = Color(hex: "E8F0FF")
    /// #EEF2FF — 옅은 강조 배경
    static let accentSoft = Color(hex: "EEF2FF")
    /// #E5F4FF — 안내 배경
    static let infoSubtle = Color(hex: "E5F4FF")

    // MARK: Text

    /// #111827 — 제목·본문 기본
    static let textPrimary = Color(hex: "111827")
    /// #1B1E28 — 진한 본문
    static let textStrong = Color(hex: "1B1E28")
    /// #1A1A1A — 거의 검정 (라벨·어두운 배경)
    static let ink = Color(hex: "1A1A1A")
    /// #374151 — 진한 회색 글자
    static let textDark = Color(hex: "374151")
    /// #333840 — 목록 본문
    static let textBody = Color(hex: "333840")
    /// #313131
    static let gray800 = Color(hex: "313131")
    /// #4F4F4F
    static let gray700 = Color(hex: "4F4F4F")
    /// #666666 — 보조 설명 (팝업 본문)
    static let textGray = Color(hex: "666666")
    /// #6B7280 — 보조 글자·placeholder
    static let textSecondary = Color(hex: "6B7280")
    /// #7D848D — 흐린 보조 글자
    static let textMuted = Color(hex: "7D848D")
    /// #9CA3AF — 3차 글자·비활성 아이콘
    static let textTertiary = Color(hex: "9CA3AF")

    // MARK: Surface & Line

    /// #F3F4F6 — 카드·입력칸·칩 배경
    static let surface = Color(hex: "F3F4F6")
    /// #F7F7F9 — 채팅 구분 배경
    static let surfaceMuted = Color(hex: "F7F7F9")
    /// #F9FAFB — 읽은 알림 등 가장 옅은 배경
    static let surfaceSubtle = Color(hex: "F9FAFB")
    /// #F9F9F9 — 화면 기본 배경
    static let screenBackground = Color(hex: "F9F9F9")
    /// #E5E7EB — 구분선·옅은 테두리
    static let divider = Color(hex: "E5E7EB")
    /// #D9DEE5
    static let borderSoft = Color(hex: "D9DEE5")
    /// #C3CDDA — 지도 도로·흐린 선
    static let borderMuted = Color(hex: "C3CDDA")
    /// #D1D5DB — 진한 테두리·비활성 체크
    static let borderStrong = Color(hex: "D1D5DB")

    // MARK: Button

    /// #CECECE — 비활성 버튼 배경
    static let buttonDisabled = Color(hex: "CECECE")
    /// #999999 — 비활성 버튼 글자
    static let buttonDisabledText = Color(hex: "999999")

    // MARK: Status

    /// #EF4444 — 위험·오류 (빨간 테두리·문구)
    static let danger = Color(hex: "EF4444")
    /// #E53E3E — 진한 위험 (제한 배너)
    static let dangerStrong = Color(hex: "E53E3E")
    /// #E46059 — 부드러운 빨강 (전송 실패)
    static let dangerSoft = Color(hex: "E46059")
    /// #FCE5E5 — 위험 뱃지 배경
    static let dangerSubtle = Color(hex: "FCE5E5")
    /// #FFF5F5 — 위험 배너 배경
    static let dangerBackground = Color(hex: "FFF5F5")
    /// #EB8C0D — 경고 (주황)
    static let warning = Color(hex: "EB8C0D")
    /// #F59E0B — 경고 (호박색)
    static let warningAmber = Color(hex: "F59E0B")
    /// #FFF2D9 — 경고 뱃지 배경
    static let warningSubtle = Color(hex: "FFF2D9")
    /// #DD6B20 — 주의 (GPS 정확도 낮음)
    static let caution = Color(hex: "DD6B20")
    /// #2E9B67 — 정상·성공
    static let success = Color(hex: "2E9B67")
    /// #E0EAE0 — 지도 녹지
    static let successSubtle = Color(hex: "E0EAE0")
    /// #48BB78 — 접속 중·읽음
    static let online = Color(hex: "48BB78")
    /// #734CD9 — 관광객 위치 핀
    static let touristPin = Color(hex: "734CD9")
}
