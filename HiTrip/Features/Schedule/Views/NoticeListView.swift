import SwiftUI

// MARK: - NoticeListView
/// 공지사항 전체 리스트 화면
///
/// 여행사가 그룹에 등록한 모든 공지사항을 시간순으로 표시.
/// 홈 화면의 공지 카드를 탭하면 이 화면으로 이동한다.
///
/// 디자인:
/// - 상단: "공지사항" 타이틀 + 뒤로가기
/// - 각 공지: 카드 형태 (제목, 내용, 날짜, 중요 뱃지)

struct NoticeListView: View {

    @ObservedObject var viewModel: TripListViewModel
    @Environment(\.dismiss) private var dismiss

    /// 날짜 포맷
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.allNotices.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    ForEach(viewModel.allNotices) { notice in
                        noticeRow(notice)
                    }
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(HiTripColor.screenBackground)
        .navigationTitle("공지사항")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
    }

    // MARK: - Notice Row

    private func noticeRow(_ notice: TripNotice) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 상단: 제목 + 중요 뱃지
            HStack(spacing: 8) {
                if notice.isImportant {
                    Text("중요")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                }

                Text(notice.title.isEmpty ? "공지" : notice.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)

                Spacer()

                if notice.isRepresentative {
                    Text("대표")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(HiTripColor.secondary700)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(HiTripColor.secondary700, lineWidth: 1)
                        )
                }
            }

            // 내용
            Text(notice.content)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .lineLimit(3)

            // 날짜
            Text(dateFormatter.string(from: notice.date))
                .font(.system(size: 12))
                .foregroundColor(HiTripColor.gray400)
        }
        .hiTripCard(padding: 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "megaphone")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)

            Text("등록된 공지사항이 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Text("여행사에서 공지를 등록하면 여기에 표시됩니다")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
        }
    }
}
