import SwiftUI

// MARK: - SplashView
/// 스플래시 화면
///
/// 디자인: 파란 배경(#0C46C0) + 흰색 "Hi Trip" 중앙 배치
///
/// 동작 흐름:
/// 1. 화면 표시 → 0.8초 fade-in + scale 애니메이션
/// 2. 1.5초 후 Keychain 토큰 확인
/// 3. 토큰 있음 → HomeView, 토큰 없음 → LoginView

struct SplashView: View {

    @EnvironmentObject var router: AppRouter
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 배경: Primary 800 (#0C46C0)
            HiTripColor.splashBackground
                .ignoresSafeArea()

            // 로고 텍스트
            Text("Hi Trip")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)
        }
        .onAppear {
            // fade-in + scale 애니메이션
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }

            // 1.5초 후 자동 로그인 판단
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                router.handleAutoLogin(
                    isLoggedIn: KeychainManager.shared.isLoggedIn
                )
            }
        }
    }
}
