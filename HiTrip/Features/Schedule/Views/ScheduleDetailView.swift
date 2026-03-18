import SwiftUI

// MARK: - ScheduleDetailView
/// 일정 상세/수정 화면 — CRUD의 [R] 상세 조회 + [U] Update + [D] Delete
///
/// 두 가지 모드:
/// - 보기 모드: 일정 상세 정보 표시 + 수정/삭제 버튼
/// - 수정 모드: ScheduleCreateView와 동일한 폼 (기존 데이터 채워짐)
///
/// 동작:
/// - "수정" 탭 → 수정 모드 전환 → 폼에 기존 데이터 로드
/// - "저장" 탭 → viewModel.updateSchedule() → 성공 시 시트 닫기
/// - "삭제" 탭 → 확인 Alert → viewModel.deleteSchedule() → 시트 닫기

struct ScheduleDetailView: View {

    @ObservedObject var viewModel: ScheduleViewModel

    /// 상세 보기 대상 일정
    let schedule: Schedule

    @Environment(\.dismiss) private var dismiss

    /// 보기 모드 / 수정 모드 전환
    @State private var isEditing = false

    /// 삭제 확인 Alert 표시 여부
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    editForm
                } else {
                    detailContent
                }
            }
            .navigationTitle(isEditing ? "일정 수정" : "일정 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 왼쪽 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("취소") {
                            isEditing = false
                        }
                    } else {
                        Button("닫기") {
                            dismiss()
                        }
                    }
                }

                // 오른쪽 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("저장") {
                            viewModel.updateSchedule(schedule)
                        }
                        .disabled(!viewModel.isTitleValid)
                        .fontWeight(.semibold)
                    } else {
                        Button("수정") {
                            viewModel.loadScheduleForEdit(schedule)
                            isEditing = true
                        }
                    }
                }
            }
            // 수정 완료 시 시트 닫기
            .onChange(of: viewModel.isCompleted) { completed in
                if completed {
                    viewModel.isCompleted = false
                    dismiss()
                }
            }
            // 삭제 확인 Alert
            .alert("일정 삭제", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) {
                    viewModel.deleteSchedule(id: schedule.id)
                    dismiss()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("'\(schedule.title)' 일정을 삭제하시겠습니까?")
            }
        }
    }

    // MARK: - Detail Content (보기 모드)

    /// 일정 상세 정보 표시
    private var detailContent: some View {
        List {
            // 제목
            Section("제목") {
                Text(schedule.title)
                    .font(.system(size: 16, weight: .medium))
            }

            // 날짜
            Section("날짜") {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(HiTripColor.primary800)
                    Text(schedule.date.formatted(date: .long, time: .shortened))
                }
            }

            // 장소 (있을 때만)
            if !schedule.location.isEmpty {
                Section("장소") {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(HiTripColor.primary800)
                        Text(schedule.location)
                    }
                }
            }

            // 설명 (있을 때만)
            if !schedule.description.isEmpty {
                Section("설명") {
                    Text(schedule.description)
                        .font(.system(size: 15))
                        .foregroundColor(HiTripColor.textGrayA)
                }
            }

            // 삭제 버튼
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("일정 삭제")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Edit Form (수정 모드)

    /// 수정 폼 — ScheduleCreateView와 동일한 구조
    private var editForm: some View {
        Form {
            Section("제목") {
                TextField("일정 제목을 입력하세요", text: $viewModel.title)
            }

            Section("날짜") {
                DatePicker(
                    "일정 날짜",
                    selection: $viewModel.date,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            Section("장소") {
                TextField("장소를 입력하세요 (선택)", text: $viewModel.location)
            }

            Section("설명") {
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 100)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(HiTripColor.error)
                        .font(.system(size: 14))
                }
            }
        }
    }
}
