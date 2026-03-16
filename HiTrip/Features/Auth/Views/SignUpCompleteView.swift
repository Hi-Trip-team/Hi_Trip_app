import SwiftUI

// MARK: - SignUpCompleteView
/// 회원가입 완료 화면
///
/// UI 구성:
/// - 체크마크 아이콘 (스케일 애니메이션)
/// - "가입이 완료되었습니다!" 메시지
/// - 닉네임 표시 ("OOO님, 환영합니다!")
/// - "로그인하러 가기" 버튼 → 로그인 화면으로 이동
///
/// 이 화면에서는 네비게이션 바와 프로그레스 바가 숨겨짐
/// (SignUpFlowView에서 .complete 단계일 때 숨김 처리)

struct SignUpCompleteView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @EnvironmentObject var router: AppRouter

    /// 체크마크 등장 애니메이션 상태
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
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // 화면 등장 시 체크마크 애니메이션 실행
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
        }
    }

    // MARK: - Checkmark Icon

    /// 파란 원 안에 체크마크
    /// - onAppear 시 스케일 0 → 1 스프링 애니메이션
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

    /// 닉네임을 포함한 환영 메시지
    private var welcomeMessage: some View {
        Text("\(viewModel.nickname)님, 환영합니다!")
            .font(.system(size: 16))
            .foregroundColor(HiTripColor.gray500)
    }

    // MARK: - Login Button

    /// "로그인하러 가기" 버튼
    /// - 탭 시 AppRouter를 통해 로그인 화면으로 이동
    /// - 회원가입 완료 후 자동 로그인이 아닌, 수동 로그인 유도
    ///   (보안 관점: 사용자가 직접 입력하여 로그인 확인)
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
