import SwiftUI

struct NoticeEditorPopup: View {

    @Binding var text: String
    let limit: Int
    let isEditing: Bool
    let isSaving: Bool
    var onCancel: () -> Void
    var onSubmit: () -> Void

    @State private var showDiscardConfirm = false

    /// 공백·개행만 있으면 작성완료를 막습니다
    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && text.count <= limit
            && !isSaving
    }

    private var isOverLimit: Bool { text.count > limit }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { requestCancel() }

            VStack(alignment: .leading, spacing: 0) {
                Text(isEditing ? "공지 수정" : "새 공지 작성")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.top, 22)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#F3F4F6"))

                    if text.isEmpty {
                        Text("새 공지를 작성하세요")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }

                    // 입력 중에 자르지 않습니다 (조합형 문자 입력이 깨집니다)
                    TextEditor(text: $text)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#111827"))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .frame(height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOverLimit ? Color(hex: "#EF4444") : .clear, lineWidth: 1)
                )
                .padding(.top, 14)

                HStack {
                    Spacer()
                    Text("\(text.count)/\(limit)")
                        .font(.system(size: 11, weight: isOverLimit ? .bold : .regular))
                        .foregroundColor(isOverLimit ? Color(hex: "#EF4444") : Color(hex: "#6B7280"))
                }
                .padding(.top, 8)

                HStack(spacing: 12) {
                    Button { requestCancel() } label: {
                        Text("취소하기")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#333840"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#F3F4F6"))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button { onSubmit() } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("작성완료")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canSubmit ? Color(hex: "#2563EB") : Color(hex: "#C3CDDA"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                }
                .padding(.top, 26)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .frame(width: 330, height: 320, alignment: .top)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .confirmationDialog("작성을 취소할까요?", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button("작성 취소", role: .destructive) { onCancel() }
            Button("계속 작성", role: .cancel) { }
        } message: {
            Text("내용은 저장되지 않습니다")
        }
    }

    private func requestCancel() {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onCancel()
        } else {
            showDiscardConfirm = true
        }
    }
}
