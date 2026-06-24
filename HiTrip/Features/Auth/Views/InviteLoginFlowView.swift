import SwiftUI

// MARK: - InviteLoginFlowView
/// 초대코드 로그인 플로우 — 회원가입과 동일한 스텝 UI
///
/// Step 1: 전화번호 입력
/// Step 2: 생년월일 선택
/// Step 3: 초대코드 입력 → 로그인

struct InviteLoginFlowView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = InviteLoginViewModel()

    var body: some View {
        ZStack {
            HiTripColor.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 네비게이션 바
                navBar

                // 프로그레스 바
                progressBar
                    .padding(.top, 8)

                // 타이틀
                titleSection
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                // Mock 모드 힌트 배너
                if APIEnvironment.current.useMock {
                    mockHintBanner
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                }

                // 입력 필드
                inputSection
                    .padding(.top, 28)
                    .padding(.horizontal, 24)

                // 에러 메시지
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // 다음/로그인 버튼
                nextButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }

            // 로딩 오버레이
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .onChange(of: viewModel.loginSuccess) { success in
            if success { router.navigateToHome() }
        }
        .onChange(of: viewModel.requiresAgreement) { required in
            if required { router.navigateToAgreement() }
        }
    }

    // MARK: - Mock Hint Banner

    private var mockHintBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🧪 MOCK 모드")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.orange)
            Text("전화번호: 010-1234-5678\n생년월일: 1995년 3월 15일\n초대코드: HITRIP2026")
                .font(.system(size: 12))
                .foregroundColor(.orange.opacity(0.8))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                if viewModel.currentStep == .phone {
                    router.navigateToLogin()
                } else {
                    viewModel.goBack()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }

            Spacer()

            Text("초대코드 로그인")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            // 빈 공간 (symmetry)
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(HiTripColor.gray200)
                    .frame(height: 4)
                    .cornerRadius(2)

                Rectangle()
                    .fill(HiTripColor.primary800)
                    .frame(width: geo.size.width * viewModel.progress, height: 4)
                    .cornerRadius(2)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.stepTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text(viewModel.stepSubtitle)
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Section

    @ViewBuilder
    private var inputSection: some View {
        switch viewModel.currentStep {
        case .phone:
            phoneInput
        case .birthDate:
            birthDateInput
        case .inviteCode:
            inviteCodeInput
        }
    }

    // MARK: - Phone Input

    private var phoneInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("전화번호")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            TextField("010-0000-0000", text: $viewModel.phone)
                .font(.system(size: 17))
                .keyboardType(.phonePad)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.phone.isEmpty ? HiTripColor.gray200 : HiTripColor.primary800,
                            lineWidth: 1
                        )
                )

            if !viewModel.phone.isEmpty && !viewModel.isPhoneValid {
                Text("올바른 전화번호를 입력해주세요")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Birth Date Input

    private var birthDateInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("생년월일")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            DatePicker(
                "",
                selection: $viewModel.birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .frame(maxHeight: 200)
        }
    }

    // MARK: - Invite Code Input

    private var inviteCodeInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("초대코드")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            TextField("초대코드를 입력하세요", text: $viewModel.inviteCode)
                .font(.system(size: 20, weight: .medium))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.inviteCode.isEmpty ? HiTripColor.gray200 : HiTripColor.primary800,
                            lineWidth: 1
                        )
                )

            Text("여행사에서 문자 또는 이메일로 전달받은 코드입니다")
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.gray400)
        }
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            viewModel.errorMessage = nil
            viewModel.goNext()
        } label: {
            Text(viewModel.buttonTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.isCurrentStepValid
                        ? HiTripColor.primary800
                        : HiTripColor.gray300
                )
                .cornerRadius(14)
        }
        .disabled(!viewModel.isCurrentStepValid)
        .buttonStyle(.plain)
    }
}
