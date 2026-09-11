import SwiftUI

// MARK: - EmergencyCallDialog
/// 긴급 통역 연결 — 홈의 "긴급 즉시 연락" 버튼으로 뜨는 팝업
///
/// 별도 화면이 아니라 홈 위에 겹쳐 띄웁니다.
/// 긴급 버튼이라 한 번 탭에 바로 걸지 않고 이 확인 단계를 거칩니다 (오발신 방지).
///
/// 판단·전송·전화 연결은 EmergencyCallViewModel이 맡습니다.
///
/// 통역 센터 번호와 운영시간은 아직 확정 전이라, 번호는 홈 응답의
/// manager_contact를, 운영시간은 아래 기본값을 씁니다.

struct EmergencyCallDialog: View {

    @Binding var isPresented: Bool
    /// "안내사에게 메시지" — 메시지 목록으로 보냅니다
    var onMessageGuide: (() -> Void)?

    @StateObject private var viewModel: EmergencyCallViewModel

    /// - Parameters:
    ///   - phoneNumber: 연결할 전화번호. 없으면 "전화하기"를 누를 수 없습니다.
    ///   - openHour / closeHour: 운영 시작·종료 시각 (현지 기준, 24시간)
    init(
        isPresented: Binding<Bool>,
        phoneNumber: String?,
        openHour: Int = 9,
        closeHour: Int = 22,
        onMessageGuide: (() -> Void)? = nil
    ) {
        _isPresented = isPresented
        self.onMessageGuide = onMessageGuide
        _viewModel = StateObject(wrappedValue: EmergencyCallViewModel(
            phoneNumber: phoneNumber, openHour: openHour, closeHour: closeHour
        ))
    }

    var body: some View {
        ZStack {
            DimmedBackground { isPresented = false }

            dialogCard
        }
    }

    private var dialogCard: some View {
        VStack(spacing: 0) {
            Text("☎")
                .font(AppFont.emojiL)
                .foregroundColor(AppColor.danger)
                .padding(.top, AppSpacing.xl)

            Text(viewModel.title)
                .font(AppFont.title3Bold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.top, AppSpacing.md)

            VStack(spacing: 2) {
                Text(viewModel.guideText)
                Text(viewModel.operatingHoursText)
            }
            .font(AppFont.label)
            .foregroundColor(AppColor.textBody)
            .multilineTextAlignment(.center)
            .padding(.top, 14)

            HStack(spacing: 10) {
                Button { isPresented = false } label: {
                    Text("취소")
                        .font(AppFont.bodyMedium)
                        .foregroundColor(AppColor.textBody)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.lg)
                }
                .buttonStyle(.plain)

                if viewModel.isWithinOperatingHours {
                    Button { viewModel.call { isPresented = false } } label: {
                        Group {
                            if viewModel.isSending {
                                ProgressView().tint(.white)
                            } else {
                                Text("전화하기")
                                    .font(AppFont.bodyBold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(viewModel.canCall ? AppColor.danger : AppColor.borderMuted)
                        .cornerRadius(AppRadius.lg)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canCall || viewModel.isSending)
                } else {
                    // 운영시간 밖에는 담당 안내사에게 메시지를 보내도록 유도합니다
                    Button {
                        isPresented = false
                        onMessageGuide?()
                    } label: {
                        Text("안내사에게 메시지")
                            .font(AppFont.bodyBold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(AppColor.accent)
                            .cornerRadius(AppRadius.lg)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, 22)
            .padding(.bottom, 22)
        }
        .frame(width: 310)
        .background(Color.white)
        .cornerRadius(AppRadius.xl)
    }
}
