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
    /// 일정 상세에서 처음 펼칠 일차 — nil이면 여행 중일 때 오늘 일차
    @State private var tripDetailFocusDay: Int?
    @State private var showEmergency = false
    @State private var showLocalLanguage = false
    @State private var showChat = false
    @State private var showNotice = false
    @State private var showNearbySpot = false
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
                            // 섹션(일정 · 주변 인기 스팟 · 공지/현지말) 사이 간격
                            todayScheduleSection
                                .padding(.bottom, AppSpacing.xs)
                            nearbySpotSection
                                .padding(.bottom, AppSpacing.xs)
                            noticeSection
                            localLanguageCard
                            bottomActionRow
                            LogoutButton()
                                .padding(.top, AppSpacing.xl)
                                .padding(.bottom, AppSpacing.xs)
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
                        // 통역 번호가 비어 있으면 담당 안내사 번호로 연결합니다
                        phoneNumber: AppLinks.interpreterPhone ?? viewModel.managerPhone,
                        onMessageGuide: { showChat = true }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showNotice)
            .animation(.easeInOut(duration: 0.2), value: showEmergency)
            .background(Color.white)
            .navigationBarHidden(true)
            .task { viewModel.load() }
            .navigationDestination(isPresented: $showTripDetail) { TripDetailView(focusDay: tripDetailFocusDay) }
            // 일정 화면에서 개인 일정을 추가·수정·삭제하고 돌아오면 홈 일정 칸도 바로 반영합니다
            .onChange(of: showTripDetail) { isShown in
                if !isShown { viewModel.reloadPersonalSchedules() }
            }
            .navigationDestination(isPresented: $showLocalLanguage) { LocalLanguageView() }
            .navigationDestination(isPresented: $showChat) {
                TouristChatListView(viewModel: chatViewModel)
            }
            .navigationDestination(isPresented: $showNearbySpot) { NearbySpotView() }
            .navigationDestination(unwrapping: $selectedSpot) { spot in
                NearbySpotDetailView(
                    name: spot.title,
                    address: spot.place.address,
                    description: spot.description,
                    imageUrl: spot.imageUrl,
                    isSponsored: spot.isSponsored == true,
                    latitude: spot.place.latitude.flatMap(Double.init),
                    longitude: spot.place.longitude.flatMap(Double.init),
                    categoryName: spot.place.categoryName,
                    reason: spot.reason
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
            // 알림함(종 아이콘)은 알림 목록 API가 생길 때까지 숨깁니다 — 항상 빈 화면이라
            // 심사에서 미완성 기능으로 보일 수 있습니다. 화면(TouristNotificationListView)은 남겨 둡니다.
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
    }

    // MARK: - 오늘의 일정

    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 여행 진행률 카드 — 시작 전(D-day)·종료 후(수고하셨어요)에도 보입니다
            TripProgressCard(
                progress: viewModel.tripProgress,
                remainingDays: viewModel.tripTotalDays - viewModel.todayDayNumber,
                destination: viewModel.destinationText,
                headlineOverride: viewModel.progressHeadline,
                statusOverride: viewModel.progressStatus
            )
            .padding(.horizontal, 21)
            .padding(.bottom, AppSpacing.lg)

            sectionTitle

            switch viewModel.phase {
            case .before:
                scheduleMessage("여행 시작 전이에요 · \(viewModel.departureDateText)")
            case .finished:
                scheduleMessage("여행 정보와 계정은 \(viewModel.dataPurgeDateText)에 파기됩니다")
            case .during:
                inTripSchedule
            }

            // 전체일정 링크
            Button { openTripDetail(day: nil) } label: {
                Text("전체일정 확인 및 개인 일정 수정하기  >")
                    .font(AppFont.labelMedium)
                    .foregroundColor(AppColor.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
    }

    /// 일정 상세로 이동 — 일정을 눌렀으면 그 일정의 일차를, '전체일정 확인'이면 nil(여행 중이면 오늘 일차)을 펼칩니다
    private func openTripDetail(day: Int?) {
        tripDetailFocusDay = day
        showTripDetail = true
    }

    private var sectionTitle: some View {
        Text("오늘의 일정")
            .font(AppFont.bodyLBold)
            .foregroundColor(AppColor.textPrimary)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.md)
    }

    // MARK: - 일정 안내 문구

    /// 일정 칸 자리에 보여주는 안내 — 진행 중인 일정 없음 · 여행 시작 전 · 종료 후
    private func scheduleMessage(_ text: String) -> some View {
        Text(text)
            .font(AppFont.body)
            .foregroundColor(AppColor.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.lg)
            .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - 여행 중

    private var inTripSchedule: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 지금 진행 중인 일정(정규 우선, 없으면 내 일정) — 없으면 안내 문구. 예정 일정은 "다음 일정"에만
            if let current = viewModel.currentItem {
                homeScheduleRow(current, height: 64, titleFont: AppFont.bodyMMedium)
            } else {
                scheduleMessage(viewModel.noCurrentScheduleText)
            }

            // 다음 일정 — 정규 일정과 오늘 남은 내 일정 중 더 이른 것, 없으면 레이블째 숨김
            if let next = viewModel.nextItem {
                Text("다음 일정")
                    .font(AppFont.label)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                homeScheduleRow(next, height: 48, titleFont: AppFont.bodyMedium)
            }
        }
    }

    /// 홈 일정 한 줄 — 내 일정이면 앞에 "내 일정" 표시, 누르면 그 일정의 일차가 열립니다
    private func homeScheduleRow(_ item: TravelerHomeViewModel.HomeScheduleItem, height: CGFloat, titleFont: Font) -> some View {
        HStack(spacing: AppSpacing.xs) {
            if item.isPersonal {
                Text("내 일정")
                    .font(AppFont.caption2Bold)
                    .foregroundColor(AppColor.accent)
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(AppColor.accentSubtle)
                    .cornerRadius(AppRadius.xs)
            }
            Text(item.title)
                .font(titleFont)
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(TravelerHomeViewModel.timeRange(item.startTime, item.endTime))
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: height)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.lg)
        .contentShape(Rectangle())
        .onTapGesture { openTripDetail(day: item.dayNumber) }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - 주변 인기 스팟

    /// 섹션은 항상 보입니다 — 스팟이 없어도 사라지지 않고 로딩/없음 상태를 알려줍니다
    private var nearbySpotSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("주변 인기 스팟")
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.xl)

            spotContent

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

    @ViewBuilder
    private var spotContent: some View {
        if !viewModel.popularSpots.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.popularSpots) { spot in
                        spotCard(spot)
                            .onTapGesture { selectedSpot = spot }
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
            }
        } else if !viewModel.isSpotsLoaded {
            // 불러오는 중 — 카드 자리만 회색으로
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(AppColor.surface)
                        .frame(width: 150, height: 150)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
        } else {
            spotEmptyState
        }
    }

    /// 서버가 준 스팟이 없을 때 — 지도에서 주변 장소를 찾도록 안내합니다
    private var spotEmptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "mappin.slash")
                .font(AppFont.title3)
                .foregroundColor(AppColor.textTertiary)
            Text("아직 등록된 스팟이 없어요")
                .font(AppFont.labelMedium)
                .foregroundColor(AppColor.textBody)
            Text("아래 더보기에서 지도로 주변 장소를 찾아볼 수 있어요")
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.lg)
        .padding(.horizontal, AppSpacing.xl)
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
            // 배지와 본문을 세로 가운데로 — .top이면 한 줄 본문이 배지보다 위로 떠 보였습니다
            HStack(alignment: .center, spacing: 10) {
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


