import SwiftUI

// MARK: - SignUpCompleteView
/// 회원가입 완료 화면
///
/// UI 구성:
/// - 체크마크 아이콘 (스케일 애니메이션)
/// - "가입이 완료되었습니다!" 메시지
/// - 닉네임 환영 메시지
/// - "로그인하러 가기" 버튼

struct SignUpCompleteView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @EnvironmentObject var router: AppRouter

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 체크마크 아이콘
            checkmarkIcon
                .padding(.bottom, 24)

            // 완료 메시지
            completionMessage
                .padding(.bottom, 8)

            // 환영 메시지
            welcomeMessage

            Spacer()

            // 로그인하러 가기 버튼
            loginButton
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
        }
    }

    // MARK: - Checkmark Icon

    private var checkmarkIcon: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(HiTripColor.primary800)
            .scaleEffect(showCheckmark ? 1.0 : 0.0)
    }

    // MARK: - Completion Message

    private var completionMessage: some View {
        Text("가입이 완료되었습니다!")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(HiTripColor.textBlack)
    }

    // MARK: - Welcome Message

    private var welcomeMessage: some View {
        Text("\(viewModel.nickname)님, 환영합니다!")
            .font(.system(size: 16))
            .foregroundColor(HiTripColor.gray500)
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            router.navigateToLogin()
        } label: {
            Text("로그인하러 가기")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(HiTripColor.buttonPrimary)
                .cornerRadius(10)
        }
    }
}
