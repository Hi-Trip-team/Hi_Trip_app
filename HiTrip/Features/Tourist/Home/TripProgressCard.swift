import SwiftUI

// MARK: - TripProgressCard
/// 홈 "오늘의 일정" 상단 여행 진행률 카드
///
/// 피그마 12152:4224 — #0C46C0, 349×103, 모서리 16
/// - "여행 진행률 · N일 남음" 13 Medium, 자간 -0.26
/// - 진행 바: 트랙 #A0BCF8 6pt 라운드캡, 지나온 구간 #4F7BFF,
///   현재 위치에 12pt 점과 그 위를 따라가는 버스 아이콘 (Figma 12151:4014)
/// - "65% 완료" 자간 -0.38
/// - 오른쪽에 목적지
///
/// 인디케이터는 기획대로 "당일 첫 일정 시작 ~ 마지막 일정 종료" 대비 현재 시각 비율입니다.
/// 남은 일수는 여행 일정에서 계산해 넘겨받고, 퍼센트 문구는 진행률에서 만듭니다.
///
/// 날씨(디자인의 "맑음 22°C")는 API에 없어 표시하지 않습니다.
/// 스키마 전체에 weather/temperature 필드가 0건입니다.

struct TripProgressCard: View {

    /// 당일 진행률 0...1 — 첫 일정 시작 전 0, 마지막 일정 종료 후 1
    let progress: Double
    /// 여행 종료까지 남은 일수
    let remainingDays: Int
    /// 목적지 — 없으면 숨김
    let destination: String?

    /// 트랙 좌우 여백 (카드 기준)
    private let trackInset: CGFloat = 26
    private let trackHeight: CGFloat = 6
    private let dotSize: CGFloat = 12

    // MARK: - 계산값

    private var clamped: Double { min(max(progress, 0), 1) }

    /// "여행 진행률 · 3일 남음"
    private var headline: String {
        if remainingDays > 0  { return "여행 진행률 · \(remainingDays)일 남음" }
        if remainingDays == 0 { return "여행 진행률 · 오늘이 마지막 날" }
        return "여행 진행률 · 일정 종료"
    }

    /// "65% 완료"
    private var percentText: String {
        "\(Int((clamped * 100).rounded()))% 완료"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(headline)
                .font(AppFont.labelMedium)
                .tracking(-0.26)
                .foregroundColor(.white)
                .padding(.top, AppSpacing.sm)

            // 버스는 진행 위치(점) 바로 위를 따라갑니다.
            // 제목과 같은 줄에 두면 진행률이 낮을 때 글자를 가려서 한 줄 아래에 둡니다.
            GeometryReader { geo in
                Image("Icons/bus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 20)
                    // 원본 아이콘은 왼쪽을 봅니다. 진행 방향(오른쪽)으로 뒤집습니다.
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: busOffset(in: geo.size.width))
            }
            .frame(height: 24)
            .padding(.top, 2)

            progressBar
                .frame(height: dotSize)

            HStack(alignment: .firstTextBaseline) {
                Text(percentText)
                    .font(AppFont.bodyLBold)
                    .tracking(-0.38)
                    .foregroundColor(.white)

                Spacer(minLength: 8)

                if let destination, !destination.isEmpty {
                    Text(destination)
                        .font(AppFont.labelMedium)
                        .tracking(-0.26)
                        .foregroundColor(.white)
                        .padding(.trailing, 2)
                }
            }
            .padding(.vertical, 6)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, trackInset)
        .frame(height: 103)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.brand)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }

    /// 버스를 점 중앙에 맞춥니다 (아이콘 폭의 절반만큼 왼쪽으로)
    private func busOffset(in width: CGFloat) -> CGFloat {
        let travel = max(width - dotSize, 0)
        return travel * clamped + dotSize / 2 - 13
    }

    // MARK: - 진행 바

    private var progressBar: some View {
        GeometryReader { geo in
            // 점이 트랙 밖으로 나가지 않도록 지름만큼 안쪽에서 움직입니다.
            let travel = max(geo.size.width - dotSize, 0)
            let dotCenter = travel * clamped + dotSize / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.brandLight)
                    .frame(height: trackHeight)

                // 지나온 구간
                Capsule()
                    .fill(AppColor.brandBright)
                    .frame(width: dotCenter, height: trackHeight)

                Circle()
                    .fill(AppColor.brandBright)
                    .frame(width: dotSize, height: dotSize)
                    .offset(x: travel * clamped)
            }
            .frame(height: geo.size.height, alignment: .center)
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        TripProgressCard(progress: 0,    remainingDays: 6, destination: "제주")
        TripProgressCard(progress: 0.65, remainingDays: 3, destination: "제주")
        TripProgressCard(progress: 1,    remainingDays: 0, destination: "제주")
    }
    .padding(21)
}
