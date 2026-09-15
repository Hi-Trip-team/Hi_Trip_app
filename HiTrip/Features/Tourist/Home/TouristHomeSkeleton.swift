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
            // 카드 3장(150×3 + 간격)은 화면보다 넓어서, 그대로 두면 스켈레톤 전체가 화면 밖으로 넓어져
            // 좌우 여백이 사라져 보였습니다. 실제 홈처럼 가로 스크롤 틀(스크롤은 막음) 안에 넣어
            // 주어진 폭만 차지하고 세 번째 카드는 오른쪽 끝에서 잘리게 합니다.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in SkeletonBlock(width: 150, height: 84, radius: AppRadius.lg) }
                }
            }
            .disabled(true)
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
