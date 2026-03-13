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
        .onChange(of: viewModel.loginSuccess) { _, success in
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
    /// - submitLabel(.next): 키보드 리턴키를 "다음"으로 표시
    /// - onSubmit: ID 입력 후 자동으로 Password 필드로 포커스 이동
    private var inputSection: some View {
        VStack(spacing: 12) {
            TextField("ID (성함)", text: $viewModel.id)
                .padding(14)
                .background(HiTripColor.inputBackground)
                .cornerRadius(10)
                .focused($focusedField, equals: .id)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

            SecureField("password (생년월일)", text: $viewModel.password)
                .padding(14)
                .background(HiTripColor.inputBackground)
                .cornerRadius(10)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .password)
        }
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isFormValid
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!isFormValid)
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

    /// 폼 유효성: ID + PW 모두 비어있지 않아야 버튼 활성화
    private var isFormValid: Bool {
        !viewModel.id.trimmed.isEmpty && !viewModel.password.trimmed.isEmpty
    }
}
