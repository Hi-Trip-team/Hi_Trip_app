import SwiftUI

// MARK: - SignUpNicknameView
/// 회원가입 Step 1: 닉네임 설정 (피그마 레이아웃)
///
/// 피그마 디자인:
/// - 큰 타이틀 "하이트립에서 사용할\n이름을 입력해주세요"
/// - "닉네임" 라벨 (파란색) + 입력 필드 + 중복확인 버튼
/// - 하단 "다음" 버튼
///
/// 동작:
/// 1. 닉네임 2자 이상 입력 → "중복확인" 버튼 활성화
/// 2. 중복확인 탭 → API 호출 → 결과 메시지 표시
/// 3. 닉네임 수정 → 확인 상태 초기화 (다시 확인 필요)
/// 4. 사용 가능 확인 완료 → "다음" 버튼 활성화

struct SignUpNicknameView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 큰 타이틀 (피그마 기준)
            titleSection
                .padding(.top, 40)

            // "닉네임" 라벨 (파란색)
            Text("닉네임")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HiTripColor.secondary700)
                .padding(.top, 40)
                .padding(.bottom, 8)

            // 닉네임 입력 + 중복확인 버튼
            nicknameInputSection

            // 확인 결과 메시지
            messageSection
                .padding(.top, 8)

            Spacer()

            // 다음 버튼
            nextButton
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .onChange(of: viewModel.nickname) { _ in
            viewModel.resetNicknameCheck()
        }
    }

    // MARK: - Title Section

    /// 피그마 기준 큰 타이틀
    private var titleSection: some View {
        Text("하이트립에서 사용할\n이름을 입력해주세요")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(HiTripColor.textBlack)
            .lineSpacing(6)
    }

    // MARK: - Nickname Input

    private var nicknameInputSection: some View {
        HStack(spacing: 10) {
            TextField("닉네임을 작성해주세요!", text: $viewModel.nickname)
                .padding(14)
                .background(HiTripColor.inputBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(nicknameBorderColor, lineWidth: 1)
                )
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { isFocused = false }

            // 중복확인 버튼
            Button {
                isFocused = false
                viewModel.checkNickname()
            } label: {
                Text("중복확인")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        isCheckButtonEnabled
                            ? HiTripColor.primary800
                            : HiTripColor.buttonDisabled
                    )
                    .cornerRadius(10)
            }
            .disabled(!isCheckButtonEnabled)
        }
    }

    // MARK: - Message Section

    private var messageSection: some View {
        Group {
            if let message = viewModel.nicknameMessage {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(
                        viewModel.isNicknameAvailable
                            ? HiTripColor.readCheck
                            : HiTripColor.error
                    )
            }
        }
        .frame(height: 20, alignment: .leading)
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            viewModel.goToNextStep()
        } label: {
            Text("다음")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(
                    isNextEnabled ? .white : HiTripColor.buttonDisabledText
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isNextEnabled
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!isNextEnabled)
    }

    // MARK: - Computed Helpers

    private var isNextEnabled: Bool {
        viewModel.isNicknameChecked && viewModel.isNicknameAvailable
    }

    private var isCheckButtonEnabled: Bool {
        viewModel.nickname.trimmed.count >= 2 && !viewModel.isNicknameChecked
    }

    private var nicknameBorderColor: Color {
        guard viewModel.isNicknameChecked else { return HiTripColor.gray300 }
        return viewModel.isNicknameAvailable ? HiTripColor.readCheck : HiTripColor.error
    }
}
