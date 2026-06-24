import SwiftUI

// MARK: - LoginView
/// 로그인 화면
///
/// 디자인:
/// - 밝은 회색 배경 (#F7F7F7)
/// - "Hi Trip" 로고 (Secondary 700)
/// - ID/PW 인풋 필드 (흰색 배경, 둥근 모서리)
/// - 자동 로그인 체크박스
/// - 파란색 로그인 버튼
/// - 회원가입 링크
/// - 하단 COPYRIGHT

struct LoginView: View {

    @ObservedObject var viewModel: LoginViewModel
    @EnvironmentObject var router: AppRouter
    @FocusState private var focusedField: Field?

    enum Field { case id, password }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 배경색
            HiTripColor.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                logoSection
                Spacer().frame(height: 60)
                inputSection
                errorSection
                Spacer().frame(height: 16)
                autoLoginToggle
                Spacer().frame(height: 16)
                loginButton
                Spacer().frame(height: 12)
                signUpButton
                Spacer().frame(height: 24)
                inviteLoginButton
                Spacer()
                copyrightSection
            }
            .padding(.horizontal, 32)

            // 로딩 오버레이
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
        // 로그인 성공 시 홈 화면으로 전환
        .onChange(of: viewModel.loginSuccess) { success in
            if success { router.navigateToHome() }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        Text("Hi Trip")
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(HiTripColor.logoText)
    }

    // MARK: - Input Fields

    /// ID, Password 입력 필드
    /// - 회원가입과 동일 조건: 아이디 4자+, 비밀번호 8자+
    /// - 조건 미충족 시 실시간 피드백 표시
    private var inputSection: some View {
        VStack(spacing: 16) {
            // 아이디 입력
            VStack(alignment: .leading, spacing: 6) {
                TextField("아이디를 입력해주세요 (4자 이상)", text: $viewModel.id)
                    .padding(14)
                    .background(HiTripColor.inputBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(idBorderColor, lineWidth: 1)
                    )
                    .focused($focusedField, equals: .id)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }

                if !viewModel.id.isEmpty && !viewModel.isIdValid {
                    Text("아이디는 4자 이상이어야 합니다.")
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.error)
                }
            }

            // 비밀번호 입력
            VStack(alignment: .leading, spacing: 6) {
                SecureField("비밀번호를 입력해주세요 (8자 이상)", text: $viewModel.password)
                    .padding(14)
                    .background(HiTripColor.inputBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(passwordBorderColor, lineWidth: 1)
                    )
                    .focused($focusedField, equals: .password)

                if !viewModel.password.isEmpty && !viewModel.isPasswordValid {
                    Text("비밀번호는 8자 이상이어야 합니다.")
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.error)
                }
            }
        }
    }

    // MARK: - Border Colors

    private var idBorderColor: Color {
        guard !viewModel.id.isEmpty else { return .clear }
        return viewModel.isIdValid ? HiTripColor.readCheck : HiTripColor.error
    }

    private var passwordBorderColor: Color {
        guard !viewModel.password.isEmpty else { return .clear }
        return viewModel.isPasswordValid ? HiTripColor.readCheck : HiTripColor.error
    }

    // MARK: - Error Message

    /// 에러 메시지 영역 — 고정 높이로 레이아웃 밀림 방지
    private var errorSection: some View {
        Group {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.error)
                    .padding(.top, 8)
            }
        }
        .frame(height: 24)
    }

    // MARK: - Auto Login Toggle

    @State private var isAutoLogin = false

    private var autoLoginToggle: some View {
        HStack {
            Button { isAutoLogin.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: isAutoLogin
                          ? "checkmark.circle.fill"
                          : "checkmark.circle")
                        .foregroundColor(isAutoLogin
                                         ? HiTripColor.secondary700
                                         : HiTripColor.gray400)
                    Text("자동 로그인")
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Login Button

    /// 로그인 버튼
    /// - ID, PW 모두 입력 시 Primary 색상으로 활성화
    /// - 미입력 시 Gray로 비활성화 (disabled)
    private var loginButton: some View {
        Button {
            focusedField = nil  // 키보드 닫기
            viewModel.login()
        } label: {
            Text("로그인")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(
                    viewModel.isFormValid ? .white : HiTripColor.buttonDisabledText
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.isFormValid
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!viewModel.isFormValid)
    }

    // MARK: - Sign Up Button

    private var signUpButton: some View {
        Button {
            router.navigateToSignUp()
        } label: {
            Text("회원가입")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.secondary700)
                .underline()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Invite Login Button

    private var inviteLoginButton: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .fill(HiTripColor.gray300)
                    .frame(height: 0.5)
                Text("또는")
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray400)
                Rectangle()
                    .fill(HiTripColor.gray300)
                    .frame(height: 0.5)
            }

            Button {
                router.navigateToInviteLogin()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 16))
                    Text("초대코드로 로그인")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(HiTripColor.primary800)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(HiTripColor.primary800.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(HiTripColor.primary800.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Copyright

    private var copyrightSection: some View {
        VStack(spacing: 2) {
            Text("COPYRIGHT \u{00A9} 2025 FGTV ALL RIGHTS RESERVED.")
            Text("Contact PICTOREAL Inc.")
        }
        .font(.system(size: 11))
        .foregroundColor(HiTripColor.gray400)
        .padding(.bottom, 24)
    }

    // MARK: - Validation
    // → viewModel.isFormValid로 이동 (아이디 4자+, 비밀번호 8자+)
}
