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
            // 진행 현황 요약
            progressSummary
                .padding(.bottom, 20)

            // 미완료 항목
            if !viewModel.pendingTodos.isEmpty {
                sectionHeader(title: "할 일", emoji: "⬜", count: viewModel.pendingTodos.count)
                    .padding(.bottom, 10)

                VStack(spacing: 2) {
                    ForEach(viewModel.pendingTodos) { todo in
                        todoRow(todo)
                    }
                }
                .padding(.bottom, 24)
            }

            // 완료 항목
            if !viewModel.completedTodos.isEmpty {
                sectionHeader(title: "완료", emoji: "✅", count: viewModel.completedTodos.count)
                    .padding(.bottom, 10)

                VStack(spacing: 2) {
                    ForEach(viewModel.completedTodos) { todo in
                        todoRow(todo)
                    }
                }
            }
        }
    }

    // MARK: - 진행 현황

    private var progressSummary: some View {
        let total = viewModel.allTodos.count
        let done = viewModel.completedTodos.count
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

    // MARK: - 섹션 헤더

    private func sectionHeader(title: String, emoji: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(emoji).font(.system(size: 13))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)
            Text("(\(count))")
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.gray400)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(HiTripColor.sectionTagBackground)
        .cornerRadius(18)
    }

    // MARK: - 체크리스트 행

    private func todoRow(_ todo: TripTodo) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 체크 버튼
            Button {
                viewModel.toggleTodo(todo.id)
            } label: {
                ZStack {
                    if todo.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(HiTripColor.primary800)
                    } else {
                        Circle()
                            .stroke(HiTripColor.gray300, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            // 텍스트
            VStack(alignment: .leading, spacing: 3) {
                Text(todo.title)
                    .font(.system(size: 15))
                    .foregroundColor(todo.isCompleted ? HiTripColor.gray400 : HiTripColor.textBlack)
                    .strikethrough(todo.isCompleted, color: HiTripColor.gray400)

                if let subtitle = todo.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray400)
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
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
