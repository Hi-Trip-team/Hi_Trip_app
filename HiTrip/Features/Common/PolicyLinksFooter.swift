import SwiftUI
import SafariServices

// MARK: - PolicyLinksFooter
/// 홈 맨 아래 "이용약관 · 개인정보처리방침 · 문의하기"
///
/// 동의 화면은 로그인할 때 한 번만 지나가므로, 로그인한 뒤에도 약관과 개인정보처리방침을
/// 다시 볼 수 있어야 합니다 (App Store 심사에서 확인하는 항목).
/// 여행객 홈과 안내사 홈이 함께 씁니다.

struct PolicyLinksFooter: View {

    @State private var webURL: URL?
    /// 메일 앱이 없을 때 주소를 직접 보여줍니다
    @State private var showInquiryFallback = false

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let terms = AppLinks.terms(.service) {
                linkButton("이용약관") { webURL = terms }
                separator
            }
            if let privacy = AppLinks.privacyPolicy {
                linkButton("개인정보처리방침") { webURL = privacy }
                separator
            }
            linkButton("문의하기") { openInquiry() }
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: Binding(get: { webURL != nil }, set: { if !$0 { webURL = nil } })) {
            if let webURL {
                PolicySafariView(url: webURL).ignoresSafeArea()
            }
        }
        .alert("문의하기", isPresented: $showInquiryFallback) {
            if let email = AppLinks.inquiryEmail {
                Button("주소 복사") { UIPasteboard.general.string = email }
            }
            Button("닫기", role: .cancel) { }
        } message: {
            Text("메일 앱이 없어 바로 열 수 없어요.\n\(AppLinks.inquiryEmail ?? "")로 문의해주세요.\n계정·개인정보 삭제도 이 주소로 요청할 수 있어요.")
        }
    }

    private func linkButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .underline()
        }
        .buttonStyle(.plain)
    }

    private var separator: some View {
        Text("·")
            .font(AppFont.caption)
            .foregroundColor(AppColor.textTertiary)
    }

    /// 메일 앱을 열 수 없으면 주소를 안내합니다
    private func openInquiry() {
        guard let url = AppLinks.inquiry, UIApplication.shared.canOpenURL(url) else {
            showInquiryFallback = true
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - 약관 웹뷰

private struct PolicySafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
