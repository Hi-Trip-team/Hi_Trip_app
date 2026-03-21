import SwiftUI

// MARK: - ProfileView
/// 프로필 화면
///
/// UI 구성:
/// - 프로필 아바타 (이니셜 원형 뱃지)
/// - 사용자 정보 (이름, 아이디, 유저 타입)
/// - 메뉴 섹션 (알림 설정, 이용약관, 버전 정보)
/// - 로그아웃 버튼
///
/// 현재는 Keychain에 저장된 정보로 표시
/// 서버 연동 후 API에서 받아온 정보로 교체 예정

struct ProfileView: View {

    @EnvironmentObject var router: AppRouter

    /// 로그아웃 확인 Alert 표시 여부
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // 프로필 헤더
                profileHeader
                    .listRowBackground(Color.clear)

                // 계정 정보
                accountSection

                // 앱 설정
                settingsSection

                // 앱 정보
                appInfoSection

                // 로그아웃
                logoutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("프로필")
            // 로그아웃 확인 Alert
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

    /// 프로필 아바타 + 이름 + 유저 타입 뱃지
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // 아바타 (이니셜 표시)
            ZStack {
                Circle()
                    .fill(HiTripColor.primary800)
                    .frame(width: 80, height: 80)

                Text(avatarInitial)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }

            // 사용자 이름
            Text(userName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            // 유저 타입 뱃지 (안내사/관광객)
            Text(userTypeBadge)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(HiTripColor.primary800)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(HiTripColor.secondary100)
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Account Section

    /// 계정 정보 섹션
    private var accountSection: some View {
        Section("계정 정보") {
            // 아이디
            HStack {
                Label("아이디", systemImage: "person.text.rectangle")
                    .foregroundColor(HiTripColor.textGrayA)
                Spacer()
                Text(userId)
                    .foregroundColor(HiTripColor.gray500)
            }

            // 유저 타입
            HStack {
                Label("유형", systemImage: "person.crop.rectangle")
                    .foregroundColor(HiTripColor.textGrayA)
                Spacer()
                Text(userTypeBadge)
                    .foregroundColor(HiTripColor.gray500)
            }
        }
    }

    // MARK: - Settings Section

    /// 앱 설정 섹션 (Phase 6에서 실제 동작 연결)
    private var settingsSection: some View {
        Section("설정") {
            // 알림 설정
            NavigationLink {
                placeholderView("알림 설정", phase: 6)
            } label: {
                Label("알림 설정", systemImage: "bell")
                    .foregroundColor(HiTripColor.textGrayA)
            }

            // 언어 설정
            NavigationLink {
                placeholderView("언어 설정", phase: 6)
            } label: {
                Label("언어", systemImage: "globe")
                    .foregroundColor(HiTripColor.textGrayA)
            }
        }
    }

    // MARK: - App Info Section

    /// 앱 정보 섹션
    private var appInfoSection: some View {
        Section("앱 정보") {
            // 이용약관
            NavigationLink {
                placeholderView("이용약관", phase: 6)
            } label: {
                Label("이용약관", systemImage: "doc.text")
                    .foregroundColor(HiTripColor.textGrayA)
            }

            // 개인정보처리방침
            NavigationLink {
                placeholderView("개인정보처리방침", phase: 6)
            } label: {
                Label("개인정보처리방침", systemImage: "lock.shield")
                    .foregroundColor(HiTripColor.textGrayA)
            }

            // 버전 정보
            HStack {
                Label("버전", systemImage: "info.circle")
                    .foregroundColor(HiTripColor.textGrayA)
                Spacer()
                Text(appVersion)
                    .foregroundColor(HiTripColor.gray400)
            }
        }
    }

    // MARK: - Logout Section

    /// 로그아웃 버튼
    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutAlert = true
            } label: {
                HStack {
                    Spacer()
                    Text("로그아웃")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Placeholder View

    /// Phase 6에서 구현 예정인 상세 화면
    private func placeholderView(_ title: String, phase: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(HiTripColor.textGrayA)
            Text("Phase \(phase)에서 구현 예정")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
            Spacer()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Helpers

    /// Keychain에서 사용자 이름 조회 (없으면 기본값)
    private var userName: String {
        KeychainManager.shared.getUserId() ?? "Hi Trip 사용자"
    }

    /// 아바타 이니셜 (이름 첫 글자)
    private var avatarInitial: String {
        String(userName.prefix(1))
    }

    /// 사용자 아이디
    private var userId: String {
        KeychainManager.shared.getUserId() ?? "-"
    }

    /// 유저 타입 표시 텍스트
    private var userTypeBadge: String {
        guard let type = KeychainManager.shared.getUserType() else { return "미설정" }
        return type == "guide" ? "안내사" : "관광객"
    }

    /// 앱 버전 (Bundle에서 자동 조회)
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
