import SwiftUI

// MARK: - AppInfoView
/// 버전정보 화면
///
/// 서비스 소개 · 앱 정보 · 하단 링크(이용약관, 개인정보처리방침, 고객센터)

struct AppInfoView: View {

    private let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 히어로 헤더
                heroHeader

                // 서비스 소개
                serviceSection
                    .padding(.top, 28)

                // 앱 정보 테이블
                appInfoSection
                    .padding(.top, 24)

                // 하단 링크
                footerLinks
                    .padding(.top, 32)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(HiTripColor.screenBackground)
        .navigationTitle("버전정보")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 36)

            Text("Hi Trip")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)

            Text("여행 중 안전·관리·콘텐츠 통합 SaaS\n여행사·가이드·여행자를 연결하는\n스마트 여행 플랫폼")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("v\(appVersion)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)

            Spacer().frame(height: 36)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [HiTripColor.primary800, HiTripColor.secondary600],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.top, 8)
    }

    // MARK: - Service Section

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("서비스 소개")

            Text("하이트립은 여행 중 발생하는 모든 상황을\n하나의 플랫폼에서 처리합니다.")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("실시간 안전 모니터링 및 SOS 긴급 구조 연결")
                featureRow("여행사·가이드·여행자 통합 일정 관리")
                featureRow("경비 정산 및 참가자 납부 현황 관리")
                featureRow("현지 맞춤 명소 AI 기반 콘텐츠 추천")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(HiTripColor.primary800)
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.textBlack)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("앱 정보")

            VStack(spacing: 0) {
                infoRow(label: "버전", value: "v\(appVersion) (2025.05)")
                Divider().padding(.leading, 16)
                infoRow(label: "개발사", value: "하이트립 주식회사")
                Divider().padding(.leading, 16)
                infoRow(label: "최소 지원", value: "iOS 16.0 이상")
                Divider().padding(.leading, 16)
                infoRow(label: "빌드 번호", value: buildNumber)
            }
            .background(Color.white)
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray500)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(HiTripColor.textBlack)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                linkButton("이용약관")
                Text(" · ")
                    .foregroundColor(HiTripColor.gray300)
                linkButton("개인정보처리방침")
                Text(" · ")
                    .foregroundColor(HiTripColor.gray300)
                linkButton("고객센터")
            }
            .font(.system(size: 13))

            Text("© 2026 Hi Trip Inc. All rights reserved.")
                .font(.system(size: 12))
                .foregroundColor(HiTripColor.gray400)
        }
        .frame(maxWidth: .infinity)
    }

    private func linkButton(_ title: String) -> some View {
        Text(title)
            .foregroundColor(HiTripColor.accentLink)
    }

    // MARK: - Section Title

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(HiTripColor.textBlack)
    }
}
