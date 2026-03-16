import SwiftUI

// MARK: - SignUpNicknameView
/// 회원가입 Step 1: 닉네임 설정
///
/// UI 구성:
/// - 안내 텍스트 ("Hi Trip에서 사용할 닉네임을 입력해 주세요")
/// - 닉네임 입력 필드 + 중복확인 버튼
/// - 중복 확인 결과 메시지 (사용 가능/불가)
/// - "다음" 버튼 (중복 확인 완료 시 활성화)
///
/// 동작:
/// 1. 닉네임 2자 이상 입력 → "중복확인" 버튼 활성화
/// 2. 중복확인 탭 → API 호출 → 결과 메시지 표시
/// 3. 닉네임 수정 → 확인 상태 초기화 (다시 확인 필요)
/// 4. 사용 가능 확인 완료 → "다음" 버튼 활성화 → Step 2로

struct SignUpNicknameView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 안내 텍스트
            guideSection
                .padding(.top, 32)

            // 닉네임 입력 + 중복확인 버튼
            nicknameInputSection
                .padding(.top, 28)

            // 확인 결과 메시지
            messageSection
                .padding(.top, 8)

            Spacer()

            // 다음 버튼
            nextButton
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        // 닉네임 변경 시 확인 상태 초기화
        .onChange(of: viewModel.nickname) { _ in
            viewModel.resetNicknameCheck()
        }
    }

    // MARK: - Guide Section

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임 설정")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("Hi Trip에서 사용할 닉네임을 입력해 주세요.")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)
        }
    }

    // MARK: - Nickname Input

    /// 닉네임 입력 필드 + 중복확인 버튼을 나란히 배치
    /// - HStack으로 입력필드(유연 너비) + 버튼(고정 너비)
    private var nicknameInputSection: some View {
        HStack(spacing: 10) {
            TextField("닉네임 입력 (2자 이상)", text: $viewModel.nickname)
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

    /// 닉네임 확인 결과 메시지
    /// - 사용 가능: 초록색
    /// - 사용 불가/에러: 빨간색
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

    /// "다음" 버튼 — 닉네임 중복 확인 완료 시에만 활성화
    private var nextButton: some View {
        Button {
            viewModel.goToNextStep()
        } label: {
            Text("다음")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.isNicknameChecked && viewModel.isNicknameAvailable
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!(viewModel.isNicknameChecked && viewModel.isNicknameAvailable))
    }

    // MARK: - Computed Helpers

    /// 중복확인 버튼 활성화 조건
    /// - 닉네임 2자 이상 + 아직 확인 안 된 상태
    private var isCheckButtonEnabled: Bool {
        viewModel.nickname.trimmed.count >= 2 && !viewModel.isNicknameChecked
    }

    /// 입력 필드 테두리 색상
    /// - 기본: 회색 테두리
    /// - 확인 완료 + 사용 가능: 초록색
    /// - 확인 완료 + 사용 불가: 빨간색
    private var nicknameBorderColor: Color {
        guard viewModel.isNicknameChecked else { return HiTripColor.gray300 }
        return viewModel.isNicknameAvailable ? HiTripColor.readCheck : HiTripColor.error
    }
}
