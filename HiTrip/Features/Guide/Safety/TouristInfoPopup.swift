import SwiftUI

struct TouristInfoPopup: View {

    let participant: ParticipantLatestDTO
    let profile: TravelerDetailDTO?
    let statusLine: String
    let canViewLocation: Bool
    let isEscaped: Bool
    var onClose: () -> Void
    var onViewLocation: () -> Void

    @State private var showsFullPassport = false
    @State private var blockedNotice = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                Text(participant.travelerName)
                    .font(AppFont.title3Bold)
                    .foregroundColor(AppColor.textPrimary)

                if isEscaped {
                    Text("이탈")
                        .font(AppFont.caption2Bold)
                        .foregroundColor(AppColor.danger)
                        .padding(.horizontal, 10)
                        .frame(height: 20)
                        .background(AppColor.dangerSubtle)
                        .cornerRadius(4)
                        .padding(.top, 2)
                }

                Spacer()

                Button(action: onClose) {
                    Text("✕")
                        .font(AppFont.bodyL)
                        .foregroundColor(AppColor.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, AppSpacing.xl)

            infoRow("국가", profile?.country ?? "—")
                .padding(.top, 22)
            passportRow
                .padding(.top, AppSpacing.sm)
            infoRow("전화번호", profile?.phone ?? "—")
                .padding(.top, AppSpacing.sm)
            infoRow("상태", statusLine, valueColor: AppColor.danger)
                .padding(.top, AppSpacing.sm)

            HStack(spacing: AppSpacing.sm) {
                Button { call() } label: {
                    Text("전화걸기")
                        .font(AppFont.bodyMedium)
                        .foregroundColor(hasPhone ? AppColor.textBody : AppColor.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.lg)
                }
                .buttonStyle(.plain)
                .disabled(!hasPhone)

                Button {
                    if canViewLocation { onViewLocation() } else { blockedNotice = true }
                } label: {
                    Text("위치보기")
                        .font(AppFont.bodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canViewLocation ? AppColor.accent : AppColor.borderMuted)
                        .cornerRadius(AppRadius.lg)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, AppSpacing.xl)

            if !hasPhone {
                Text("연락처가 등록되지 않았어요")
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.top, AppSpacing.xs)
            } else if blockedNotice {
                Text("위험 상태의 관광객만 위치를 볼 수 있어요")
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.top, AppSpacing.xs)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, AppSpacing.lg)
        // Figma 320x300 카드
        .frame(width: 320, height: 300, alignment: .top)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }

    private func infoRow(_ label: String, _ value: String, valueColor: Color = AppColor.textPrimary) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .frame(width: 66, alignment: .leading)
            Text(value)
                .font(AppFont.labelMedium)
                .foregroundColor(valueColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 여권번호 — 기본 마스킹, 👁 탭 시 3초만 공개
    private var passportRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("여권번호")
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
                .frame(width: 66, alignment: .leading)

            Text(hasPassport
                 ? (showsFullPassport ? (profile?.passportNumber ?? "") : (profile?.maskedPassport ?? ""))
                 : "—")
                .font(AppFont.labelMedium)
                .foregroundColor(AppColor.textPrimary)

            // 여권번호가 비어 있으면 눈 아이콘도 숨깁니다 (서버에 값이 없을 수 있습니다)
            if hasPassport {
                Button { revealPassport() } label: {
                    Text("👁")
                        .font(AppFont.label)
                }
                .buttonStyle(.plain)
                .padding(.leading, AppSpacing.xs)
            }
        }
    }

    private func revealPassport() {
        showsFullPassport = true
        // 3초 뒤 자동으로 다시 가립니다 (개인정보 열람 최소화)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showsFullPassport = false }
    }

    private var hasPassport: Bool {
        guard let passport = profile?.passportNumber else { return false }
        return !passport.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var hasPhone: Bool {
        guard let phone = profile?.phone else { return false }
        return !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func call() {
        guard let phone = profile?.phone else { return }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
