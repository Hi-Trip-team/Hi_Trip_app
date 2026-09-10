import SwiftUI

// MARK: - LoginView
/// 로그인 화면 (관광객·안내사 공용)
///
/// - 계정은 SaaS에서 발급합니다. 앱에는 회원가입·비밀번호 변경이 없습니다.
/// - 아이디: 서버 username (문자열, 최대 150자) / 비밀번호: 문자열
/// - 어느 홈으로 갈지는 서버가 인정한 계정 종류로 정합니다(앱이 추측하지 않음).

struct LoginView: View {

    @StateObject private var viewModel = AppDIContainer.shared.makeLoginViewModel()
    @EnvironmentObject var router: AppRouter
    @Environment(\.openURL) private var openURL
    @FocusState private var focusedField: Field?

    enum Field { case id, password }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
                .onTapGesture { focusedField = nil }

            VStack(spacing: 0) {
                Spacer()
                logoSection
                Spacer()

                VStack(alignment: .leading, spacing: HiTripSpacing.md) {
                    idField
                    passwordField
                }
                .padding(.horizontal, HiTripSpacing.pagePadding)

                autoLoginRow
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.mdl)

                // 불일치 · 잠금 안내 — 버튼 바로 위
                if let message = viewModel.bannerMessage {
                    Text(message)
                        .font(HiTripFont.caption)
                        .foregroundColor(HiTripColor.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, HiTripSpacing.pagePadding)
                        .padding(.top, HiTripSpacing.md)
                        .monospacedDigit()
                }

                loginButton
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, viewModel.bannerMessage == nil ? HiTripSpacing.md : HiTripSpacing.sm)

                inquiryButton
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.sm)

                #if DEBUG
                HStack(spacing: 12) {
                    Button("🧑 Guide") { router.navigateToHomeAs(.guide) }
                    Button("🧳 Tourist") { router.navigateToHomeAs(.tourist) }
                }
                .font(.caption)
                .foregroundColor(HiTripColor.gray500)
                .padding(.top, 8)
                #endif

                Spacer()
                copyrightSection
            }
        }
        .onChange(of: viewModel.result?.accessToken) { _ in
            guard let result = viewModel.result else { return }
            router.proceedAfterLogin(as: result.user.userType, requiresAgreement: result.requiresAgreement)
        }
        .alert("동일한 아이디로 접속중인 기기가 있습니다.", isPresented: $viewModel.showConcurrentAlert) {
            Button("취소", role: .cancel) {}
            Button("확인") { viewModel.login(force: true) }
        } message: {
            Text("차단하고 로그인하시겠습니까?")
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        Text("Hi Trip")
            .font(.custom("Pretendard-Bold", size: 56))
            .foregroundColor(HiTripColor.primary800)
    }

    // MARK: - ID

    private var idField: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.xs) {
            TextField("발급받은 아이디", text: $viewModel.id)
                .font(HiTripFont.body)
                .keyboardType(.asciiCapable)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .id)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .modifier(LoginFieldStyle(isError: viewModel.idError != nil, isFocused: focusedField == .id))

            if let error = viewModel.idError {
                fieldError(error)
            }
        }
    }

    // MARK: - Password

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.xs) {
            SecureField("비밀번호", text: $viewModel.password)
                .font(HiTripFont.body)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                    viewModel.login()
                }
                .modifier(LoginFieldStyle(isError: viewModel.isPasswordHighlighted, isFocused: focusedField == .password))

            if let error = viewModel.passwordError {
                fieldError(error)
            }
        }
    }

    private func fieldError(_ text: String) -> some View {
        Text(text)
            .font(HiTripFont.caption)
            .foregroundColor(HiTripColor.danger)
            .padding(.leading, HiTripSpacing.xs)
    }

    // MARK: - Auto Login

    private var autoLoginRow: some View {
        Button { viewModel.isAutoLogin.toggle() } label: {
            HStack(spacing: HiTripSpacing.sm) {
                Image(systemName: viewModel.isAutoLogin ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.isAutoLogin ? HiTripColor.primary800 : HiTripColor.gray400)
                    .font(.system(size: 18))
                Text("자동 로그인")
                    .font(HiTripFont.body)
                    .foregroundColor(HiTripColor.textBlack)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Login Button

    private var isButtonActive: Bool {
        viewModel.isFormFilled && !viewModel.isLocked
    }

    private var loginButton: some View {
        Button {
            focusedField = nil
            viewModel.login()
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("로그인")
                        .font(HiTripFont.bodyLBold)
                        .foregroundColor(isButtonActive ? .white : HiTripColor.buttonDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isButtonActive || viewModel.isLoading ? HiTripColor.primary800 : HiTripColor.buttonDisabled)
            .cornerRadius(HiTripRadius.card)
        }
        .buttonStyle(.plain)
        // 요청 중 중복 탭 방지 / 잠금 중 비활성
        .disabled(viewModel.isLoading || viewModel.isLocked)
    }

    // MARK: - 문의하기

    private var inquiryButton: some View {
        HStack {
            Spacer()
            Button {
                if let url = AppLinks.inquiry { openURL(url) }
            } label: {
                Text("문의하기")
                    .font(HiTripFont.body)
                    .foregroundColor(HiTripColor.gray500)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Copyright

    private var copyrightSection: some View {
        VStack(spacing: 2) {
            Text("COPYRIGHT © 2025 FGTV ALL RIGHTS RESERVED.")
            Text("Contact PICTOREAL Inc.")
        }
        .font(HiTripFont.caption)
        .foregroundColor(HiTripColor.gray400)
        .multilineTextAlignment(.center)
        .padding(.bottom, HiTripSpacing.xl)
    }
}

// MARK: - LoginFieldStyle
/// 회색 입력칸 + 상태별 테두리 (오류 빨강 > 포커스 파랑)
private struct LoginFieldStyle: ViewModifier {
    let isError: Bool
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(HiTripSpacing.mdl)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: HiTripRadius.card)
                    .stroke(
                        isError ? HiTripColor.danger
                            : isFocused ? HiTripColor.primary800.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
    }
}
