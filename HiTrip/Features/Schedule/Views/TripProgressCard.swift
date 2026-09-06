import SwiftUI

// MARK: - TripProgressCard
/// 홈 "오늘의 일정" 상단 여행 진행률 카드
///
/// 피그마 12152:4224 — #0C46C0, 349×103, 모서리 16
/// - "여행 진행률 · N일 남음" 13 Medium, 자간 -0.26
/// - 진행 바: 트랙 #A0BCF8 6pt 라운드캡, 현재 위치에 #4F7BFF 12pt 점
/// - "65% 완료" 19 Bold, 자간 -0.38
/// - 오른쪽에 목적지
///
/// 날씨(디자인의 "맑음 22°C")는 API에 없어 표시하지 않습니다.
/// 스키마 전체에 weather/temperature 필드가 0건입니다.

struct TripProgressCard: View {

    /// 0...1
    let progress: Double
    /// "여행 진행률 · 3일 남음"
    let headline: String
    /// "65% 완료"
    let percentText: String
    /// 목적지 — 없으면 숨김
    let destination: String?

    /// 트랙 좌우 여백 (카드 기준)
    private let trackInset: CGFloat = 26
    private let trackHeight: CGFloat = 6
    private let dotSize: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(headline)
                .font(.system(size: 13, weight: .medium))
                .tracking(-0.26)
                .foregroundColor(.white)
                .padding(.top, 15)

            progressBar
                .frame(height: dotSize)
                .padding(.top, 21)

            HStack(alignment: .firstTextBaseline) {
                Text(percentText)
                    .font(.system(size: 19, weight: .bold))
                    .tracking(-0.38)
                    .foregroundColor(.white)

                Spacer(minLength: 8)

                if let destination, !destination.isEmpty {
                    Text(destination)
                        .font(.system(size: 13, weight: .medium))
                        .tracking(-0.26)
                        .foregroundColor(.white)
                        .padding(.trailing, 2)
                }
            }
            .padding(.top, 12)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, trackInset)
        .frame(height: 103)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#0C46C0"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 진행 바

    private var progressBar: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            // 점이 트랙 밖으로 나가지 않도록 반지름만큼 안쪽으로 좁힙니다.
            let travel = max(geo.size.width - dotSize, 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "#A0BCF8"))
                    .frame(height: trackHeight)

                Circle()
                    .fill(Color(hex: "#4F7BFF"))
                    .frame(width: dotSize, height: dotSize)
                    .offset(x: travel * clamped)
            }
            .frame(height: geo.size.height, alignment: .center)
        }
    }
}
