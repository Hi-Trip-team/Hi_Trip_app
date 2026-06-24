import SwiftUI

// MARK: - SplashView
/// 스플래시 화면
///
/// 동작 흐름:
/// 1. 화면 표시 → 0.8초 fade-in + scale 애니메이션
/// 2. 1.5초 후 인증 상태 판단
///    - Mock 모드: 자동으로 Mock 유저 주입 → HomeView
///    - Remote 모드: Keychain 토큰 확인 → 있으면 Home, 없으면 Login
///      (단, Mock 토큰이 남아 있으면 자동으로 지우고 Login으로 이동)

struct SplashView: View {

    @EnvironmentObject var router: AppRouter
    @State private var isAnimating = false

    private let mockToken = "mock-token-dev-abc123"

    var body: some View {
        ZStack {
            HiTripColor.splashBackground
                .ignoresSafeArea()

            Text("Hi Trip")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if APIEnvironment.current.useMock {
                    injectMockSession()
                    TripDataStore.shared.reload()
                    router.handleAutoLogin(isLoggedIn: true)
                } else {
                    // Remote 모드: 이전에 Mock 토큰이 남아 있으면 제거
                    let kc = KeychainManager.shared
                    if kc.getToken() == mockToken {
                        kc.clearAll()
                    }
                    let isLoggedIn = kc.isLoggedIn
                    if isLoggedIn { TripDataStore.shared.reload() }
                    router.handleAutoLogin(isLoggedIn: isLoggedIn)
                }
            }
        }
    }

    private func injectMockSession() {
        let kc = KeychainManager.shared
        kc.saveToken(mockToken)
        kc.saveUserId("42")
        kc.saveUserType("tourist")
        kc.saveUserName("홍길동")
        kc.saveUserEmail("gildong@example.com")
    }
}
