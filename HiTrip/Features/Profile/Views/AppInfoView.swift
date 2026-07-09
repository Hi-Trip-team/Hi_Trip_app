import SwiftUI

// MARK: - AppInfoView
/// 버전정보 화면 — 피그마 디자인 반영
///
/// 구성: 히어로 헤더 (풀너비) → 서비스 소개 카드 → 앱 정보 카드 → 하단 링크

struct AppInfoView: View {

    private let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 히어로 헤더 (풀너비, 마진 없음)
                heroHeader

                // 서비스 소개
                serviceSection

                // 앱 정보
                appInfoSection

                // 하단 링크
                footerLinks
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
        }
        .background(HiTripColor.screenBackground)
        .navigationTitle("버전정보")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack {
            LinearGradient(
                colors: [HiTripColor.primary800, Color(hex: "3A5BD9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 14) {
                Spacer().frame(height: 12)

                Text("Hi Trip")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                Text("여행 중 안전·관리·콘텐츠 통합 SaaS\n여행사·가이드·여행자를 연결하는\n스마트 여행 플랫폼")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)

                Text("v\(appVersion)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Capsule())

                Spacer().frame(height: 12)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    // MARK: - Service Section

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("서비스 소개")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Text("하이트립은 여행 중 발생하는 모든 상황을\n하나의 플랫폼에서 처리합니다.")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 14) {
                featureRow("실시간 안전 모니터링 및 SOS 긴급 구조 연결")
                featureRow("여행사·가이드·여행자 통합 일정 관리")
                featureRow("경비 정산 및 참가자 납부 현황 관리")
                featureRow("현지 맞춤 명소 AI 기반 콘텐츠 추천")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .padding(.horizontal, 20)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(HiTripColor.primary800)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.textBlack)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("앱 정보")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                infoRow(label: "버전", value: "v\(appVersion) (2025.05)")
                Divider()
                infoRow(label: "개발사", value: "하이트립 주식회사")
                Divider()
                infoRow(label: "최소 지원", value: "iOS 16.0 이상")
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .padding(.horizontal, 20)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("이용약관")
                    .foregroundColor(HiTripColor.accentLink)
                Text("개인정보처리방침")
                    .foregroundColor(HiTripColor.accentLink)
                Text("고객센터")
                    .foregroundColor(HiTripColor.accentLink)
            }
            .font(.system(size: 13))

            Text("© 2026 Hi Trip Inc. All rights reserved.")
                .font(.system(size: 12))
                .foregroundColor(HiTripColor.gray400)
        }
        .frame(maxWidth: .infinity)
    }
}
