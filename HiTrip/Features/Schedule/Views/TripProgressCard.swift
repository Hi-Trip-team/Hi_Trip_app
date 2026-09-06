import SwiftUI

// MARK: - TripProgressCard
/// 홈 "오늘의 일정" 상단 여행 진행률 카드
///
/// 피그마 12152:4224 — #0C46C0, 349×103, 모서리 16
/// - "여행 진행률 · N일 남음" 13 Medium, 자간 -0.26
/// - 진행 바: 트랙 #A0BCF8 6pt 라운드캡, 지나온 구간 #4F7BFF,
///   현재 위치에 12pt 점과 그 위를 따라가는 🚌
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
                .padding(.top, 12)

            // 버스는 진행 위치(점) 바로 위를 따라갑니다.
            // 제목과 같은 줄에 두면 진행률이 낮을 때 글자를 가려서 한 줄 아래에 둡니다.
            GeometryReader { geo in
                Text("🚌")
                    .font(.system(size: 20))
                    .offset(x: busOffset(in: geo.size.width))
            }
            .frame(height: 24)
            .padding(.top, 2)

            progressBar
                .frame(height: dotSize)

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
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, trackInset)
        .frame(height: 103)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#0C46C0"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// 버스를 점 중앙에 맞춥니다 (이모지 폭의 절반만큼 왼쪽으로)
    private func busOffset(in width: CGFloat) -> CGFloat {
        let travel = max(width - dotSize, 0)
        return travel * clamped + dotSize / 2 - 11
    }

    private var clamped: Double { min(max(progress, 0), 1) }

    // MARK: - 진행 바

    private var progressBar: some View {
        GeometryReader { geo in
            // 점이 트랙 밖으로 나가지 않도록 지름만큼 안쪽에서 움직입니다.
            let travel = max(geo.size.width - dotSize, 0)
            let dotCenter = travel * clamped + dotSize / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "#A0BCF8"))
                    .frame(height: trackHeight)

                // 지나온 구간
                Capsule()
                    .fill(Color(hex: "#4F7BFF"))
                    .frame(width: dotCenter, height: trackHeight)

                Circle()
                    .fill(Color(hex: "#4F7BFF"))
                    .frame(width: dotSize, height: dotSize)
                    .offset(x: travel * clamped)
            }
            .frame(height: geo.size.height, alignment: .center)
        }
    }
}
