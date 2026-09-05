import SwiftUI

struct TripListView: View {

    @StateObject private var viewModel = TripListViewModel()
    @EnvironmentObject var router: AppRouter

    @State private var showTripDetail = false
    @State private var showEmergency = false
    @State private var showLocalLanguage = false
    @State private var showChat = false
    @State private var showNotice = false
    @State private var showNearbySpot = false

    var body: some View {
        NavigationStack {
            ZStack {
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

                if showNotice {
                    NoticePopupView(isPresented: $showNotice)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showNotice)
            .background(Color.white)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showTripDetail) { TripDetailView() }
            .navigationDestination(isPresented: $showEmergency) { EmergencyView() }
            .navigationDestination(isPresented: $showLocalLanguage) { LocalLanguageView() }
            .navigationDestination(isPresented: $showChat) {
                TouristChatListView(viewModel: AppDIContainer.shared.makeChatViewModel())
            }
            .navigationDestination(isPresented: $showNearbySpot) { NearbySpotView() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("뉴진스 바다여행")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            ZStack(alignment: .topTrailing) {
                Text("🔔")
                    .font(.system(size: 18))
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                    Text("2")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 6, y: -4)
            }
            .onTapGesture { showNotice = true }
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

            if daysUntilDeparture > 0 {
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

    /// 출발까지 남은 일수 — 0 이하이면 여행 중
    private var daysUntilDeparture: Int { 0 }

    // MARK: - 여행 시작 전

    private var beforeTripCard: some View {
        VStack(spacing: 6) {
            Text("여행 시작 전이에요")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#2563EB"))
            Text("D-\(daysUntilDeparture) · 2025.04.24 출발")
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
            // 진행률 바 + 버스 이모지
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer().frame(width: 137)
                    Text("🚌")
                        .font(.system(size: 16))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#2563EB"))
                        .frame(width: 137, height: 4)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 10)

            // 현재 일정
            HStack {
                Text("숙소로 이동")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                Spacer()
                Text("15:00 - 16:00")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(Color(hex: "#F3F4F6"))
            .cornerRadius(12)
            .padding(.horizontal, 24)

            // 다음 일정 레이블
            Text("다음 일정")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 6)

            // 다음 일정
            HStack {
                Text("자유시간")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                Spacer()
                Text("16:00 - 23:00")
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

    // MARK: - 주변 인기 스팟

    private var nearbySpotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주변 인기 스팟")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(spotItems, id: \.name) { spot in
                        spotCard(spot)
                            .onTapGesture { showNearbySpot = true }
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

    private let spotItems: [SpotCardItem] = [
        SpotCardItem(name: "해운대 해수욕장"),
        SpotCardItem(name: "광안리 카페거리"),
        SpotCardItem(name: "자갈치시장"),
    ]

    private func spotCard(_ spot: SpotCardItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#D9DEE5"))
                    .frame(width: 150, height: 84)
                Text("광고")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Color(hex: "#1A1A1A"))
                    .cornerRadius(4)
                    .padding(6)
            }
            Text(spot.name)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#333840"))
        }
    }

    // MARK: - 공지

    private var noticeSection: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 10) {
                Text("공지")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(4)
                Text("오늘 자유 일정은 우천이 예상됩니다. 우산을 꼭 챙겨주세요. 집합 시간은 18:00 …")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#333840"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#F3F4F6"))
            .cornerRadius(12)

            Circle()
                .fill(Color(hex: "#EF4444"))
                .frame(width: 8, height: 8)
                .offset(x: -8, y: 8)
        }
        .contentShape(Rectangle())
        .onTapGesture { showNotice = true }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
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

                ZStack {
                    Circle()
                        .fill(Color(hex: "#EF4444"))
                        .frame(width: 20, height: 20)
                    Text("3")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: -4, y: -4)
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct SpotCardItem {
    let name: String
}
