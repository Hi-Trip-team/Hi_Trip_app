import SwiftUI

// MARK: - SignUpUserIdView
/// 회원가입 Step 2: 아이디 설정 (피그마 레이아웃)
///
/// 피그마 디자인:
/// - "아이디 설정" 타이틀 + 설명
/// - 아이디 입력 필드 + 중복확인 버튼
/// - 하단 "다음" 버튼
///
/// 동작 (닉네임 중복확인과 동일한 패턴):
/// 1. 아이디 4자 이상 입력 → "중복확인" 버튼 활성화
/// 2. 중복확인 탭 → API 호출 → 결과 메시지 표시
/// 3. 아이디 수정 → 확인 상태 초기화
/// 4. 사용 가능 확인 완료 → "다음" 버튼 활성화

struct SignUpUserIdView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀 + 설명
            titleSection
                .padding(.top, 40)

            // "아이디" 라벨 (파란색)
            Text("아이디")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HiTripColor.secondary700)
                .padding(.top, 32)
                .padding(.bottom, 8)

            // 아이디 입력 + 중복확인 버튼
            userIdInputSection

            // 확인 결과 메시지
            messageSection
                .padding(.top, 8)

            Spacer()

            // 다음 버튼
            nextButton
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .onChange(of: viewModel.userId) { _ in
            viewModel.resetUserIdCheck()
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("아이디 설정")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("로그인에 사용할 아이디를 입력해 주세요.\n기존에 존재하는 아이디인지 확인이 필요합니다.")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .lineSpacing(4)
        }
    }

    // MARK: - User ID Input

    private var userIdInputSection: some View {
        HStack(spacing: 10) {
            TextField("아이디를 입력해주세요 (4자 이상)", text: $viewModel.userId)
                .padding(14)
                .background(HiTripColor.inputBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )
                .focused($isFocused)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .onSubmit { isFocused = false }

            // 중복확인 버튼
            Button {
                isFocused = false
                viewModel.checkUserId()
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
            if let message = viewModel.userIdMessage {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(
                        viewModel.isUserIdAvailable
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
        viewModel.isUserIdChecked && viewModel.isUserIdAvailable
    }

    private var isCheckButtonEnabled: Bool {
        viewModel.isUserIdFormatValid && !viewModel.isUserIdChecked
    }

    private var borderColor: Color {
        guard viewModel.isUserIdChecked else { return HiTripColor.gray300 }
        return viewModel.isUserIdAvailable ? HiTripColor.readCheck : HiTripColor.error
    }
}
