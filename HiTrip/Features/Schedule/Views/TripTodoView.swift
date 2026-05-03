import SwiftUI

// MARK: - TripTodoView
/// 할 일 탭 — 체크리스트
///
/// 피그마 디자인:
/// - "✈️ 오늘 일정 준비" 섹션 (배경 #F4F3F9, radius 18)
/// - "🧳 여행 준비 & 관리" 섹션
/// - 각 항목: 체크 원(고정 22x22) + 텍스트 + 더보기(...)
/// - "체크리스트를 추가하세요." placeholder
///
/// 주간 캘린더 스트립은 TripDetailView에서 공용으로 표시

struct TripTodoView: View {

    @ObservedObject var viewModel: TripDetailViewModel
    @State private var newTodoText: String = ""
    @State private var addingSection: TripTodo.Section?

    /// 수정 모드: 편집 중인 Todo ID + 텍스트
    @State private var editingTodoId: UUID?
    @State private var editingTodoText: String = ""

    /// 섹션 헤더 배경색
    private let sectionTagBackground = HiTripColor.sectionTagBackground

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // "오늘 일정 준비" 섹션
                todoSection(
                    title: "오늘 일정 준비",
                    emoji: "✈️",
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
                .padding(.top, 24)

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
            // 섹션 헤더 태그 (pill, 배경 #F4F3F9, radius 18)
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(sectionTagBackground)
            .cornerRadius(18)
            .padding(.bottom, 14)

            // "체크리스트를 추가하세요" placeholder + 추가 기능
            addTodoRow(section: section)

            // 체크리스트 항목들
            ForEach(todos) { todo in
                todoRow(todo)
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
                .padding(.vertical, 4)
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
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Todo Row

    private func todoRow(_ todo: TripTodo) -> some View {
        HStack(spacing: 10) {
            // 체크 원 — 고정 프레임으로 위치 이동 방지
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
                    }
                }
                .frame(width: 22, height: 22)
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
        .padding(.vertical, 4)
    }
}
