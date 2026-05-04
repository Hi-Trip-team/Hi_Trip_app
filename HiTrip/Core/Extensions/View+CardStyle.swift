import SwiftUI

// MARK: - HiTripCardStyle
/// 공통 카드 스타일 ViewModifier
///
/// 디자인 스펙:
/// - 배경: #FFFFFF (흰색)
/// - Corner Radius: 16px
/// - Drop Shadow: #B4BCC9, opacity 12%, radius 12 (spread 12% 근사)
///
/// 사용법:
/// ```swift
/// VStack { ... }
///     .hiTripCard()
/// ```
///
/// 패딩이 필요한 경우:
/// ```swift
/// VStack { ... }
///     .hiTripCard(padding: 16)
/// ```

struct HiTripCardModifier: ViewModifier {
    var padding: CGFloat?

    func body(content: Content) -> some View {
        Group {
            if let padding = padding {
                content.padding(padding)
            } else {
                content
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(hex: "B4BCC9").opacity(0.12), radius: 12, x: 0, y: 4)
    }
}

extension View {
    /// HiTrip 공통 카드 스타일 적용
    /// - Parameter padding: 내부 패딩 (nil이면 패딩 없음, 직접 지정)
    func hiTripCard(padding: CGFloat? = nil) -> some View {
        modifier(HiTripCardModifier(padding: padding))
    }
}
