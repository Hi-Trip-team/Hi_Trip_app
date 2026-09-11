import SwiftUI

// MARK: - SplashView
/// 스플래시 화면
///
/// 판단 로직은 SplashViewModel이 맡고, 이 View는 로고·재시도·업데이트 팝업만 그립니다.

struct SplashView: View {

    @EnvironmentObject var router: AppRouter

    @StateObject private var viewModel = SplashViewModel()
    @State private var isAnimating = false
    @State private var attempt = 0

    var body: some View {
        ZStack {
            AppColor.brand
                .ignoresSafeArea()

            Text("Hi Trip")
                .font(AppFont.displayBold)
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)

            // 하단 앱 버전 — 번들의 MARKETING_VERSION을 그대로 보여줍니다
            VStack {
                Spacer()
                Text("v\(AppVersionChecker.currentVersion)")
                    .font(AppFont.caption)
                    .foregroundColor(.white)
                    .padding(.bottom, AppSpacing.xs)
            }

            if viewModel.phase == .offline {
                offlineSection
            }

            if viewModel.phase == .updateRequired {
                updatePopup
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { isAnimating = true }
        }
        .task(id: attempt) { await viewModel.start() }
        .onChange(of: viewModel.route) { route in
            switch route {
            case .login?:
                router.navigateToLogin()
            case let .home(type, requiresAgreement)?:
                router.proceedAfterLogin(as: type, requiresAgreement: requiresAgreement)
            case nil:
                break
            }
        }
    }

    // MARK: - 네트워크 미연결

    private var offlineSection: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Text("네트워크 연결을 확인해주세요")
                .font(AppFont.bodyLSemiBold)
                .foregroundColor(.white)
            Button {
                viewModel.retry()
                attempt += 1
            } label: {
                Text("재시도")
                    .font(AppFont.bodySemiBold)
                    .foregroundColor(AppColor.brand)
                    .frame(width: 120, height: 44)
                    .background(Color.white)
                    .cornerRadius(AppRadius.lg)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 80)
    }

    // MARK: - 강제 업데이트 (닫기 없음)

    private var updatePopup: some View {
        ZStack {
            DimmedBackground(opacity: 0.4)

            VStack(spacing: AppSpacing.sm) {
                Text("업데이트가 필요합니다")
                    .font(AppFont.headlineSemiBold)
                    .foregroundColor(AppColor.textPrimary)
                Text("안정적인 서비스 이용을 위해\n최신 버전으로 업데이트해주세요.")
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textGray)
                    .multilineTextAlignment(.center)
                Button {
                    if let url = AppLinks.appStore { UIApplication.shared.open(url) }
                } label: {
                    Text("업데이트")
                        .font(AppFont.bodyLSemiBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColor.brand)
                        .cornerRadius(AppRadius.lg)
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.xl)
            .background(Color.white)
            .cornerRadius(AppRadius.xl)
            .padding(.horizontal, 40)
        }
    }
}
