import SwiftUI
import SwiftData

// MARK: - TripTodoView
/// 할 일 탭
///
/// 두 가지 할일을 함께 표시:
/// - 가이드 체크리스트: 서버에서 내려옴, 토글만 가능
/// - 내 할일: SwiftData 로컬 저장, 직접 추가/완료/삭제 가능

struct TripTodoView: View {

    @ObservedObject var viewModel: TripDetailViewModel

    // SwiftData — 현재 여행의 개인 할일만 쿼리
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonalTodo.createdAt) private var allPersonalTodos: [PersonalTodo]

    // 현재 여행 ID 기준 필터
    private var personalTodos: [PersonalTodo] {
        guard let tripId = TripDataStore.shared.currentPackage?.id else { return [] }
        return allPersonalTodos.filter { $0.tripId == tripId }
    }

    @State private var newTodoText = ""
    @State private var isAddingTodo = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.allTodos.isEmpty && personalTodos.isEmpty {
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
        .background(Color.white)
    }

    // MARK: - 전체 콘텐츠

    private var checklistContent: some View {
        VStack(alignment: .leading, spacing: 16) {

            // 진행 현황 카드
            progressSummary

            // ── 가이드 체크리스트 섹션 ──
            if !viewModel.allTodos.isEmpty {
                sectionHeader(title: "✈️ 가이드 체크리스트", isGuide: true)

                VStack(spacing: 0) {
                    ForEach(viewModel.pendingTodos) { todo in
                        guideTodoRow(todo)
                        Divider().padding(.leading, 52)
                    }
                    ForEach(viewModel.completedTodos) { todo in
                        guideTodoRow(todo)
                        if todo.id != viewModel.completedTodos.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 10, x: 0, y: 2)
            }

            // ── 내 할일 섹션 ──
            sectionHeader(title: "📝 내 할일", isGuide: false)

            VStack(spacing: 0) {
                // 추가 입력 행
                addRow

                let pending   = personalTodos.filter { !$0.isCompleted }
                let completed = personalTodos.filter {  $0.isCompleted }

                if !pending.isEmpty {
                    Divider().padding(.leading, 52)
                    ForEach(pending) { todo in
                        personalTodoRow(todo)
                        if todo.id != pending.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                if !completed.isEmpty {
                    Divider().padding(.leading, 52)
                    ForEach(completed) { todo in
                        personalTodoRow(todo)
                        if todo.id != completed.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 10, x: 0, y: 2)
        }
    }

    // MARK: - 섹션 헤더

    private func sectionHeader(title: String, isGuide: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HiTripColor.gray500)
            Spacer()
            if isGuide {
                Text("가이드 전용")
                    .font(.system(size: 11))
                    .foregroundColor(HiTripColor.gray300)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(HiTripColor.gray100)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - 진행 현황 카드

    private var progressSummary: some View {
        let guideDone    = viewModel.completedTodos.count
        let guideTotal   = viewModel.allTodos.count
        let personalDone = personalTodos.filter { $0.isCompleted }.count
        let personalTotal = personalTodos.count
        let done  = guideDone + personalDone
        let total = guideTotal + personalTotal
        let ratio = total > 0 ? CGFloat(done) / CGFloat(total) : 0

        return VStack(alignment: .leading, spacing: 10) {
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
        .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 10, x: 0, y: 2)
    }

    // MARK: - 가이드 할일 행 (토글만)

    private func guideTodoRow(_ todo: TripTodo) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Button { viewModel.toggleTodo(todo.id) } label: {
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

            Text(todo.title)
                .font(.system(size: 15))
                .foregroundColor(todo.isCompleted ? HiTripColor.gray400 : HiTripColor.textBlack)
                .strikethrough(todo.isCompleted, color: HiTripColor.gray300)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleTodo(todo.id) }
    }

    // MARK: - 개인 할일 추가 행

    private var addRow: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .foregroundColor(HiTripColor.primary800.opacity(0.14))
            }
            .frame(width: 24, height: 24)

            if isAddingTodo {
                TextField("할일을 입력하세요", text: $newTodoText)
                    .font(.system(size: 15))
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit { commitNewTodo() }

                if !newTodoText.isEmpty {
                    Button { commitNewTodo() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(HiTripColor.primary800)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    isAddingTodo = true
                    isTextFieldFocused = true
                } label: {
                    Text("할일 추가하기")
                        .font(.system(size: 15))
                        .foregroundColor(HiTripColor.gray400)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .animation(.easeInOut(duration: 0.15), value: isAddingTodo)
    }

    // MARK: - 개인 할일 행 (토글 + 삭제)

    private func personalTodoRow(_ todo: PersonalTodo) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Button { todo.isCompleted.toggle() } label: {
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

            Text(todo.title)
                .font(.system(size: 15))
                .foregroundColor(todo.isCompleted ? HiTripColor.gray400 : HiTripColor.textBlack)
                .strikethrough(todo.isCompleted, color: HiTripColor.gray300)

            Spacer()

            // 삭제 버튼
            Button { deleteTodo(todo) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(HiTripColor.gray300)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture { todo.isCompleted.toggle() }
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

            Text("가이드가 체크리스트를 등록하거나\n직접 할일을 추가해보세요")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Actions

    private func commitNewTodo() {
        let text = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            isAddingTodo = false
            return
        }
        let tripId = TripDataStore.shared.currentPackage?.id ?? UUID()
        let todo = PersonalTodo(title: text, tripId: tripId)
        modelContext.insert(todo)
        newTodoText = ""
        isAddingTodo = false
        isTextFieldFocused = false
    }

    private func deleteTodo(_ todo: PersonalTodo) {
        modelContext.delete(todo)
    }
}
