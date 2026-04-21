import SwiftUI

// MARK: - SignUpPasswordView
/// 회원가입 Step 3: 비밀번호 설정 (피그마 레이아웃)
///
/// 피그마 디자인:
/// - "비밀번호 설정" 타이틀 + 설명
/// - "비밀번호를 입력해주세요." 라벨 (파란색)
/// - 비밀번호 입력 (영문, 숫자, 특수문자 포함 8자 이상)
/// - 비밀번호 확인 입력
/// - 하단 "다음" 버튼

struct SignUpPasswordView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @FocusState private var focusedField: Field?

    enum Field { case password, confirm }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀 + 설명
            titleSection
                .padding(.top, 40)

            // 비밀번호 입력 라벨 (파란색)
            Text("비밀번호를 입력해주세요.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HiTripColor.secondary700)
                .padding(.top, 32)
                .padding(.bottom, 8)

            // 비밀번호 입력
            passwordInputSection

            // 에러 메시지 (API 호출 실패 시)
            errorSection
                .padding(.top, 8)

            Spacer()

            // 다음 버튼
            nextButton
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("비밀번호 설정")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("비밀번호를 설정하면 이메일을 통해 로그인이 가능하고,\n계정을 안전하게 관리할 수 있습니다.")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .lineSpacing(4)
        }
    }

    // MARK: - Password Input

    private var passwordInputSection: some View {
        VStack(spacing: 16) {
            // 비밀번호 입력
            VStack(alignment: .leading, spacing: 6) {
                SecureField("영문, 숫자, 특수문자 포함 8자 이상", text: $viewModel.password)
                    .padding(14)
                    .background(HiTripColor.inputBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(passwordBorderColor, lineWidth: 1)
                    )
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .confirm }

                // 비밀번호 길이 피드백
                if !viewModel.password.isEmpty {
                    Text(viewModel.isPasswordValid
                         ? "사용 가능한 비밀번호입니다."
                         : "비밀번호는 8자 이상이어야 합니다.")
                        .font(.system(size: 13))
                        .foregroundColor(
                            viewModel.isPasswordValid
                                ? HiTripColor.readCheck
                                : HiTripColor.error
                        )
                }
            }

            // 비밀번호 확인
            VStack(alignment: .leading, spacing: 6) {
                // 비밀번호 확인 라벨 (파란색)
                Text("비밀번호를 입력해주세요.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(HiTripColor.secondary700)
                    .padding(.bottom, 2)
                SecureField("비밀번호 확인", text: $viewModel.passwordConfirm)
                    .padding(14)
                    .background(HiTripColor.inputBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(confirmBorderColor, lineWidth: 1)
                    )
                    .focused($focusedField, equals: .confirm)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }

                // 비밀번호 일치 피드백
                if !viewModel.passwordConfirm.isEmpty {
                    Text(viewModel.isPasswordMatch
                         ? "비밀번호가 일치합니다."
                         : "비밀번호가 일치하지 않습니다.")
                        .font(.system(size: 13))
                        .foregroundColor(
                            viewModel.isPasswordMatch
                                ? HiTripColor.readCheck
                                : HiTripColor.error
                        )
                }
            }
        }
    }

    // MARK: - Error Section

    private var errorSection: some View {
        Group {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.error)
            }
        }
        .frame(height: 20, alignment: .leading)
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            focusedField = nil
            viewModel.goToNextStep()
        } label: {
            Text("다음")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(
                    viewModel.isPasswordStepValid
                        ? .white : HiTripColor.buttonDisabledText
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.isPasswordStepValid
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!viewModel.isPasswordStepValid)
    }

    // MARK: - Border Colors

    private var passwordBorderColor: Color {
        guard !viewModel.password.isEmpty else { return HiTripColor.gray300 }
        return viewModel.isPasswordValid ? HiTripColor.readCheck : HiTripColor.error
    }

    private var confirmBorderColor: Color {
        guard !viewModel.passwordConfirm.isEmpty else { return HiTripColor.gray300 }
        return viewModel.isPasswordMatch ? HiTripColor.readCheck : HiTripColor.error
    }
}
