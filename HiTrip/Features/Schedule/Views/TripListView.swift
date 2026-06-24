import SwiftUI

// MARK: - TripListView
/// 홈 화면 — 여행 대시보드
///
/// 피그마 디자인:
/// - 헤더: "전체 일정 확인" + 여행 이름 pill
/// - 진행률 카드 (파란 배경, 버스 아이콘, 날씨, 참여자)
/// - 공지사항 카드
/// - 오늘의 미션 카드
/// - 오늘의 일정 (전체 보기 링크)
/// - 지금 갈만한 곳 (가로 스크롤)
/// - 여행 필수 번역 모음
/// - 긴급 연락망 배너

struct TripListView: View {

    @StateObject private var viewModel = TripListViewModel()
    @EnvironmentObject var router: AppRouter

    /// 긴급 연락 페이지 이동
    @State private var showEmergency: Bool = false

    /// 공지사항 리스트 이동
    @State private var showNoticeList: Bool = false

    /// 오늘의 일정 전체 보기 이동
    @State private var showTodaySchedule: Bool = false

    /// 선택된 스팟 상세보기
    @State private var selectedSpot: TravelerSpotDTO?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 헤더 (스크롤과 함께 이동)
                    headerSection

                    // 진행률 카드
                    progressCard

                    // 공지사항
                    noticeCard

                    // 오늘의 미션
                    missionCard

                    // 오늘의 일정
                    todayScheduleSection

                    // 내일의 일정 (있을 때만 표시)
                    if !viewModel.tomorrowSchedules.isEmpty {
                        tomorrowScheduleSection
                    }

                    // 지금 갈만한 곳
                    nearbySpotSection

                    // 여행 필수 번역 모음
                    translationCard

                    // 긴급 연락망
                    emergencyBanner

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 20)
            }
            .background(HiTripColor.screenBackground)
            .navigationDestination(isPresented: $showEmergency) {
                EmergencyView(viewModel: AppDIContainer.shared.makeEmergencyViewModel())
            }
            .navigationDestination(isPresented: $showNoticeList) {
                NoticeListView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showTodaySchedule) {
                TodayScheduleView(viewModel: viewModel)
            }
            .sheet(item: $selectedSpot) { spot in
                TravelerSpotDetailView(spot: spot)
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header Section

    /// 스크롤되는 헤더: "전체 일정 확인" + 여행 pill
    private var headerSection: some View {
        HStack {
            Text("전체 일정 확인")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            tripDayPill
        }
        .padding(.top, 12)
    }

    // MARK: - Trip Day Pill

    /// "제주 힐링여행 · 2일차" 알약 배지
    private var tripDayPill: some View {
        Text("\(viewModel.currentTripName) · \(viewModel.currentDayText)")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(HiTripColor.accentLink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(HiTripColor.accentLink, lineWidth: 1)
            )
    }

    // MARK: - Progress Card

    /// 여행 진행률 카드 (파란 배경)
    private var progressCard: some View {
        HStack(spacing: 0) {
            // 왼쪽: 버스 아이콘 + 진행률
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    // 버스 이모지
                    Text("🚌")
                        .font(.system(size: 36))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.daysRemainingText)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))

                        // 프로그레스 바
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * viewModel.progressRate, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }

                Text(viewModel.progressText)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // 오른쪽: 날씨 + 참여자
            VStack(alignment: .trailing, spacing: 6) {
                Text(viewModel.weatherLocation)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(viewModel.weatherDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))

                Spacer().frame(height: 4)

                Text(viewModel.participantsText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [HiTripColor.primary800, HiTripColor.secondary600],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }

    // MARK: - Notice Card

    /// 공지사항 카드 (탭 → 공지 리스트)
    private var noticeCard: some View {
        Button {
            showNoticeList = true
        } label: {
            infoCard(emoji: "📢", title: "공지사항", content: viewModel.noticeText)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mission Card

    /// 오늘의 미션 카드 (서비스 준비 중)
    private var missionCard: some View {
        infoCard(emoji: "🎯", title: "오늘의 미션", content: "서비스 준비 중입니다")
    }

    /// 공통 정보 카드 (공지, 미션 등)
    private func infoCard(emoji: String, title: String, content: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(emoji)
                        .font(.system(size: 14))
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(HiTripColor.textBlack)
                }

                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray500)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray300)
        }
        .hiTripCard(padding: 16)
    }

    // MARK: - Today Schedule Section

    /// 오늘의 일정 섹션
    private var todayScheduleSection: some View {
        VStack(spacing: 0) {
            // 헤더: "오늘의 일정" + "전체 보기 >"
            HStack {
                Text("오늘의 일정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)

                Spacer()

                Button {
                    showTodaySchedule = true
                } label: {
                    Text("전체 보기 >")
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.accentLink)
                }
            }
            .padding(.bottom, 12)

            // 일정 리스트 (최대 3개) 또는 빈 상태
            if viewModel.todaySchedules.isEmpty {
                Text("오늘은 일정이 없습니다.")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray400)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }

            VStack(spacing: 0) {
                ForEach(Array(viewModel.todaySchedules.prefix(3).enumerated()), id: \.element.id) { index, schedule in
                    HStack {
                        HStack(spacing: 6) {
                            Text(schedule.emoji)
                                .font(.system(size: 16))
                            Text(schedule.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(HiTripColor.textBlack)
                        }

                        Spacer()

                        Text(schedule.timeText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(HiTripColor.gray500)
                    }
                    .padding(.vertical, 14)

                    if index < min(viewModel.todaySchedules.count, 3) - 1 {
                        Divider()
                    }
                }

                // 3개 초과 시 나머지 개수 표시
                if viewModel.todaySchedules.count > 3 {
                    Button {
                        showTodaySchedule = true
                    } label: {
                        Text("+ \(viewModel.todaySchedules.count - 3)개 더 보기")
                            .font(.system(size: 13))
                            .foregroundColor(HiTripColor.accentLink)
                            .padding(.vertical, 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Tomorrow Schedule Section

    /// 내일의 일정 미리보기 섹션
    private var tomorrowScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("내일의 일정")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.tomorrowSchedules.prefix(3).enumerated()), id: \.element.id) { index, schedule in
                    HStack {
                        HStack(spacing: 6) {
                            Text(schedule.emoji)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(schedule.placeName ?? schedule.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(HiTripColor.textBlack)
                                    .lineLimit(1)
                                if let content = schedule.mainContent, schedule.placeName != nil {
                                    Text(content)
                                        .font(.system(size: 12))
                                        .foregroundColor(HiTripColor.gray500)
                                        .lineLimit(1)
                                }
                            }
                        }
                        Spacer()
                        Text(schedule.timeText)
                            .font(.system(size: 13))
                            .foregroundColor(HiTripColor.gray400)
                    }
                    .padding(.vertical, 12)

                    if index < min(viewModel.tomorrowSchedules.count, 3) - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color(hex: "B4BCC9").opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Nearby Spot Section

    private var nearbySpotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text("📍")
                    .font(.system(size: 14))
                Text("지금 갈만한 곳")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
            }

            if viewModel.nearbySpotDTOs.isEmpty {
                Text("등록된 추천 장소가 없습니다.")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray400)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.nearbySpotDTOs) { spot in
                            nearbySpotCard(spot)
                                .onTapGesture { selectedSpot = spot }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
        .hiTripCard(padding: 16)
    }

    private func nearbySpotCard(_ spot: TravelerSpotDTO) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 썸네일
            Group {
                if let url = URL(string: spot.imageUrl), !spot.imageUrl.isEmpty {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else {
                            spotPlaceholder(spot)
                        }
                    }
                } else {
                    spotPlaceholder(spot)
                }
            }
            .frame(width: 110, height: 80)
            .clipped()
            .cornerRadius(10)

            Spacer().frame(height: 6)

            // 유형 뱃지
            Text(spot.spotType == "recommended" ? "🌟 추천" : "🔥 인기")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(spot.spotType == "recommended" ? .orange : .red)

            Spacer().frame(height: 2)

            // 장소명
            Text(spot.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)
                .lineLimit(1)

            // 카테고리
            if let cat = spot.place.categoryName {
                Text(cat)
                    .font(.system(size: 11))
                    .foregroundColor(HiTripColor.gray400)
                    .lineLimit(1)
            }
        }
        .frame(width: 110)
    }

    private func spotPlaceholder(_ spot: TravelerSpotDTO) -> some View {
        ZStack {
            HiTripColor.gray200
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(HiTripColor.gray400)
        }
    }

    // MARK: - Translation Card

    /// 여행 필수 번역 모음
    private var translationCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("여행 필수 번역 모음")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)

                Text(viewModel.translationPreview)
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray500)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray300)
        }
        .hiTripCard(padding: 16)
    }

    // MARK: - Emergency Banner

    /// 긴급 연락망 바로가기
    private var emergencyBanner: some View {
        Button {
            showEmergency = true
        } label: {
            HStack(spacing: 14) {
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
            .hiTripCard(padding: 16)
        }
        .buttonStyle(.plain)
    }
}
