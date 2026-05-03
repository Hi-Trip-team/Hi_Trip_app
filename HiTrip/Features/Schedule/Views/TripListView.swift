import SwiftUI

// MARK: - TripListView
/// 홈 화면 — 피그마 디자인
///
/// UI 구성:
/// - 네비바: "Hi Trip" 로고 + 알림 아이콘
/// - 주간 캘린더 스트립 (날짜 선택)
/// - "내 일정" 섹션 + "View all" 링크
/// - 여행 카드 리스트 (썸네일 + 날짜 + 제목 + 위치)
/// - 긴급 연락망 바로가기 배너

struct TripListView: View {

    @StateObject private var viewModel = TripListViewModel()
    @EnvironmentObject var router: AppRouter

    /// "View all" 클릭 → AllTripsView로 이동
    @State private var navigateToAllTrips: Bool = false

    /// 내 일정 카드 클릭 → 상세보기 (SpotDetailView 스타일)
    @State private var selectedTripForDetail: Trip?

    /// 긴급 연락 페이지 이동
    @State private var showEmergency: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                HiTripColor.screenBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // 주간 캘린더 스트립
                        calendarCard

                        // "내 일정" 헤더
                        sectionHeader
                            .padding(.top, 24)

                        // 여행 카드 리스트
                        tripCardList
                            .padding(.top, 12)

                        // 긴급 연락망 바로가기
                        emergencyBanner
                            .padding(.top, 24)
                            .padding(.horizontal, 20)

                        Spacer().frame(height: 24)
                    }
                }
            }
            // "View all" → 전체 일정 리스트
            .navigationDestination(isPresented: $navigateToAllTrips) {
                AllTripsView()
            }
            // 긴급 연락 → EmergencyView
            .navigationDestination(isPresented: $showEmergency) {
                EmergencyView(viewModel: AppDIContainer.shared.makeEmergencyViewModel())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Hi Trip")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(HiTripColor.primary800)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { } label: {
                        Image(systemName: "bell")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
            }
        }
    }

    // MARK: - Calendar Card

    private var calendarCard: some View {
        VStack(spacing: 0) {
            WeekCalendarStripView(
                selectedDate: $viewModel.selectedDate,
                style: .sundayStart
            )
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("내 일정")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            Button {
                navigateToAllTrips = true
            } label: {
                HStack(spacing: 4) {
                    Text("View all")
                        .font(.system(size: 14))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .foregroundColor(HiTripColor.secondary700)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Trip Card List

    private var tripCardList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredTrips) { trip in
                Button {
                    selectedTripForDetail = trip
                } label: {
                    TripCardRow(trip: trip)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .sheet(item: $selectedTripForDetail) { trip in
            TripScheduleDetailView(trip: trip)
        }
    }

    // MARK: - Emergency Banner

    private var emergencyBanner: some View {
        Button {
            showEmergency = true
        } label: {
            HStack(spacing: 14) {
                // 아이콘 영역
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "phone.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                // 텍스트 영역
                VStack(alignment: .leading, spacing: 4) {
                    Text("긴급 연락망")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(HiTripColor.textBlack)

                    Text("경찰·소방·의료 등 긴급 연락처 확인")
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray500)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray300)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TripCardRow

struct TripCardRow: View {

    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(formattedDate)
                        .font(.system(size: 13))
                }
                .foregroundColor(HiTripColor.gray500)

                Text(trip.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                if !trip.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text("위치: \(trip.location)")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(HiTripColor.gray400)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray300)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [HiTripColor.primary800.opacity(0.3), HiTripColor.secondary300],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: thumbnailIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            )
    }

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
