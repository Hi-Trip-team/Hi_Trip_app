import SwiftUI

// MARK: - NoticePopupView
/// 여행객용 공지사항 팝업 — 안내사가 등록한 활성 공지를 읽기 전용으로 표시
///
/// 여행객에게는 알림 센터(안전 지표·타 관광객 정보)를 노출하지 않고,
/// 이 공지 팝업만 제공합니다.

struct NoticePopupView: View {

    @Binding var isPresented: Bool

    let notice: TravelerNoticeDTO
    /// 접어둔 이전 공지들 — 없으면 "이전 공지 보기" 버튼을 숨깁니다
    var previousNotices: [TravelerNoticeDTO] = []

    @State private var showPrevious = false

    /// "2025.04.24 10:20"
    private var dateText: String {
        guard let raw = notice.publishedAt ?? notice.createdAt else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw) else { return "" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f.string(from: date)
    }

    /// 본문을 빈 줄 기준으로 문단으로 나눕니다
    private var paragraphs: [String] {
        notice.content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            popupCard
                .padding(.horizontal, 24)
        }
    }

    private var popupCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(notice.title.isEmpty ? "공지사항" : notice.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#111827"))
                    // 작성자명은 여행객 공지 API에 없어 날짜만 표시합니다 (백엔드 요청 중)
                    Text(dateText)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(paragraphs, id: \.self) { p in
                    Text(p)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#333840"))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            if !previousNotices.isEmpty {
            Divider()
                .padding(.horizontal, 20)

            if showPrevious {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(previousNotices) { prev in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prev.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#111827"))
                            Text(prev.content)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#6B7280"))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            Button { showPrevious.toggle() } label: {
                HStack(spacing: 4) {
                    Text("이전 공지 보기")
                        .font(.system(size: 13))
                    Image(systemName: showPrevious ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#2563EB"))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
    }
}
