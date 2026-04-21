import SwiftUI

// MARK: - TripEventRow
/// 오늘의 일정 행 — 피그마 디자인
///
/// 구성:
/// - 왼쪽 세로 색상 바 (카테고리 컬러)
/// - 제목
/// - 시간 범위 (09:00 - 10:00)
/// - ... 메뉴 (수정/삭제)

struct TripEventRow: View {

    let event: TripEvent
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // 왼쪽 카테고리 색상 바
            RoundedRectangle(cornerRadius: 2)
                .fill(event.category.color)
                .frame(width: 4, height: 44)

            // 이벤트 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                Text(timeRangeText)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray500)
            }

            Spacer()

            // 더보기(...) 메뉴 — 수정/삭제
            if onDelete != nil || onEdit != nil {
                Menu {
                    if let onEdit = onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Label("수정", systemImage: "pencil")
                        }
                    }

                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(HiTripColor.gray400)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(10)
    }

    /// 시간 범위 텍스트 (예: "09:00 - 10:00")
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: event.startTime)) - \(formatter.string(from: event.endTime))"
    }
}
