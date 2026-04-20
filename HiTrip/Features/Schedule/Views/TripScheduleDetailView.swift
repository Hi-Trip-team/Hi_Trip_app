import SwiftUI

// MARK: - TripScheduleDetailView
/// 내 일정 상세 보기 — SpotDetailView와 동일한 레이아웃
///
/// 구성:
/// - 헤더 이미지 (썸네일)
/// - 제목 + 유형 태그
/// - 날짜 정보
/// - 위치 정보
/// - 멤버 정보

struct TripScheduleDetailView: View {

    let trip: Trip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 헤더 이미지
                    headerImage

                    VStack(alignment: .leading, spacing: 16) {
                        // 제목 + 태그
                        titleSection

                        Divider()

                        // 날짜
                        infoRow(
                            icon: "calendar",
                            title: "날짜",
                            content: formattedDate
                        )

                        // 위치
                        if !trip.location.isEmpty {
                            infoRow(
                                icon: "mappin.and.ellipse",
                                title: "위치",
                                content: trip.location
                            )
                        }

                        // 멤버
                        if !trip.memberAvatars.isEmpty {
                            infoRow(
                                icon: "person.2.fill",
                                title: "참여 멤버",
                                content: "\(trip.memberAvatars.count)명"
                            )
                        }

                        Divider()

                        // 체크리스트/캘린더로 이동 버튼
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            HStack(spacing: 10) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)

                                Text("할일 / 캘린더 보기")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(HiTripColor.primary800)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle(trip.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header Image

    private var headerImage: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(
                LinearGradient(
                    colors: [HiTripColor.primary800.opacity(0.4), HiTripColor.secondary300],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 220)
            .overlay(
                Image(systemName: thumbnailIcon)
                    .font(.system(size: 48))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trip.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textGrayA)

            Text("여행 일정")
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.primary800)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(HiTripColor.secondary100)
                .cornerRadius(6)
        }
    }

    // MARK: - Info Row (SpotDetailView 동일 패턴)

    private func infoRow(icon: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(HiTripColor.primary800)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray400)

                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(HiTripColor.textGrayA)
            }
        }
    }

    // MARK: - Helpers

    private var thumbnailIcon: String {
        switch trip.thumbnailName {
        case "mountain": return "mountain.2.fill"
        case "building": return "building.2.fill"
        case "beach":    return "water.waves"
        default:         return "photo.fill"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: trip.date)
    }
}
