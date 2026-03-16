import SwiftUI

// MARK: - SignUpUserIdView
/// 회원가입 Step 3: 아이디 설정
///
/// UI 구성:
/// - 안내 텍스트 ("로그인에 사용할 아이디를 입력해 주세요")
/// - 아이디 입력 필드
/// - 유효성 안내 메시지 (4자 이상)
/// - "다음" 버튼 (4자 이상 입력 시 활성화)
///
/// 검증 규칙:
/// - 공백 제거 후 4자 이상 필요 (SignUpUseCase.execute()에서도 이중 검증)
/// - 클라이언트 사이드 검증 → 빠른 피드백
/// - 서버 사이드 검증 → 최종 회원가입 시 재검증

struct SignUpUserIdView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 안내 텍스트
            guideSection
                .padding(.top, 32)

            // 아이디 입력 필드
            userIdInputSection
                .padding(.top, 28)

            // 유효성 메시지
            validationMessage
                .padding(.top, 8)

            Spacer()

            // 다음 버튼
            nextButton
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Guide Section

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("아이디 설정")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("로그인에 사용할 아이디를 입력해 주세요.")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)
        }
    }

    // MARK: - User ID Input

    private var userIdInputSection: some View {
        TextField("아이디 입력 (4자 이상)", text: $viewModel.userId)
            .padding(14)
            .background(HiTripColor.inputBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1)
            )
            .focused($isFocused)
            .autocapitalization(.none)    // 대문자 자동 변환 비활성화
            .disableAutocorrection(true)  // 자동 수정 비활성화
            .submitLabel(.done)
            .onSubmit { isFocused = false }
    }

    // MARK: - Validation Message

    /// 아이디 길이 안내 메시지
    /// - 빈 상태: 메시지 없음
    /// - 4자 미만: 빨간색 경고
    /// - 4자 이상: 초록색 확인
    private var validationMessage: some View {
        Group {
            if !viewModel.userId.isEmpty {
                if viewModel.isUserIdValid {
                    Text("사용 가능한 아이디 형식입니다.")
                        .foregroundColor(HiTripColor.readCheck)
                } else {
                    Text("아이디는 4자 이상이어야 합니다.")
                        .foregroundColor(HiTripColor.error)
                }
            }
        }
        .font(.system(size: 13))
        .frame(height: 20, alignment: .leading)
    }

    // MARK: - Next Button

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
                    viewModel.isUserIdValid
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!viewModel.isUserIdValid)
    }

    // MARK: - Border Color

    /// 입력 필드 테두리 색상
    /// - 빈 상태: 기본 회색
    /// - 유효: 초록색
    /// - 무효: 빨간색
    private var borderColor: Color {
        guard !viewModel.userId.isEmpty else { return HiTripColor.gray300 }
        return viewModel.isUserIdValid ? HiTripColor.readCheck : HiTripColor.error
    }
}
