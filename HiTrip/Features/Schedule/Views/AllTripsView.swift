import SwiftUI

// MARK: - AllTripsView
/// 전체 일정 보기 — "View all"에서 진입
///
/// 위치(지역)별로 그룹핑하여 모든 여행을 한 눈에 확인
/// - 위치별 섹션 헤더 + 카드 리스트
/// - 카드 탭 → TripDetailView (할일/캘린더)로 이동

struct AllTripsView: View {

    @ObservedObject private var store = TripDataStore.shared
    @Environment(\.dismiss) private var dismiss

    /// Store에서 직접 참조
    private var trips: [Trip] { store.sortedTrips }

    /// 그룹핑: location → [Trip]
    private var groupedTrips: [(location: String, trips: [Trip])] {
        let dict = Dictionary(grouping: trips) { trip in
            trip.location.isEmpty ? "기타" : trip.location
        }
        return dict
            .map { (location: $0.key, trips: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.location < $1.location }
    }

    var body: some View {
        ZStack {
            HiTripColor.screenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 상단 요약
                    summaryHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    // 위치별 섹션
                    ForEach(groupedTrips, id: \.location) { group in
                        locationSection(location: group.location, trips: group.trips)
                    }

                    Spacer().frame(height: 24)
                }
            }
        }
        .navigationTitle("전체 일정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("총 \(trips.count)개의 일정")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("\(groupedTrips.count)개 지역")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
        }
    }

    // MARK: - Location Section

    private func locationSection(location: String, trips: [Trip]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 위치 헤더
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(HiTripColor.primary800)

                Text(location)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                Text("\(trips.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HiTripColor.primary800)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(HiTripColor.secondary100)
                    .cornerRadius(10)

                Spacer()
            }
            .padding(.horizontal, 24)

            // 카드들
            ForEach(trips) { trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    allTripCard(trip)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Trip Card

    private func allTripCard(_ trip: Trip) -> some View {
        HStack(spacing: 14) {
            // 썸네일
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [HiTripColor.primary800.opacity(0.3), HiTripColor.secondary300],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: thumbnailIcon(trip))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                Text(formattedDate(trip.date))
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray500)

                if !trip.memberAvatars.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                        Text("\(trip.memberAvatars.count)명 참여")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(HiTripColor.gray400)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray300)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Helpers

    private func thumbnailIcon(_ trip: Trip) -> String {
        switch trip.thumbnailName {
        case "mountain": return "mountain.2.fill"
        case "building": return "building.2.fill"
        case "beach":    return "water.waves"
        default:         return "photo.fill"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}
