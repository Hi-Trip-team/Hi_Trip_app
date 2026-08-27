import SwiftUI

// MARK: - InviteLoginFlowView
/// 관광객 계정 로그인 화면
///
/// POST /api/v1/tourist/auth/login/
/// Request: username, password

struct InviteLoginFlowView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = InviteLoginViewModel()
    @State private var isPasswordVisible = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(alignment: .leading, spacing: HiTripSpacing.xl) {

                        // 타이틀
                        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
                            Text("관광객 로그인")
                                .font(HiTripFont.title1)
                                .foregroundColor(HiTripColor.textBlack)
                            Text("여행사에서 발급받은 계정으로 로그인하세요")
                                .font(HiTripFont.body)
                                .foregroundColor(HiTripColor.gray500)
                        }
                        .padding(.top, HiTripSpacing.xxl)

                        // Mock 힌트
                        if APIEnvironment.current.useMock {
                            mockHintBanner
                        }

                        // 아이디
                        inputField(
                            label: "아이디",
                            placeholder: "발급받은 아이디",
                            text: $viewModel.username
                        )

                        // 비밀번호
                        passwordField

                        // 에러
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(HiTripFont.caption)
                                .foregroundColor(HiTripColor.danger)
                        }
                    }
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.bottom, HiTripSpacing.xxl)
                }

                loginButton
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.bottom, HiTripSpacing.xxl)
            }

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.5)
            }
        }
        .onChange(of: viewModel.loginSuccess) { success in
            if success { router.navigateToHome() }
        }
        .onChange(of: viewModel.requiresAgreement) { required in
            if required { router.navigateToAgreement() }
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { router.navigateToLogin() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
            }
            Spacer()
            Text("관광객 로그인")
                .font(HiTripFont.title3)
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, HiTripSpacing.lg)
        .padding(.top, HiTripSpacing.sm)
    }

    // MARK: - Input Field

    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
            Text(label)
                .font(HiTripFont.bodyBold)
                .foregroundColor(HiTripColor.textBlack)
            TextField(placeholder, text: text)
                .font(HiTripFont.body)
                .autocapitalization(.none)
                .padding(HiTripSpacing.mdl)
                .background(HiTripColor.gray100)
                .cornerRadius(HiTripRadius.card)
        }
    }

    // MARK: - Password Field

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
            Text("비밀번호")
                .font(HiTripFont.bodyBold)
                .foregroundColor(HiTripColor.textBlack)
            HStack {
                if isPasswordVisible {
                    TextField("비밀번호", text: $viewModel.password)
                        .font(HiTripFont.body)
                        .autocapitalization(.none)
                } else {
                    SecureField("비밀번호", text: $viewModel.password)
                        .font(HiTripFont.body)
                }
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(HiTripColor.gray400)
                }
            }
            .padding(HiTripSpacing.mdl)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
        }
    }

    // MARK: - Mock Hint

    private var mockHintBanner: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.xs) {
            Text("🧪 MOCK 모드")
                .font(HiTripFont.badge)
                .foregroundColor(.orange)
            Text("아이디: tourist01\n비밀번호: password123")
                .font(HiTripFont.caption)
                .foregroundColor(.orange)
        }
        .padding(HiTripSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(HiTripRadius.card)
        .overlay(RoundedRectangle(cornerRadius: HiTripRadius.card).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            viewModel.errorMessage = nil
            viewModel.login()
        } label: {
            Text("로그인")
                .font(HiTripFont.bodyLBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HiTripSpacing.lg)
                .background(viewModel.isFormValid ? HiTripColor.primary800 : HiTripColor.buttonDisabled)
                .cornerRadius(HiTripRadius.button)
        }
        .disabled(!viewModel.isFormValid)
        .buttonStyle(.plain)
    }
}
