import SwiftUI

// MARK: - TouristHomeSkeleton
/// 관광객 홈 첫 로딩 — 제목 · 진행률 카드 · 오늘의 일정 · 주변 스팟 · 공지 순서

struct TouristHomeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBlock(width: 180, height: 22)
                .padding(.top, AppSpacing.md)
            SkeletonBlock(width: 110, height: 14)
                .padding(.top, AppSpacing.xs)

            SkeletonBlock(height: 120, radius: AppRadius.xl)
                .padding(.top, AppSpacing.xl)

            SkeletonBlock(width: 90, height: 18)
                .padding(.top, AppSpacing.xl)
            SkeletonBlock(height: 64, radius: AppRadius.lg)
                .padding(.top, AppSpacing.sm)
            SkeletonBlock(height: 48, radius: AppRadius.lg)
                .padding(.top, AppSpacing.xs)

            SkeletonBlock(width: 110, height: 18)
                .padding(.top, AppSpacing.xl)
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in SkeletonBlock(width: 150, height: 84, radius: AppRadius.lg) }
            }
            .padding(.top, AppSpacing.sm)

            SkeletonBlock(height: 58, radius: AppRadius.lg)
                .padding(.top, AppSpacing.xl)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .shimmering()
    }
}
