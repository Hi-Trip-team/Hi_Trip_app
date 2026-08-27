import SwiftUI

// MARK: - StaffDashboardView
/// 여행사(Staff/Guide) 전체 일정 화면
///
/// 피그마 0827 여행사 앱 플로우:
/// 전체 일정 → 지도 범위 설정 → 안전관리 → 관광객 정보 랍업 → 관광객 위치 확인 → 고객 관리 → 알림 센터

struct StaffDashboardView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = TripListViewModel()

    @State private var showMapRange = false
    @State private var showSafety = false
    @State private var showTouristInfo = false
    @State private var showTouristLocation = false
    @State private var showChat = false
    @State private var showNotification = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    menuGrid
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 32)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showMapRange) {
                MapRangeSettingView()
            }
            .navigationDestination(isPresented: $showChat) {
                ChatListView(viewModel: AppDIContainer.shared.makeChatViewModel())
            }
            .navigationDestination(isPresented: $showNotification) {
                NotificationCenterView()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("전체 일정")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
                Text("투어 관리 현황을 확인하세요")
                    .font(HiTripFont.body)
                    .foregroundColor(HiTripColor.gray500)
            }
            Spacer()
            Button {
                showNotification = true
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(HiTripColor.textBlack)
            }
        }
    }

    // MARK: - Menu Grid

    private var menuGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            menuCard(
                icon: "map",
                title: "지도 범위 설정",
                subtitle: "관광 구역 설정",
                color: HiTripColor.primary800
            ) { showMapRange = true }

            menuCard(
                icon: "shield.checkered",
                title: "안전관리",
                subtitle: "여행객 안전 현황",
                color: Color(hex: "#E85D5D")
            ) { showSafety = true }

            menuCard(
                icon: "person.text.rectangle",
                title: "관광객 정보",
                subtitle: "참여자 정보 확인",
                color: Color(hex: "#F0A500")
            ) { showTouristInfo = true }

            menuCard(
                icon: "location.circle",
                title: "위치 확인",
                subtitle: "실시간 위치 현황",
                color: Color(hex: "#34A853")
            ) { showTouristLocation = true }

            menuCard(
                icon: "bubble.left.and.bubble.right",
                title: "고객 관리",
                subtitle: "메시지 및 문의",
                color: HiTripColor.primary800
            ) { showChat = true }

            menuCard(
                icon: "bell.badge",
                title: "알림 센터",
                subtitle: "안전·이탈 알림",
                color: Color(hex: "#FF6B35")
            ) { showNotification = true }
        }
    }

    private func menuCard(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HiTripFont.bodyBold)
                        .foregroundColor(HiTripColor.textBlack)
                    Text(subtitle)
                        .font(HiTripFont.caption)
                        .foregroundColor(HiTripColor.gray500)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(HiTripSpacing.mdl)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
        }
        .buttonStyle(.plain)
    }
}
