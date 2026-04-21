import SwiftUI

// MARK: - SignUpTermsView
/// 회원가입 Step 4: 약관 동의 (피그마 레이아웃)
///
/// UI 구성:
/// - "약관 동의" 타이틀 + 설명
/// - "전체 동의" 체크박스 (구분선으로 분리)
/// - [필수] 서비스 이용약관 + 보기 버튼
/// - [필수] 개인정보 수집 및 이용 + 보기 버튼
/// - [선택] 마케팅 정보 수신
/// - "가입하기" 버튼 (필수 약관 모두 동의 시 활성화 → 회원가입 API 호출)

struct SignUpTermsView: View {

    @ObservedObject var viewModel: SignUpViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀
            titleSection
                .padding(.top, 40)

            // 약관 체크박스 영역
            termsSection
                .padding(.top, 28)

            Spacer()

            // 가입하기 버튼
            signUpButton
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("약관 동의")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("서비스 이용을 위해 약관에 동의해 주세요.")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
        }
    }

    // MARK: - Terms Checkboxes

    private var termsSection: some View {
        VStack(spacing: 0) {
            // 전체 동의
            agreeAllRow
                .padding(.bottom, 16)

            // 구분선
            Divider()
                .padding(.bottom, 16)

            // [필수] 서비스 이용약관
            termRow(
                title: "[필수] 서비스 이용약관",
                isChecked: $viewModel.agreeService,
                showDetail: true
            )
            .padding(.bottom, 12)

            // [필수] 개인정보 수집 및 이용
            termRow(
                title: "[필수] 개인정보 수집 및 이용",
                isChecked: $viewModel.agreePrivacy,
                showDetail: true
            )
            .padding(.bottom, 12)

            // [선택] 마케팅 정보 수신
            termRow(
                title: "[선택] 마케팅 정보 수신",
                isChecked: $viewModel.agreeMarketing,
                showDetail: false
            )
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Agree All Row

    private var agreeAllRow: some View {
        Button {
            viewModel.toggleAgreeAll()
        } label: {
            HStack(spacing: 12) {
                checkboxIcon(isChecked: viewModel.agreeAll)

                Text("전체 동의")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Individual Term Row

    private func termRow(
        title: String,
        isChecked: Binding<Bool>,
        showDetail: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                isChecked.wrappedValue.toggle()
                viewModel.updateAgreeAll()
            } label: {
                HStack(spacing: 12) {
                    checkboxIcon(isChecked: isChecked.wrappedValue)

                    Text(title)
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.textGrayA)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if showDetail {
                Button {
                    // TODO: 약관 상세 WebView 표시
                } label: {
                    Text("보기")
                        .font(.system(size: 13))
                        .foregroundColor(HiTripColor.gray400)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Checkbox Icon

    private func checkboxIcon(isChecked: Bool) -> some View {
        Image(systemName: isChecked
              ? "checkmark.circle.fill"
              : "circle")
            .font(.system(size: 22))
            .foregroundColor(isChecked
                             ? HiTripColor.primary800
                             : HiTripColor.gray300)
    }

    // MARK: - Sign Up Button

    /// "가입하기" 버튼 — 약관이 마지막 입력 단계이므로 signUp() 호출
    private var signUpButton: some View {
        Button {
            viewModel.signUp()
        } label: {
            Text("가입하기")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(
                    viewModel.isRequiredTermsAgreed
                        ? .white : HiTripColor.buttonDisabledText
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.isRequiredTermsAgreed
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!viewModel.isRequiredTermsAgreed)
    }
}
