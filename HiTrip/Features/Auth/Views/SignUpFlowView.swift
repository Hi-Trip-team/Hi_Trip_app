import SwiftUI

// MARK: - SignUpFlowView
/// 회원가입 전체 플로우 컨테이너 View (피그마 레이아웃)
///
/// 구조:
/// ```
/// SignUpFlowView (컨테이너)
///   ├─ 뒤로가기 버튼 (타이틀 없음 — 피그마 기준)
///   ├─ switch currentStep
///   │   ├─ .nickname → SignUpNicknameView
///   │   ├─ .userId   → SignUpUserIdView
///   │   ├─ .password → SignUpPasswordView
///   │   ├─ .terms    → SignUpTermsView
///   │   └─ .complete → SignUpCompleteView
///   └─ 하단 도트 인디케이터 (현재 단계 표시)
/// ```

struct SignUpFlowView: View {

    @ObservedObject var viewModel: SignUpViewModel
    @EnvironmentObject var router: AppRouter

    /// 완료 단계 제외한 실제 입력 단계 수 (도트 개수)
    private let inputSteps: [SignUpViewModel.Step] = [.nickname, .userId, .password, .terms]

    var body: some View {
        ZStack {
            // 배경색
            HiTripColor.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 네비게이션 바 (완료 화면에서는 숨김)
                if viewModel.currentStep != .complete {
                    navigationBar
                }

                // 단계별 View 렌더링
                stepContent
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                // 하단 도트 인디케이터 (완료 화면에서는 숨김)
                if viewModel.currentStep != .complete {
                    dotIndicator
                        .padding(.bottom, 20)
                }
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

    /// 미니멀 네비게이션 바 — 뒤로가기 버튼만 (피그마 기준)
    private var navigationBar: some View {
        HStack {
            Button {
                if viewModel.currentStep == .nickname {
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Dot Indicator

    /// 하단 도트 페이지 인디케이터 (피그마 기준)
    private var dotIndicator: some View {
        HStack(spacing: 8) {
            ForEach(inputSteps, id: \.rawValue) { step in
                Circle()
                    .fill(step == viewModel.currentStep
                          ? HiTripColor.dotActive
                          : HiTripColor.dotInactive)
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .nickname:
            SignUpNicknameView(viewModel: viewModel)

        case .userId:
            SignUpUserIdView(viewModel: viewModel)

        case .password:
            SignUpPasswordView(viewModel: viewModel)

        case .terms:
            SignUpTermsView(viewModel: viewModel)

        case .complete:
            SignUpCompleteView(viewModel: viewModel)
        }
    }
}
