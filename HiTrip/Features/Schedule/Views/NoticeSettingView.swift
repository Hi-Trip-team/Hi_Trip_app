import SwiftUI

struct NoticeSettingView: View {

    @Environment(\.dismiss) private var dismiss

    private let notices: [NoticeItem] = [
        NoticeItem(isActive: true, date: "04.24 10:20",
                   content: "오늘 자유 일정은 우천이 예상됩니다. 우산을 꼭 챙겨주세요. 집합 시간은 18:00 호텔 로비…"),
        NoticeItem(isActive: false, date: "04.24 08:00",
                   content: "조식은 2층 레스토랑에서 07:00부터 이용 가능합니다."),
        NoticeItem(isActive: false, date: "04.23 21:00",
                   content: "여행에 참여하신 여러분 모두 환영합니다! 이번 여행은 안전을 최우선으로 하는 웰니스 여행…"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            // 새 공지 버튼
            Button { } label: {
                Text("새 공지 작성하기")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(notices) { notice in
                        noticeCard(notice)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("공지 설정")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    // MARK: - 공지 카드

    private func noticeCard(_ notice: NoticeItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                // 토글 영역
                ZStack {
                    Capsule()
                        .fill(notice.isActive ? Color(hex: "#2563EB") : Color(hex: "#E5E7EB"))
                        .frame(width: 44, height: 24)
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .offset(x: notice.isActive ? 10 : -10)
                }

                if notice.isActive {
                    Text("활성")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#2563EB"))
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .background(Color(hex: "#E8F0FF"))
                        .cornerRadius(4)
                }

                Text(notice.date)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))

                Spacer()

                Text("⋮")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            Text(notice.content)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#333840"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(notice.isActive ? Color(hex: "#2563EB") : Color(hex: "#E5E7EB"),
                        lineWidth: notice.isActive ? 1.5 : 1)
        )
    }
}

private struct NoticeItem: Identifiable {
    let id = UUID()
    let isActive: Bool
    let date: String
    let content: String
}
