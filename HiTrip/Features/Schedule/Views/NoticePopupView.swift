import SwiftUI

// MARK: - NoticePopupView
/// 여행객용 공지사항 팝업 — 안내사가 등록한 활성 공지를 읽기 전용으로 표시
///
/// 여행객에게는 알림 센터(안전 지표·타 관광객 정보)를 노출하지 않고,
/// 이 공지 팝업만 제공합니다.

struct NoticePopupView: View {

    @Binding var isPresented: Bool

    var date: String = "2025.04.24 10:20"
    var author: String = "김안내 가이드"
    var paragraphs: [String] = [
        "오늘 자유 일정은 우천이 예상됩니다. 우산을 꼭 챙겨주세요.",
        "집합 시간은 18:00, 집합 장소는 호텔 1층 로비입니다.\n늦으시는 분은 단체톡방에 꼭 남겨주세요.",
        "안전한 여행 되세요!",
    ]

    @State private var showPrevious = false

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
                    Text("공지사항")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#111827"))
                    Text("\(date) · \(author)")
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

            Divider()
                .padding(.horizontal, 20)

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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
    }
}
