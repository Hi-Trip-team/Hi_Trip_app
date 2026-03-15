import SwiftUI

// MARK: - SignUpTermsView
/// 회원가입 Step 2: 약관 동의
///
/// UI 구성:
/// - 안내 텍스트
/// - "전체 동의" 체크박스 (구분선으로 분리)
/// - [필수] 서비스 이용약관 + 보기 버튼
/// - [필수] 개인정보 수집 및 이용 + 보기 버튼
/// - [선택] 마케팅 정보 수신
/// - "다음" 버튼 (필수 약관 모두 동의 시 활성화)
///
/// 동작:
/// - "전체 동의" 토글 → 모든 약관 일괄 체크/해제
/// - 개별 약관 토글 → 3개 모두 체크 시 전체 동의 자동 활성화
/// - 필수 2개 동의 시 "다음" 버튼 활성화 (마케팅은 선택)

struct SignUpTermsView: View {

    @ObservedObject var viewModel: SignUpViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 안내 텍스트
            guideSection
                .padding(.top, 32)

            // 약관 체크박스 영역
            termsSection
                .padding(.top, 28)

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
            Text("약관 동의")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("서비스 이용을 위해 약관에 동의해 주세요.")
                .font(.system(size: 15))
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

    /// "전체 동의" 체크박스
    /// - 나머지 개별 약관을 한꺼번에 토글
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

    /// 개별 약관 행
    /// - isChecked: 바인딩 (토글 가능)
    /// - showDetail: true면 "보기" 버튼 표시 (약관 상세 페이지 이동용)
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

            // "보기" 버튼 (약관 상세 내용 — Phase 2에서 WebView 연동)
            if showDetail {
                Button {
                    // TODO: Phase 2 — 약관 상세 WebView 표시
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

    /// 체크박스 아이콘
    /// - 체크됨: 파란 원 + 체크마크
    /// - 미체크: 회색 빈 원
    private func checkboxIcon(isChecked: Bool) -> some View {
        Image(systemName: isChecked
              ? "checkmark.circle.fill"
              : "circle")
            .font(.system(size: 22))
            .foregroundColor(isChecked
                             ? HiTripColor.primary800
                             : HiTripColor.gray300)
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
                    viewModel.isRequiredTermsAgreed
                        ? HiTripColor.buttonPrimary
                        : HiTripColor.buttonDisabled
                )
                .cornerRadius(10)
        }
        .disabled(!viewModel.isRequiredTermsAgreed)
    }
}
