import SwiftUI

// MARK: - LoginView
/// 로그인 화면 (관광객·안내사 공용) — Figma 0827 수정본 12380:1413 / 불일치 12381:6009
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

    // Figma 색상
    private let fieldBackground = Color(hex: "#F3F4F6")
    private let placeholderGray = Color(hex: "#6B7280")
    private let errorRed = Color(hex: "#EF4444")
    private let brandBlue = Color(hex: "#0C46C0")

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
                .onTapGesture { focusedField = nil }

            VStack(spacing: 0) {
                Text("Hi Trip")
                    .font(.pretendard(.heavy, size: 40))
                    .foregroundColor(brandBlue)
                    .padding(.top, 133)

                VStack(alignment: .leading, spacing: 20) {
                    idField
                    passwordField
                }
                .padding(.top, 134)
                .padding(.horizontal, 20)

                autoLoginRow
                    .padding(.top, 15)
                    .padding(.horizontal, 24)

                // 불일치 · 잠금 안내 — 버튼 바로 위
                if let message = viewModel.bannerMessage {
                    Text(message)
                        .font(.pretendard(.medium, size: 13))
                        .foregroundColor(errorRed)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 7)
                        .padding(.horizontal, 24)
                }

                loginButton
                    .padding(.top, viewModel.bannerMessage == nil ? 35 : 12)
                    .padding(.horizontal, 20)

                inquiryButton
                    .padding(.top, 13)
                    .padding(.horizontal, 22)

                #if DEBUG
                HStack(spacing: 12) {
                    Button("🧑 Guide") { router.navigateToHomeAs(.guide) }
                    Button("🧳 Tourist") { router.navigateToHomeAs(.tourist) }
                }
                .font(.caption)
                .foregroundColor(HiTripColor.gray500)
                .padding(.top, 8)
                #endif

                Spacer(minLength: 16)
                copyrightSection
            }
        }
        .onChange(of: viewModel.result?.accessToken) { _ in
            guard let result = viewModel.result else { return }
            router.proceedAfterLogin(as: result.user.userType, requiresAgreement: result.requiresAgreement)
        }
        .fullScreenCover(isPresented: $viewModel.showPasswordChange) {
            InitialPasswordChangeView(viewModel: viewModel)
        }
        .alert("동일한 아이디로 접속중인 기기가 있습니다.", isPresented: $viewModel.showConcurrentAlert) {
            Button("취소", role: .cancel) {}
            Button("확인") { viewModel.login(force: true) }
        } message: {
            Text("차단하고 로그인하시겠습니까?")
        }
    }

    // MARK: - ID

    private var idField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("", text: $viewModel.id, prompt: placeholder("발급받은 아이디"))
                .keyboardType(.asciiCapable)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .id)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .modifier(fieldStyle(isError: viewModel.idError != nil))

            if let error = viewModel.idError {
                fieldError(error)
            }
        }
    }

    // MARK: - Password

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            SecureField("", text: $viewModel.password, prompt: placeholder("비밀번호"))
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                    viewModel.login()
                }
                .modifier(fieldStyle(isError: viewModel.isPasswordHighlighted))

            if let error = viewModel.passwordError {
                fieldError(error)
            }
        }
    }

    private func placeholder(_ text: String) -> Text {
        Text(text).foregroundColor(placeholderGray)
    }

    private func fieldStyle(isError: Bool) -> LoginFieldStyle {
        LoginFieldStyle(isError: isError, background: fieldBackground, errorColor: errorRed)
    }

    private func fieldError(_ text: String) -> some View {
        Text(text)
            .font(.pretendard(.medium, size: 13))
            .foregroundColor(errorRed)
            .padding(.leading, 4)
    }

    // MARK: - Auto Login

    private var autoLoginRow: some View {
        Button { viewModel.isAutoLogin.toggle() } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isAutoLogin ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 17))
                    .foregroundColor(viewModel.isAutoLogin ? brandBlue : Color(hex: "#9CA3AF"))
                Text("자동 로그인")
                    .font(.pretendard(.semibold, size: 16))
                    .tracking(0.16)
                    .foregroundColor(Color(hex: "#1A1A1A"))
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
                        .font(.pretendard(.bold, size: 16))
                        .foregroundColor(isButtonActive ? .white : HiTripColor.buttonDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 53)
            .background(isButtonActive || viewModel.isLoading ? brandBlue : HiTripColor.buttonDisabled)
            .clipShape(RoundedRectangle(cornerRadius: 9))
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
                    .font(.pretendard(.regular, size: 14))
                    .foregroundColor(placeholderGray)
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
        .font(.pretendard(.regular, size: 10))
        .foregroundColor(placeholderGray)
        .multilineTextAlignment(.center)
    }
}

// MARK: - LoginFieldStyle
/// 회색 입력칸(높이 50, radius 9) + 오류 시 빨간 테두리
private struct LoginFieldStyle: ViewModifier {
    let isError: Bool
    let background: Color
    let errorColor: Color

    func body(content: Content) -> some View {
        content
            .font(.pretendard(.medium, size: 16))
            .tracking(0.16)
            .foregroundColor(.black)
            .padding(.horizontal, 21)
            .frame(height: 50)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isError ? errorColor : Color.clear, lineWidth: 1)
            )
    }
}
