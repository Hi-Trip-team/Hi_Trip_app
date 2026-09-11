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
    private let fieldBackground = Color(hex: "#F3F4F6")
    private let subGray = Color(hex: "#6B7280")
    private let errorRed = Color(hex: "#EF4444")
    private let brandBlue = Color(hex: "#0C46C0")

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
                    .font(.pretendard(.bold, size: 22))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.top, 33)

                Text("처음 로그인하셨어요. 발급받은 임시 비밀번호를\n새 비밀번호로 바꾸면 바로 로그인됩니다.")
                    .font(.pretendard(.regular, size: 13))
                    .foregroundColor(subGray)
                    .lineSpacing(3)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 20) {
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
                        .font(.pretendard(.medium, size: 13))
                        .foregroundColor(errorRed)
                        .padding(.top, 16)
                }

                Spacer()

                submitButton

                Button("취소") { viewModel.cancelPasswordChange() }
                    .font(.pretendard(.regular, size: 14))
                    .foregroundColor(subGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { focused = .new }
    }

    private func field(_ placeholder: String, text: Binding<String>, field: Field, isError: Bool, message: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SecureField("", text: text, prompt: Text(placeholder).foregroundColor(subGray))
                .textContentType(.newPassword)
                .focused($focused, equals: field)
                .submitLabel(field == .new ? .next : .done)
                .onSubmit {
                    if field == .new { focused = .confirm } else if canSubmit { submit() }
                }
                .font(.pretendard(.medium, size: 16))
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
                    .font(.pretendard(.medium, size: 13))
                    .foregroundColor(errorRed)
                    .padding(.leading, 4)
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
                        .font(.pretendard(.bold, size: 16))
                        .foregroundColor(canSubmit ? .white : HiTripColor.buttonDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 53)
            .background(canSubmit || viewModel.isChangingPassword ? brandBlue : HiTripColor.buttonDisabled)
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
