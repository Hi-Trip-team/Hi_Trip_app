import SwiftUI

// MARK: - SignUpPasswordView
/// 회원가입 Step 4: 비밀번호 설정
///
/// UI 구성:
/// - 안내 텍스트
/// - 비밀번호 입력 (SecureField, 6자 이상)
/// - 비밀번호 확인 입력 (SecureField, 일치 여부)
/// - 실시간 유효성 피드백
/// - "가입하기" 버튼 (둘 다 유효 시 활성화 → 회원가입 API 호출)
///
/// 검증 규칙:
/// - 비밀번호: 6자 이상
/// - 비밀번호 확인: 비밀번호와 일치
/// - 두 조건 모두 만족 시 "가입하기" 버튼 활성화

struct SignUpPasswordView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @FocusState private var focusedField: Field?

    enum Field { case password, confirm }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 안내 텍스트
            guideSection
                .padding(.top, 32)

            // 비밀번호 입력
            passwordInputSection
                .padding(.top, 28)

            // 에러 메시지 (API 호출 실패 시)
            errorSection
                .padding(.top, 8)

            Spacer()

            // 가입하기 버튼
            signUpButton
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Guide Section

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("비밀번호 설정")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("안전한 비밀번호를 설정해 주세요.")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)
        }
    }

    // MARK: - Password Input

    private var passwordInputSection: some View {
        VStack(spacing: 12) {
            // 비밀번호 입력
            VStack(alignment: .leading, spacing: 6) {
                SecureField("비밀번호 (6자 이상)", text: $viewModel.password)
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
                         : "비밀번호는 6자 이상이어야 합니다.")
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

    /// API 호출 실패 시 에러 메시지 표시
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

    // MARK: - Sign Up Button

    /// "가입하기" 버튼
    /// - 비밀번호 유효 + 확인 일치 시 활성화
    /// - 탭 시 ViewModel.signUp() 호출 → API 요청
    private var signUpButton: some View {
        Button {
            focusedField = nil
            viewModel.signUp()
        } label: {
            Text("가입하기")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
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

    /// 비밀번호 필드 테두리
    private var passwordBorderColor: Color {
        guard !viewModel.password.isEmpty else { return HiTripColor.gray300 }
        return viewModel.isPasswordValid ? HiTripColor.readCheck : HiTripColor.error
    }

    /// 비밀번호 확인 필드 테두리
    private var confirmBorderColor: Color {
        guard !viewModel.passwordConfirm.isEmpty else { return HiTripColor.gray300 }
        return viewModel.isPasswordMatch ? HiTripColor.readCheck : HiTripColor.error
    }
}
