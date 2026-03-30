import SwiftUI

// MARK: - EmergencyAddView
/// 개인 긴급 연락처 추가 화면 (Sheet)
///
/// ChatCreateView, ScheduleCreateView와 동일한 패턴:
/// - Form 입력 → ViewModel 호출 → isCompleted로 시트 닫기

struct EmergencyAddView: View {

    @ObservedObject var viewModel: EmergencyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("연락처 정보") {
                    TextField("이름 (예: 엄마, 동행자)", text: $viewModel.name)

                    TextField("전화번호 (예: 010-1234-5678)", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(HiTripColor.error)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("연락처 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("추가") {
                        viewModel.addContact()
                    }
                    .disabled(!viewModel.isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: viewModel.isCompleted) { completed in
                if completed {
                    dismiss()
                }
            }
        }
    }
}
