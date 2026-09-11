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
