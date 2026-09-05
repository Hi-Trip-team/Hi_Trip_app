import SwiftUI

struct TripListView: View {

    @StateObject private var viewModel = TravelerHomeViewModel()
    @EnvironmentObject var router: AppRouter

    @State private var showTripDetail = false
    @State private var showEmergency = false
    @State private var showLocalLanguage = false
    @State private var showChat = false
    @State private var showNotice = false
    @State private var showNearbySpot = false
    @State private var showNotificationList = false
    @State private var selectedSpot: TravelerSpotDTO?

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case .failed(let message):
                    errorView(message)
                case .loaded:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            headerSection
                            todayScheduleSection
                            nearbySpotSection
                            noticeSection
                            localLanguageCard
                            bottomActionRow
                                .padding(.bottom, 32)
                        }
                    }
                }

                if showNotice {
                    NoticePopupView(isPresented: $showNotice)
                }

                // 긴급 즉시 연락 — 별도 화면이 아니라 홈 위에 겹칩니다
                if showEmergency {
                    EmergencyCallDialog(
                        isPresented: $showEmergency,
                        phoneNumber: viewModel.managerPhone
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showNotice)
            .animation(.easeInOut(duration: 0.2), value: showEmergency)
            .background(Color.white)
            .navigationBarHidden(true)
            .task { viewModel.load() }
            .navigationDestination(isPresented: $showTripDetail) { TripDetailView() }
            .navigationDestination(isPresented: $showLocalLanguage) { LocalLanguageView() }
            .navigationDestination(isPresented: $showChat) {
                TouristChatListView(viewModel: AppDIContainer.shared.makeChatViewModel())
            }
            .navigationDestination(isPresented: $showNearbySpot) { NearbySpotView() }
            .navigationDestination(isPresented: $showNotificationList) { TouristNotificationListView() }
            .navigationDestination(item: $selectedSpot) { spot in
                NearbySpotDetailView(
                    name: spot.title,
                    address: spot.place.address,
                    description: spot.description,
                    imageUrl: spot.imageUrl,
                    latitude: spot.place.latitude.flatMap(Double.init),
                    longitude: spot.place.longitude.flatMap(Double.init),
                    categoryName: spot.place.categoryName
                )
            }
        }
    }

    // MARK: - 로딩 / 에러

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("여행 정보를 불러오는 중이에요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text("🧭")
                .font(.system(size: 34))
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
                .multilineTextAlignment(.center)
            Button { viewModel.load() } label: {
                Text("다시 시도")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text(viewModel.tripTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            ZStack(alignment: .topTrailing) {
                Text("🔔")
                    .font(.system(size: 18))
                if viewModel.hasUnreadNotice {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        Text("\(viewModel.unreadNoticeCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 6, y: -4)
                }
            }
            .onTapGesture { showNotificationList = true }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - 오늘의 일정

    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("오늘의 일정")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            if viewModel.isBeforeTrip {
                beforeTripCard
            } else {
                inTripSchedule
            }

            // 전체일정 링크
            Button { showTripDetail = true } label: {
                Text("전체일정 확인 및 개인 일정 수정하기  >")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#2563EB"))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 22)
        }
    }

    // MARK: - 여행 시작 전

    private var beforeTripCard: some View {
        VStack(spacing: 6) {
            Text("여행 시작 전이에요")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#2563EB"))
            Text(viewModel.departureText)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(Color(hex: "#E8F0FF"))
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }

    // MARK: - 여행 중

    private var inTripSchedule: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 진행률 바 + 버스 이모지 — 오늘 일정의 경과 비율
            GeometryReader { geo in
                let filled = geo.size.width * viewModel.progress
                VStack(alignment: .leading, spacing: 4) {
                    Text("🚌")
                        .font(.system(size: 16))
                        .offset(x: max(filled - 8, 0))
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#E5E7EB"))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#2563EB"))
                            .frame(width: filled, height: 4)
                    }
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)

            // 현재 일정
            if let current = viewModel.currentSchedule {
                HStack {
                    Text(TravelerHomeViewModel.title(of: current))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#111827"))
                    Spacer()
                    Text(TravelerHomeViewModel.timeRange(current.startTime, current.endTime))
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            } else {
                Text(viewModel.todayState == .finished
                     ? "오늘 일정이 모두 끝났어요"
                     : "오늘은 예정된 일정이 없어요")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }

            // 다음 일정 — 없으면 레이블째 숨김
            if let next = viewModel.nextSchedule {
                Text("다음 일정")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                HStack {
                    Text(TravelerHomeViewModel.title(of: next))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#111827"))
                    Spacer()
                    Text(TravelerHomeViewModel.timeRange(next.startTime, next.endTime))
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - 주변 인기 스팟

    private var nearbySpotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주변 인기 스팟")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.popularSpots) { spot in
                        spotCard(spot)
                            .onTapGesture { selectedSpot = spot }
                    }
                }
                .padding(.horizontal, 24)
            }

            Button { showNearbySpot = true } label: {
                Text("가이드의 추천 스팟 더보기  >")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#2563EB"))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 2)
            .padding(.bottom, 20)
        }
    }

    private func spotCard(_ spot: TravelerSpotDTO) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                SpotImageView(
                    imageUrl: spot.imageUrl,
                    categoryName: spot.place.categoryName,
                    iconSize: 26
                )
                .frame(width: 150, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if spot.isSponsored == true {
                    Text("광고")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .background(Color(hex: "#1A1A1A"))
                        .cornerRadius(4)
                        .padding(6)
                }
            }
            Text(spot.title)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#333840"))
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
        }
    }

    // MARK: - 공지

    @ViewBuilder
    private var noticeSection: some View {
        if let notice = viewModel.representativeNotice {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 10) {
                Text("공지")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(4)
                Text(notice.content)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#333840"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#F3F4F6"))
            .cornerRadius(12)

            if notice.isRead != true {
                Circle()
                    .fill(Color(hex: "#EF4444"))
                    .frame(width: 8, height: 8)
                    .offset(x: -8, y: 8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showNotice = true }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
        }
    }

    // MARK: - 현지 언어 카드

    private var localLanguageCard: some View {
        Button { showLocalLanguage = true } label: {
            HStack {
                Text("🗣  주로 사용하는 현지말")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#2563EB"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(hex: "#E8F0FF"))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }

    // MARK: - 하단 액션 버튼

    private var bottomActionRow: some View {
        HStack(spacing: 12) {
            Button { showEmergency = true } label: {
                Text("긴급 즉시 연락")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#EF4444"), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            ZStack(alignment: .topTrailing) {
                Button { showChat = true } label: {
                    Text("메시지 및 문의")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#111827"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                if viewModel.hasUnreadMessage {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#EF4444"))
                            .frame(width: 20, height: 20)
                        Text("\(viewModel.unreadMessageCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -4, y: -4)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}


