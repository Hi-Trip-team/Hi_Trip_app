import SwiftUI

// MARK: - GuideHomeSkeleton
/// 안내사 홈 첫 로딩 — 제목 · 오늘의 일정 · 메뉴 4칸 · 안전 현황 순서

struct GuideHomeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBlock(width: 180, height: 22)
                .padding(.top, AppSpacing.md)
            SkeletonBlock(width: 90, height: 14)
                .padding(.top, AppSpacing.xs)

            SkeletonBlock(width: 90, height: 18)
                .padding(.top, AppSpacing.xl)
            SkeletonBlock(height: 4, radius: 2)
                .padding(.top, AppSpacing.md)
            SkeletonBlock(height: 56, radius: AppRadius.lg)
                .padding(.top, AppSpacing.md)
            SkeletonBlock(height: 48, radius: AppRadius.lg)
                .padding(.top, AppSpacing.xs)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: AppSpacing.sm), GridItem(.flexible())], spacing: AppSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in SkeletonBlock(height: 106, radius: AppRadius.xl) }
            }
            .padding(.top, AppSpacing.xl)

            SkeletonBlock(height: 90, radius: AppRadius.xl)
                .padding(.top, AppSpacing.xl)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .shimmering()
    }
}
