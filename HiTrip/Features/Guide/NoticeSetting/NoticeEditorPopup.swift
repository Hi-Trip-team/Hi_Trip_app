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
                    .font(AppFont.bodyLBold)
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.top, 22)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(AppColor.surface)

                    if text.isEmpty {
                        Text("새 공지를 작성하세요")
                            .font(AppFont.label)
                            .foregroundColor(AppColor.textSecondary)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.md)
                    }

                    // 입력 중에 자르지 않습니다 (조합형 문자 입력이 깨집니다)
                    TextEditor(text: $text)
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, 10)
                }
                .frame(height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(isOverLimit ? AppColor.danger : .clear, lineWidth: 1)
                )
                .padding(.top, 14)

                HStack {
                    Spacer()
                    Text("\(text.count)/\(limit)")
                        .font(isOverLimit ? AppFont.caption2Bold : AppFont.caption2)
                        .foregroundColor(isOverLimit ? AppColor.danger : AppColor.textSecondary)
                }
                .padding(.top, AppSpacing.xs)

                HStack(spacing: AppSpacing.sm) {
                    Button { requestCancel() } label: {
                        Text("취소하기")
                            .font(AppFont.bodyMedium)
                            .foregroundColor(AppColor.textBody)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(AppColor.surface)
                            .cornerRadius(AppRadius.lg)
                    }
                    .buttonStyle(.plain)

                    Button { onSubmit() } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("작성완료")
                                    .font(AppFont.bodyBold)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canSubmit ? AppColor.accent : AppColor.borderMuted)
                        .cornerRadius(AppRadius.lg)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                }
                .padding(.top, 26)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
            .frame(width: 330, height: 320, alignment: .top)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
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
