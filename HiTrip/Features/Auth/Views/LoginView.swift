import SwiftUI

// MARK: - LoginView
/// 스태프(매니저) 로그인 화면 — 피그마 0827 수정본
///
/// - "Hi Trip" 대형 로고 (상단 중앙)
/// - 아이디 / 비밀번호 입력 필드
/// - 자동 로그인 체크박스
/// - 로그인 버튼
/// - 문의하기 링크 (우측)
/// - COPYRIGHT 푸터

struct LoginView: View {

    @ObservedObject var viewModel: LoginViewModel
    @EnvironmentObject var router: AppRouter
    @FocusState private var focusedField: Field?

    enum Field { case id, password }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // 로고 영역 (화면 상단 40%)
                Spacer()
                logoSection
                Spacer()

                // 입력 영역
                VStack(spacing: HiTripSpacing.md) {
                    idField
                    passwordField
                }
                .padding(.horizontal, HiTripSpacing.pagePadding)

                // 에러 메시지
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(HiTripFont.caption)
                        .foregroundColor(HiTripColor.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, HiTripSpacing.pagePadding)
                        .padding(.top, HiTripSpacing.xs)
                }

                // 자동 로그인
                autoLoginRow
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.mdl)

                // 로그인 버튼
                loginButton
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.md)

                // 문의하기
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

            // 로딩 오버레이
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.5)
            }
        }
        .onChange(of: viewModel.loginSuccess) { success in
            if success {
                router.navigateToHomeAs(viewModel.loggedInUserType)
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        Text("Hi Trip")
            .font(.custom("Pretendard-Bold", size: 56))
            .foregroundColor(HiTripColor.primary800)
    }

    // MARK: - ID Field

    private var idField: some View {
        TextField("아이디", text: $viewModel.id)
            .font(HiTripFont.body)
            .keyboardType(.asciiCapable)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .focused($focusedField, equals: .id)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }
            .padding(HiTripSpacing.mdl)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: HiTripRadius.card)
                    .stroke(
                        focusedField == .id ? HiTripColor.primary800.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Password Field

    private var passwordField: some View {
        SecureField("비밀번호", text: $viewModel.password)
            .font(HiTripFont.body)
            .keyboardType(.asciiCapable)
            .focused($focusedField, equals: .password)
            .submitLabel(.done)
            .onSubmit {
                guard !viewModel.password.isEmpty else { return }
                focusedField = nil
                viewModel.login()
            }
            .padding(HiTripSpacing.mdl)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: HiTripRadius.card)
                    .stroke(
                        viewModel.errorMessage != nil
                            ? HiTripColor.danger.opacity(0.5)
                            : focusedField == .password
                                ? HiTripColor.primary800.opacity(0.5)
                                : Color.clear,
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Auto Login

    @State private var isAutoLogin = false

    private var autoLoginRow: some View {
        HStack(spacing: HiTripSpacing.sm) {
            Button { isAutoLogin.toggle() } label: {
                Image(systemName: isAutoLogin ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isAutoLogin ? HiTripColor.primary800 : HiTripColor.gray400)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            Text("자동 로그인")
                .font(HiTripFont.body)
                .foregroundColor(HiTripColor.textBlack)

            Spacer()
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            focusedField = nil
            viewModel.login()
        } label: {
            Text("로그인")
                .font(HiTripFont.bodyLBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HiTripSpacing.lg)
                .background(HiTripColor.primary800)
                .cornerRadius(HiTripRadius.card)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 문의하기

    private var inquiryButton: some View {
        HStack {
            Spacer()
            Button {
                // TODO: 문의하기 액션 (웹뷰 또는 이메일)
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
