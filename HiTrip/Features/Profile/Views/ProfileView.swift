import SwiftUI

// MARK: - ProfileView
/// 프로필 메인 화면 — 피그마 디자인
///
/// UI 구성:
/// - 네비바: 뒤로가기 + "프로필" + 편집 아이콘
/// - 프로필 아바타 (분홍 원형 배경)
/// - 이름 + 이메일
/// - 통계 카드 (포인트, 여행, 버킷리스트)
/// - 메뉴 리스트 (프로필, 북마크, 여행, 설정, 버전정보)

struct ProfileView: View {

    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()

    /// 로그아웃 확인 Alert
    @State private var showLogoutAlert = false

    /// 프로필 수정 화면 이동
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                HiTripColor.screenBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // 프로필 헤더 (아바타 + 이름 + 이메일)
                        profileHeader
                            .padding(.top, 20)

                        // 통계 카드
                        statsCard
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        // 메뉴 리스트
                        menuList
                            .padding(.top, 28)

                        // 로그아웃
                        logoutButton
                            .padding(.top, 16)
                            .padding(.horizontal, 24)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(HiTripColor.textBlack)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showEditProfile = true } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(HiTripColor.primary800)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    }
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                ProfileEditView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadProfile()
            }
            .alert("로그아웃", isPresented: $showLogoutAlert) {
                Button("로그아웃", role: .destructive) {
                    KeychainManager.shared.clearAll()
                    router.navigateToLogin()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("로그아웃 하시겠습니까?")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 8) {
            // 아바타 (분홍 원형 배경 + 이모지)
            ZStack {
                Circle()
                    .fill(Color(hex: "FADADD").opacity(0.5))
                    .frame(width: 110, height: 110)

                Text("🙋‍♀️")
                    .font(.system(size: 56))
            }

            // 이름
            Text(viewModel.userName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
                .padding(.top, 8)

            // 이메일
            Text(viewModel.userEmail)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(title: "포인트", value: viewModel.pointsText)

            Divider()
                .frame(height: 40)

            statItem(title: "여행", value: viewModel.tripCountText)

            Divider()
                .frame(height: 40)

            statItem(title: "버킷리스트", value: viewModel.bucketListCountText)
        }
        .padding(.vertical, 18)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.gray500)

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.primary800)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Menu List

    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(icon: "person.crop.circle", title: "프로필") {
                showEditProfile = true
            }

            menuDivider

            menuRow(icon: "bookmark", title: "북마크") { }

            menuDivider

            menuRow(icon: "airplane", title: "여행") { }

            menuDivider

            menuRow(icon: "gearshape", title: "설정") { }

            menuDivider

            menuRow(icon: "info.circle", title: "버전정보") { }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .padding(.horizontal, 24)
    }

    private func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(HiTripColor.gray500)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(HiTripColor.textBlack)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray300)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }

    private var menuDivider: some View {
        Divider()
            .padding(.leading, 62)
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button {
            showLogoutAlert = true
        } label: {
            Text("로그아웃")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
    }

}
