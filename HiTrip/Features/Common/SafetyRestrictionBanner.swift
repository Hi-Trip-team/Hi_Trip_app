import SwiftUI

// MARK: - SafetyRestrictionBanner
/// 위치 권한이 거부된 상태로 홈에 들어오면 상단에 항상 보이는 배너
///
/// 탭하면 설정 앱으로 보내 권한을 다시 켜도록 유도합니다.
/// 설정에서 돌아오면 scenePhase로 상태를 다시 읽어 허용 시 자동으로 사라집니다.

struct SafetyRestrictionBanner: View {

    @ObservedObject private var permissions = PermissionCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if permissions.isLocationRestricted {
                Button { permissions.openSettings() } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(AppFont.label)
                        Text("안전 서비스 제한 중")
                            .font(AppFont.labelSemiBold)
                        Text("위치 권한을 허용해주세요")
                            .font(AppFont.caption)
                            .opacity(0.8)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(AppFont.caption2SemiBold)
                    }
                    .foregroundColor(AppColor.dangerStrong)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(AppColor.dangerBackground)
                }
                .buttonStyle(.plain)
                .accessibilityHint("설정 앱에서 위치 권한을 켤 수 있습니다")
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { permissions.refresh() }
        }
    }
}
