import SwiftUI

// MARK: - NoticePopupView
/// 여행객용 공지사항 팝업 — 안내사가 등록한 활성 공지를 읽기 전용으로 표시
///
/// 여행객에게는 알림 센터(안전 지표·타 관광객 정보)를 노출하지 않고,
/// 이 공지 팝업만 제공합니다.

struct NoticePopupView: View {

    @Binding var isPresented: Bool

    let notice: TravelerNoticeDTO
    /// 지난 공지(비활성) — 없으면 "이전 공지 보기" 버튼을 숨깁니다
    var previousNotices: [TravelerNoticeDTO] = []

    @State private var showPrevious = false

    /// "2025.04.24 10:20"
    private var dateText: String {
        AppDate.string(iso: notice.publishedAt ?? notice.createdAt, "yyyy.MM.dd HH:mm")
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
            DimmedBackground(opacity: 0.35) { isPresented = false }

            popupCard
                .padding(.horizontal, AppSpacing.xl)
        }
    }

    private var popupCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(notice.title.isEmpty ? "공지사항" : notice.title)
                        .font(AppFont.headlineBold)
                        .foregroundColor(AppColor.textPrimary)
                    // 작성자명은 여행객 공지 API에 없어 날짜만 표시합니다 (백엔드 요청 중)
                    Text(dateText)
                        .font(AppFont.caption2)
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)

            ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(paragraphs, id: \.self) { p in
                    Text(p)
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
            }
            // 긴 공지도 팝업 안에서 읽을 수 있게 본문만 스크롤합니다
            .frame(maxHeight: 320)

            if !previousNotices.isEmpty {
            Divider()
                .padding(.horizontal, AppSpacing.lg)

            if showPrevious {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(previousNotices) { prev in
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(prev.title)
                                .font(AppFont.labelMedium)
                                .foregroundColor(AppColor.textPrimary)
                            Text(prev.content)
                                .font(AppFont.caption)
                                .foregroundColor(AppColor.textSecondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }

            Button { showPrevious.toggle() } label: {
                HStack(spacing: AppSpacing.xxs) {
                    Text("이전 공지 보기")
                        .font(AppFont.label)
                    Image(systemName: showPrevious ? "chevron.up" : "chevron.down")
                        .font(AppFont.microSemiBold)
                }
                .foregroundColor(AppColor.accent)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            }
        }
        .background(Color.white)
        .cornerRadius(AppRadius.xl)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
    }
}
