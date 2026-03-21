import SwiftUI

// MARK: - ChatCreateView
/// 채팅방 생성 화면 (Sheet)
///
/// ScheduleCreateView와 동일한 패턴:
/// - Form으로 입력 폼 구성
/// - @Environment(\.dismiss)로 시트 닫기
/// - .onChange(of: isCompleted)로 생성 완료 시 자동 닫기

struct ChatCreateView: View {

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 상대방 정보

                Section("상대방 정보") {
                    TextField("이름", text: $viewModel.participantName)

                    Picker("유형", selection: $viewModel.participantType) {
                        Text("안내사").tag("guide")
                        Text("관광객").tag("tourist")
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - 에러 메시지

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(HiTripColor.error)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("새 채팅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("만들기") {
                        viewModel.createChatRoom()
                    }
                    .disabled(viewModel.participantName.trimmed.isEmpty)
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
