import SwiftUI

// MARK: - TripTodoView
/// 화면2: 할일 탭 — 체크리스트
///
/// 피그마 디자인:
/// - 주간 캘린더 스트립 (월요일 시작)
/// - "오늘 일정 준비" 섹션 체크리스트
/// - "여행 준비 & 관리" 섹션 체크리스트
/// - 각 항목: 체크 원 + 텍스트 + 더보기(...)
/// - 섹션 상단에 "체크리스트를 추가하세요." placeholder

struct TripTodoView: View {

    @ObservedObject var viewModel: TripDetailViewModel
    @State private var newTodoText: String = ""
    @State private var addingSection: TripTodo.Section?

    /// 수정 모드: 편집 중인 Todo ID + 텍스트
    @State private var editingTodoId: UUID?
    @State private var editingTodoText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 주간 캘린더 스트립
                WeekCalendarStripView(
                    selectedDate: $viewModel.selectedDate,
                    style: .mondayStart
                )
                .padding(.top, 8)

                // "오늘 일정 준비" 섹션
                todoSection(
                    title: "오늘 일정 준비",
                    emoji: "🏖",
                    section: .todayPrep,
                    todos: viewModel.todayPrepTodos
                )
                .padding(.top, 20)

                // "여행 준비 & 관리" 섹션
                todoSection(
                    title: "여행 준비 & 관리",
                    emoji: "🧳",
                    section: .travelPrep,
                    todos: viewModel.travelPrepTodos
                )
                .padding(.top, 20)

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - Todo Section

    private func todoSection(
        title: String,
        emoji: String,
        section: TripTodo.Section,
        todos: [TripTodo]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 섹션 헤더 태그
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(HiTripColor.gray100)
            .cornerRadius(20)
            .padding(.bottom, 12)

            // "체크리스트를 추가하세요" placeholder + 추가 기능
            addTodoRow(section: section)
                .padding(.bottom, 4)

            // 체크리스트 항목들
            ForEach(todos) { todo in
                todoRow(todo)
                    .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Add Todo Row

    private func addTodoRow(section: TripTodo.Section) -> some View {
        Group {
            if addingSection == section {
                // 입력 모드
                HStack(spacing: 10) {
                    Circle()
                        .stroke(HiTripColor.gray300, lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    TextField("할 일을 입력하세요", text: $newTodoText)
                        .font(.system(size: 15))
                        .onSubmit {
                            if !newTodoText.trimmed.isEmpty {
                                viewModel.addTodo(title: newTodoText.trimmed, section: section)
                                newTodoText = ""
                            }
                            addingSection = nil
                        }
                }
            } else {
                // placeholder 모드
                Button {
                    addingSection = section
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .stroke(HiTripColor.gray300.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 22, height: 22)

                        Text("체크리스트를 추가하세요.")
                            .font(.system(size: 15))
                            .foregroundColor(HiTripColor.gray300)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Todo Row

    private func todoRow(_ todo: TripTodo) -> some View {
        HStack(spacing: 10) {
            // 체크 원
            Button {
                viewModel.toggleTodo(todo.id)
            } label: {
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
            .buttonStyle(.plain)

            // 텍스트 (수정 모드 / 표시 모드)
            if editingTodoId == todo.id {
                TextField("할 일 수정", text: $editingTodoText)
                    .font(.system(size: 15))
                    .onSubmit {
                        if !editingTodoText.trimmed.isEmpty {
                            viewModel.updateTodo(todo.id, newTitle: editingTodoText.trimmed)
                        }
                        editingTodoId = nil
                    }
            } else {
                Text(todo.title)
                    .font(.system(size: 15))
                    .foregroundColor(
                        todo.isCompleted ? HiTripColor.gray400 : HiTripColor.textBlack
                    )
                    .strikethrough(todo.isCompleted, color: HiTripColor.gray400)
            }

            Spacer()

            // 더보기(...) 메뉴 — 수정/삭제
            Menu {
                Button {
                    editingTodoText = todo.title
                    editingTodoId = todo.id
                } label: {
                    Label("수정", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    withAnimation { viewModel.deleteTodo(todo.id) }
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(HiTripColor.gray400)
                    .frame(width: 28, height: 28)
            }
        }
    }
}
