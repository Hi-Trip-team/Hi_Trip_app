import SwiftUI

// MARK: - SignUpFlowView
/// 회원가입 전체 플로우 컨테이너 View
///
/// 역할:
/// - 상단 네비게이션 바 (뒤로가기 + 단계 타이틀)
/// - 프로그레스 바 (현재 진행률 시각화)
/// - ViewModel.currentStep에 따라 해당 단계 View 렌더링
///
/// 구조:
/// ```
/// SignUpFlowView (컨테이너)
///   ├─ 뒤로가기 버튼 + 타이틀
///   ├─ 프로그레스 바
///   └─ switch currentStep
///       ├─ .nickname → SignUpNicknameView
///       ├─ .terms    → SignUpTermsView
///       ├─ .userId   → SignUpUserIdView
///       ├─ .password → SignUpPasswordView
///       └─ .complete → SignUpCompleteView
/// ```
///
/// 면접 포인트:
/// "컨테이너 패턴을 왜 사용했나요?"
/// → "각 단계 View가 독립적으로 UI만 담당하고,
///    네비게이션/프로그레스 같은 공통 요소는 컨테이너에서 한 번만 구현합니다.
///    이렇게 하면 단계를 추가/제거할 때 개별 View를 수정할 필요가 없습니다."

struct SignUpFlowView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            // 배경색
            HiTripColor.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 네비게이션 바 (완료 화면에서는 숨김)
                if viewModel.currentStep != .complete {
                    navigationBar
                    progressBar
                }

                // 단계별 View 렌더링
                stepContent
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }

            // 로딩 오버레이
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
    }

    // MARK: - Navigation Bar

    /// 커스텀 네비게이션 바
    /// - 첫 단계(닉네임): 뒤로가기 → 로그인 화면으로 돌아감
    /// - 이후 단계: 뒤로가기 → 이전 단계로 이동
    private var navigationBar: some View {
        HStack {
            Button {
                if viewModel.currentStep == .nickname {
                    // 첫 단계에서 뒤로가기 = 회원가입 취소 → 로그인으로
                    router.navigateToLogin()
                } else {
                    viewModel.goToPreviousStep()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
            }

            Spacer()

            Text(viewModel.currentStep.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            // 오른쪽 여백 맞추기용 투명 요소
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Progress Bar

    /// 진행률 표시 바
    /// - 전체 너비 대비 현재 단계 비율만큼 채움
    /// - 애니메이션으로 부드럽게 진행
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 바
                Rectangle()
                    .fill(HiTripColor.gray200)
                    .frame(height: 4)

                // 진행 바
                Rectangle()
                    .fill(HiTripColor.primary800)
                    .frame(
                        width: geometry.size.width * viewModel.currentStep.progress,
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step Content

    /// ViewModel.currentStep에 따라 해당 단계 View 렌더링
    /// - @ViewBuilder: 여러 View 중 하나를 조건부로 반환
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .nickname:
            SignUpNicknameView(viewModel: viewModel)

        case .terms:
            SignUpTermsView(viewModel: viewModel)

        case .userId:
            SignUpUserIdView(viewModel: viewModel)

        case .password:
            SignUpPasswordView(viewModel: viewModel)

        case .complete:
            SignUpCompleteView(viewModel: viewModel)
        }
    }
}
