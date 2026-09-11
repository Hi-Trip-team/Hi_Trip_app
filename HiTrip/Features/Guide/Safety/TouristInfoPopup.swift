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
            HStack(alignment: .top, spacing: 8) {
                Text(participant.travelerName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))

                if isEscaped {
                    Text("이탈")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 10)
                        .frame(height: 20)
                        .background(Color(hex: "#FCE5E5"))
                        .cornerRadius(4)
                        .padding(.top, 2)
                }

                Spacer()

                Button(action: onClose) {
                    Text("✕")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)

            infoRow("국가", profile?.country ?? "—")
                .padding(.top, 22)
            passportRow
                .padding(.top, 12)
            infoRow("전화번호", profile?.phone ?? "—")
                .padding(.top, 12)
            infoRow("상태", statusLine, valueColor: Color(hex: "#EF4444"))
                .padding(.top, 12)

            HStack(spacing: 12) {
                Button { call() } label: {
                    Text("전화걸기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(hasPhone ? Color(hex: "#333840") : Color(hex: "#9CA3AF"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!hasPhone)

                Button {
                    if canViewLocation { onViewLocation() } else { blockedNotice = true }
                } label: {
                    Text("위치보기")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canViewLocation ? Color(hex: "#2563EB") : Color(hex: "#C3CDDA"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)

            if !hasPhone {
                Text("연락처가 등록되지 않았어요")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.top, 8)
            } else if blockedNotice {
                Text("위험 상태의 관광객만 위치를 볼 수 있어요")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        // Figma 320x300 카드
        .frame(width: 320, height: 300, alignment: .top)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(_ label: String, _ value: String, valueColor: Color = Color(hex: "#111827")) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 66, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(valueColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 여권번호 — 기본 마스킹, 👁 탭 시 3초만 공개
    private var passportRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("여권번호")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 66, alignment: .leading)

            Text(hasPassport
                 ? (showsFullPassport ? (profile?.passportNumber ?? "") : (profile?.maskedPassport ?? ""))
                 : "—")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))

            // 여권번호가 비어 있으면 눈 아이콘도 숨깁니다 (서버에 값이 없을 수 있습니다)
            if hasPassport {
                Button { revealPassport() } label: {
                    Text("👁")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
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
