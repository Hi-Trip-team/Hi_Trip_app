import SwiftUI

// MARK: - MyScheduleListView
/// "내 일정" 탭 — 여행 카드 리스트
///
/// 기능:
/// - 선택된 날짜에 해당하는 일정만 필터링 (없으면 전체 표시)
/// - 카드 탭 → SpotDetailView (검색과 동일한 상세보기)
/// - Trip→TourSpotItem 변환으로 SpotDetailView 재활용
///
/// 피그마 디자인:
/// - 각 카드: 개별 흰색 카드(radius 16) — 카드 간 gap 분리
/// - 썸네일(85x85, radius 16) + 날짜 + 제목(볼드) + 위치 + chevron

struct MyScheduleListView: View {

    @ObservedObject var viewModel: TripDetailViewModel

    /// SpotDetailView 표시용
    @State private var selectedSpot: TourSpotItem?

    /// 날짜 포맷터 — "2026년 1월 23일"
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }

    /// 표시할 일정 목록: 선택 날짜에 해당하는 일정만
    private var displayTrips: [Trip] {
        viewModel.tripsForSelectedDate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if displayTrips.isEmpty {
                    emptyState
                        .padding(.top, 60)
                } else {
                    tripCardList
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 40)
            }
        }
        .sheet(item: $selectedSpot) { spot in
            SpotDetailView(spot: spot)
        }
    }

    // MARK: - Trip Card List

    /// 각 카드가 개별 분리 + gap
    private var tripCardList: some View {
        VStack(spacing: 12) {
            ForEach(displayTrips) { trip in
                Button {
                    selectedSpot = trip.toSpotItem()
                } label: {
                    tripCardRow(trip)
                }
                .buttonStyle(.plain)
                .hiTripCard()
            }
        }
    }

    // MARK: - Trip Card Row

    /// 피그마: 썸네일 | 날짜 + 제목 + 위치 | chevron
    private func tripCardRow(_ trip: Trip) -> some View {
        HStack(spacing: 14) {
            // 썸네일 (85x85, radius 16)
            tripThumbnail(for: trip)
                .frame(width: 85, height: 85)
                .cornerRadius(16)

            // 텍스트 정보 — 각 요소 사이 gap
            VStack(alignment: .leading, spacing: 8) {
                // 날짜
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray500)

                    Text(dateFormatter.string(from: trip.date))
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray500)
                }

                // 제목
                Text(trip.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
                    .lineLimit(1)

                // 위치
                if !trip.location.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray400)

                        Text("위치: \(trip.location)")
                            .font(.system(size: 13))
                            .foregroundColor(HiTripColor.gray400)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // 오른쪽 chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HiTripColor.gray300)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    // MARK: - Thumbnail

    /// 썸네일: 이미지가 없으면 회색 + 아이콘 placeholder
    private func tripThumbnail(for trip: Trip) -> some View {
        Group {
            if !trip.thumbnailName.isEmpty, let _ = UIImage(named: trip.thumbnailName) {
                Image(trip.thumbnailName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    HiTripColor.gray200
                    Image(systemName: "airplane")
                        .font(.system(size: 24))
                        .foregroundColor(HiTripColor.gray400)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)

            Text("등록된 일정이 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Text("여행 일정을 추가해보세요!")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
        }
    }
}
