import SwiftUI

// MARK: - Skeleton
/// 첫 로딩 동안 실제 레이아웃 모양의 회색 틀을 보여줍니다.
///
/// 현업 규칙대로 **첫 로딩에만** 씁니다. 새로고침·폴링 중에는 기존 내용을 그대로 둡니다
/// (ViewModel은 load()에서만 .loading이 되고, refresh()는 상태를 바꾸지 않습니다).

struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat
    var radius: CGFloat = AppRadius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(AppColor.surface)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

// MARK: - Shimmer

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width * 1.6)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1 }
            }
            .accessibilityLabel("불러오는 중")
    }
}

extension View {
    /// 스켈레톤 위로 빛이 지나가는 효과
    func shimmering() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - SkeletonList
/// 목록·카드 화면용 기본 스켈레톤

struct SkeletonList: View {
    var rows: Int = 5
    var rowHeight: CGFloat = 60
    var spacing: CGFloat = AppSpacing.sm
    var topInset: CGFloat = AppSpacing.lg

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows, id: \.self) { _ in
                SkeletonBlock(height: rowHeight, radius: AppRadius.lg)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, topInset)
        .shimmering()
    }
}
