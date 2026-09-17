import SwiftUI
import RxSwift

// MARK: - LogoutButton
/// 홈 맨 아래 로그아웃 — 회색 caption 글자
///
/// 확인 후 서버 로그아웃(`/tourist/logout/` 또는 안내사 로그아웃)을 기다렸다가 로그인 화면으로 갑니다.
/// 관광객·안내사 홈이 함께 씁니다.

struct LogoutButton: View {

    @EnvironmentObject private var router: AppRouter
    @State private var showConfirm = false
    @State private var isLoggingOut = false
    @State private var disposeBag = DisposeBag()

    var body: some View {
        Button { showConfirm = true } label: {
            Text(isLoggingOut ? "로그아웃 중…" : "로그아웃")
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .underline()
                .padding(.vertical, AppSpacing.xs)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoggingOut)
        .confirmationDialog("로그아웃할까요?", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) { logout() }
            Button("취소", role: .cancel) { }
        }
    }

    private func logout() {
        isLoggingOut = true
        AppDIContainer.shared.makeLoginUseCase().logout()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: {
                isLoggingOut = false
                router.navigateToLogin()
            })
            .disposed(by: disposeBag)
    }
}
