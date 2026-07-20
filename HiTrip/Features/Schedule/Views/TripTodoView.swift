import SwiftUI

// MARK: - TripTodoView
/// 할 일 탭 — 서버 체크리스트 표시
///
/// 데이터: GET /api/traveler/checklists/ (여행사 설정, 읽기 전용)
/// 허용 동작: 토글(체크/해제) → PATCH /api/traveler/checklists/{id}/
/// 불가 동작: 추가/수정/삭제 (여행사 전용 권한)

struct TripTodoView: View {

    @ObservedObject var viewModel: TripDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.allTodos.isEmpty {
                    emptyState
                        .padding(.top, 60)
                } else {
                    checklistContent
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 40)
            }
        }
        .background(HiTripColor.screenBackground)
    }

    // MARK: - 체크리스트 콘텐츠

    private var checklistContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 진행 현황 요약 카드
            progressSummary
                .padding(.bottom, 20)

            // 카테고리 칩
            categoryChip
                .padding(.bottom, 12)

            // 플레이스홀더 행 (비활성)
            placeholderRow
                .padding(.bottom, 4)

            // 전체 체크리스트 (미완료 → 완료 순)
            VStack(spacing: 0) {
                ForEach(viewModel.pendingTodos) { todo in
                    todoRow(todo)
                    Divider().padding(.leading, 40)
                }
                ForEach(viewModel.completedTodos) { todo in
                    todoRow(todo)
                    Divider().padding(.leading, 40)
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - 진행 현황 카드

    private var progressSummary: some View {
        let total = viewModel.allTodos.count
        let done  = viewModel.completedTodos.count
        let ratio = total > 0 ? CGFloat(done) / CGFloat(total) : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("체크리스트")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)
                Spacer()
                Text("\(done) / \(total) 완료")
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray500)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HiTripColor.gray200)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(HiTripColor.primary800)
                        .frame(width: geo.size.width * ratio, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - 카테고리 칩

    private var categoryChip: some View {
        Text("✈️ 오늘 일정 준비")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(HiTripColor.textBlack)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
    }

    // MARK: - 플레이스홀더 행

    private var placeholderRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .foregroundColor(HiTripColor.gray300)
                    .frame(width: 24, height: 24)
            }
            Text("체크리스트를 추가하세요.")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray300)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 체크리스트 행

    private func todoRow(_ todo: TripTodo) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // 체크 버튼
            Button {
                viewModel.toggleTodo(todo.id)
            } label: {
                if todo.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(HiTripColor.primary800)
                } else {
                    Circle()
                        .stroke(HiTripColor.gray300, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)

            // 텍스트
            Text(todo.title)
                .font(.system(size: 15))
                .foregroundColor(todo.isCompleted ? HiTripColor.gray400 : HiTripColor.textBlack)

            Spacer()

            // 더보기 버튼
            Button {
                // TODO: 더보기 액션 (여행사 전용 수정/삭제)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray400)
                    .rotationEffect(.degrees(90))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleTodo(todo.id) }
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)

            Text("체크리스트가 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Text("여행사에서 체크리스트를 등록하면 표시됩니다")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}
