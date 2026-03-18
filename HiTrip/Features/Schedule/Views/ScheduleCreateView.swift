import SwiftUI

// MARK: - ScheduleCreateView
/// 일정 생성 화면 — CRUD의 [C] Create 담당
///
/// UI 구성:
/// - 네비게이션 바 (취소 + 저장 버튼)
/// - 제목 입력 (필수)
/// - 날짜 선택 (DatePicker)
/// - 장소 입력 (선택)
/// - 설명 입력 (선택, TextEditor)
///
/// 동작:
/// 1. 사용자가 폼 입력
/// 2. "저장" 탭 → viewModel.createSchedule()
/// 3. 성공 → isCompleted = true → 시트 닫기

struct ScheduleCreateView: View {

    @ObservedObject var viewModel: ScheduleViewModel

    /// 시트를 닫기 위한 환경 변수
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // 제목 (필수)
                Section("제목") {
                    TextField("일정 제목을 입력하세요", text: $viewModel.title)
                }

                // 날짜
                Section("날짜") {
                    DatePicker(
                        "일정 날짜",
                        selection: $viewModel.date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                // 장소 (선택)
                Section("장소") {
                    TextField("장소를 입력하세요 (선택)", text: $viewModel.location)
                }

                // 설명 (선택)
                Section("설명") {
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 100)
                }

                // 에러 메시지
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(HiTripColor.error)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("일정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 왼쪽: 취소
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                // 오른쪽: 저장
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        viewModel.createSchedule()
                    }
                    .disabled(!viewModel.isTitleValid)
                    .fontWeight(.semibold)
                }
            }
            // 생성 완료 시 시트 닫기
            .onChange(of: viewModel.isCompleted) { completed in
                if completed { dismiss() }
            }
        }
    }
}
