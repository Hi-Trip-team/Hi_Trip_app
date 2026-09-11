import SwiftUI

// MARK: - InitialPasswordChangeView
/// 관광객 최초 비밀번호 변경
///
/// 발급받은 임시 비밀번호로 처음 로그인하면 서버가 409 PASSWORD_CHANGE_REQUIRED를 줍니다.
/// 새 비밀번호로 바꾸면(POST /api/v1/tourist/auth/change-initial-password/) 그 비밀번호로 바로 다시 로그인합니다.
/// 비밀번호 규칙은 서버가 판단하고, 거절 사유는 서버 문구를 그대로 보여줍니다.
/// 디자인은 로그인 화면(Figma 0827)과 같은 입력칸·버튼 스타일을 씁니다.

struct InitialPasswordChangeView: View {

    @ObservedObject var viewModel: LoginViewModel
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @FocusState private var focused: Field?

    enum Field { case new, confirm }

    private let minLength = 8
    private let fieldBackground = AppColor.surface
    private let subGray = AppColor.textSecondary
    private let errorRed = AppColor.danger
    private let brandBlue = AppColor.brand

    private var isTooShort: Bool { !newPassword.isEmpty && newPassword.count < minLength }
    private var isMismatch: Bool { !confirmPassword.isEmpty && confirmPassword != newPassword }
    private var canSubmit: Bool {
        newPassword.count >= minLength && confirmPassword == newPassword && !viewModel.isChangingPassword
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
                .onTapGesture { focused = nil }

            VStack(alignment: .leading, spacing: 0) {
                Text("비밀번호를 변경해주세요")
                    .font(AppFont.title1Bold)
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.top, 33)

                Text("처음 로그인하셨어요. 발급받은 임시 비밀번호를\n새 비밀번호로 바꾸면 바로 로그인됩니다.")
                    .font(AppFont.label)
                    .foregroundColor(subGray)
                    .lineSpacing(3)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    field(
                        "새 비밀번호 (\(minLength)자 이상)",
                        text: $newPassword,
                        field: .new,
                        isError: isTooShort,
                        message: isTooShort ? "\(minLength)자 이상 입력해주세요." : nil
                    )
                    field(
                        "새 비밀번호 확인",
                        text: $confirmPassword,
                        field: .confirm,
                        isError: isMismatch,
                        message: isMismatch ? "비밀번호가 일치하지 않습니다." : nil
                    )
                }
                .padding(.top, 36)

                if let error = viewModel.passwordChangeError {
                    Text(error)
                        .font(AppFont.labelMedium)
                        .foregroundColor(errorRed)
                        .padding(.top, AppSpacing.md)
                }

                Spacer()

                submitButton

                Button("취소") { viewModel.cancelPasswordChange() }
                    .font(AppFont.body)
                    .foregroundColor(subGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, AppSpacing.xl)
        }
        .onAppear { focused = .new }
    }

    private func field(_ placeholder: String, text: Binding<String>, field: Field, isError: Bool, message: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SecureField("", text: text, prompt: Text(placeholder).foregroundColor(subGray))
                // 영문·숫자·특수문자 모두 입력되도록 키보드를 고정합니다
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.newPassword)
                .focused($focused, equals: field)
                .submitLabel(field == .new ? .next : .done)
                .onSubmit {
                    if field == .new { focused = .confirm } else if canSubmit { submit() }
                }
                .font(AppFont.bodyLMedium)
                .padding(.horizontal, 21)
                .frame(height: 50)
                .background(fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(isError ? errorRed : Color.clear, lineWidth: 1)
                )

            if let message {
                Text(message)
                    .font(AppFont.labelMedium)
                    .foregroundColor(errorRed)
                    .padding(.leading, AppSpacing.xxs)
            }
        }
    }

    private var submitButton: some View {
        Button { submit() } label: {
            ZStack {
                if viewModel.isChangingPassword || viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("변경하고 로그인")
                        .font(AppFont.bodyLBold)
                        .foregroundColor(canSubmit ? .white : AppColor.buttonDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 53)
            .background(canSubmit || viewModel.isChangingPassword ? brandBlue : AppColor.buttonDisabled)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private func submit() {
        focused = nil
        viewModel.changeInitialPassword(to: newPassword)
    }
}
