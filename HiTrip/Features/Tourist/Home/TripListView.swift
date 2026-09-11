import SwiftUI

struct TripListView: View {

    @StateObject private var viewModel = TravelerHomeViewModel()

    /// 메시지 화면 전용 ViewModel
    ///
    /// navigationDestination 클로저 안에서 만들면 이 화면이 다시 그려질 때마다
    /// 새 인스턴스가 생겨 입력 중이던 메시지가 사라집니다. 여기서 한 번만 만듭니다.
    @StateObject private var chatViewModel = AppDIContainer.shared.makeChatViewModel()
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
                                .padding(.bottom, AppSpacing.xxl)
                        }
                    }
                    .refreshable { viewModel.refresh() }
                }

                if showNotice, let notice = viewModel.representativeNotice {
                    NoticePopupView(
                        isPresented: $showNotice,
                        notice: notice,
                        previousNotices: viewModel.previousNotices
                    )
                }

                // 긴급 즉시 연락 — 별도 화면이 아니라 홈 위에 겹칩니다
                if showEmergency {
                    EmergencyCallDialog(
                        isPresented: $showEmergency,
                        phoneNumber: viewModel.managerPhone,
                        onMessageGuide: { showChat = true }
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
                TouristChatListView(viewModel: chatViewModel)
            }
            .navigationDestination(isPresented: $showNearbySpot) { NearbySpotView() }
            .navigationDestination(isPresented: $showNotificationList) { TouristNotificationListView() }
            .navigationDestination(item: $selectedSpot) { spot in
                NearbySpotDetailView(
                    name: spot.title,
                    address: spot.place.address,
                    description: spot.description,
                    imageUrl: spot.imageUrl,
                    isSponsored: spot.isSponsored == true,
                    latitude: spot.place.latitude.flatMap(Double.init),
                    longitude: spot.place.longitude.flatMap(Double.init),
                    categoryName: spot.place.categoryName
                )
            }
        }
    }

    // MARK: - 로딩 / 에러

    private var loadingView: some View {
        TouristHomeSkeleton()
    }

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) { viewModel.load() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text(viewModel.tripTitle)
                .font(AppFont.headlineBold)
                .foregroundColor(.black)
            Spacer()
            ZStack(alignment: .topTrailing) {
                Text("🔔")
                    .font(AppFont.title3)
                if viewModel.hasUnreadNotice {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        Text("\(viewModel.unreadNoticeCount)")
                            .font(AppFont.caption2Bold)
                            .foregroundColor(.white)
                    }
                    .offset(x: 6, y: -4)
                }
            }
            .onTapGesture { showNotificationList = true }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
    }

    // MARK: - 오늘의 일정

    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 여행 중에는 진행률 카드가 먼저 오고 그 아래에 제목이 붙습니다.
            // 시작 전·종료 후에는 카드가 없어 제목이 맨 위입니다.
            switch viewModel.phase {
            case .before:
                sectionTitle
                beforeTripCard
            case .finished:
                sectionTitle
                finishedTripCard
            case .during:
                inTripSchedule
            }

            // 전체일정 링크
            Button { showTripDetail = true } label: {
                Text("전체일정 확인 및 개인 일정 수정하기  >")
                    .font(AppFont.labelMedium)
                    .foregroundColor(AppColor.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, 14)
            .padding(.bottom, 22)
        }
    }

    private var sectionTitle: some View {
        Text("오늘의 일정")
            .font(AppFont.bodyLBold)
            .foregroundColor(AppColor.textPrimary)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.md)
    }

    // MARK: - 여행 시작 전

    private var beforeTripCard: some View {
        VStack(spacing: 6) {
            Text("여행 시작 전이에요")
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.accent)
            Text(viewModel.departureText)
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(AppColor.accentSubtle)
        .cornerRadius(AppRadius.lg)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - 여행 종료 후

    private var finishedTripCard: some View {
        VStack(spacing: 6) {
            Text("여행이 종료되었습니다")
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
            Text("여행 정보와 계정은 \(viewModel.dataPurgeDateText)에 파기됩니다")
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.lg)
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - 여행 중

    private var inTripSchedule: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 여행 진행률 카드
            TripProgressCard(
                progress: viewModel.todayProgress,
                remainingDays: viewModel.tripTotalDays - viewModel.todayDayNumber,
                destination: viewModel.destinationText
            )            .padding(.horizontal, 21)
            .padding(.bottom, AppSpacing.lg)

            sectionTitle

            // 현재 일정
            if let current = viewModel.currentSchedule {
                HStack {
                    Text(TravelerHomeViewModel.title(of: current))
                        .font(AppFont.bodyMMedium)
                        .foregroundColor(AppColor.textPrimary)
                    Spacer()
                    Text(TravelerHomeViewModel.timeRange(current.startTime, current.endTime))
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 64)
                .background(AppColor.surface)
                .cornerRadius(AppRadius.lg)
                .padding(.horizontal, AppSpacing.xl)
                .contentShape(Rectangle())
                .onTapGesture { showTripDetail = true }
            } else {
                Text(viewModel.todayState == .finished
                     ? "오늘 일정이 모두 끝났어요"
                     : "오늘은 등록된 일정이 없어요")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.lg)
                    .padding(.horizontal, AppSpacing.xl)
            }

            // 다음 일정 — 없으면 레이블째 숨김
            if let next = viewModel.nextSchedule {
                Text("다음 일정")
                    .font(AppFont.label)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                HStack {
                    Text(TravelerHomeViewModel.title(of: next))
                        .font(AppFont.bodyMedium)
                        .foregroundColor(AppColor.textPrimary)
                    Spacer()
                    Text(TravelerHomeViewModel.timeRange(next.startTime, next.endTime))
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 48)
                .background(AppColor.surface)
                .cornerRadius(AppRadius.lg)
                .contentShape(Rectangle())
                .onTapGesture { showTripDetail = true }
                .padding(.horizontal, AppSpacing.xl)
            }
        }
    }

    // MARK: - 주변 인기 스팟

    @ViewBuilder
    private var nearbySpotSection: some View {
        // 스팟이 없으면 섹션째 숨깁니다
        if !viewModel.popularSpots.isEmpty {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("주변 인기 스팟")
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.popularSpots) { spot in
                        spotCard(spot)
                            .onTapGesture { selectedSpot = spot }
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
            }

            Button { showNearbySpot = true } label: {
                Text("가이드의 추천 스팟 더보기  >")
                    .font(AppFont.labelMedium)
                    .foregroundColor(AppColor.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, 2)
            .padding(.bottom, AppSpacing.lg)
        }
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
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                if spot.isSponsored == true {
                    Text("광고")
                        .font(AppFont.microMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.xs)
                        .frame(height: 20)
                        .background(AppColor.ink)
                        .cornerRadius(4)
                        .padding(6)
                }
            }
            Text(spot.title)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textBody)
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
                    .font(AppFont.caption2Medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xs)
                    .frame(height: 20)
                    .background(AppColor.accent)
                    .cornerRadius(4)
                Text(notice.content)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textBody)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.lg)

            if notice.isRead != true {
                Circle()
                    .fill(AppColor.danger)
                    .frame(width: 8, height: 8)
                    .offset(x: -8, y: 8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.markNoticeRead(notice)
            showNotice = true
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, 10)
        } else {
            Text("등록된 공지가 없어요")
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .padding(.horizontal, 14)
                .frame(minHeight: 58)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.surface)
                .cornerRadius(AppRadius.lg)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, 10)
        }
    }

    // MARK: - 현지 언어 카드

    private var localLanguageCard: some View {
        Button { showLocalLanguage = true } label: {
            HStack {
                Text("🗣  주로 사용하는 현지말")
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.accent)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 56)
            .background(AppColor.accentSubtle)
            .cornerRadius(AppRadius.lg)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, 14)
    }

    // MARK: - 하단 액션 버튼

    private var bottomActionRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Button { showEmergency = true } label: {
                Text("긴급 즉시 연락")
                    .font(AppFont.bodyBold)
                    .foregroundColor(AppColor.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color.white)
                    .cornerRadius(AppRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColor.danger, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            ZStack(alignment: .topTrailing) {
                Button { showChat = true } label: {
                    Text("메시지 및 문의")
                        .font(AppFont.bodyMedium)
                        .foregroundColor(AppColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.lg)
                }
                .buttonStyle(.plain)

                if viewModel.hasUnreadMessage {
                    CountBadge(text: viewModel.unreadMessageBadgeText, diameter: 20)
                        .offset(x: -4, y: -4)
                }
            }
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}


