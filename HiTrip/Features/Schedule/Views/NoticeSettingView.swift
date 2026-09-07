import SwiftUI

// MARK: - NoticeSettingView
/// 공지 설정 (안내사) — Figma 12381:5263
///
/// 활성 공지는 항상 최대 1건입니다. 다른 공지를 켜면 서버가 기존 것을 내립니다.
/// 활성 공지를 다시 누르면 해제되고, 그때 관광객 홈은 "등록된 공지가 없어요"가 됩니다.

struct NoticeSettingView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NoticeSettingViewModel()

    @State private var showEditor = false
    /// 수정 중인 공지 — nil이면 새 공지
    @State private var editingNotice: StaffNoticeDTO?
    @State private var draft = ""

    /// 작성 후 "지금 활성화할까요?"
    @State private var pendingActivationId: Int?
    /// ⋮ 메뉴 대상
    @State private var menuTarget: StaffNoticeDTO?
    /// 삭제 확인 대상
    @State private var deleteTarget: StaffNoticeDTO?
    /// 전문 보기
    @State private var detailTarget: StaffNoticeDTO?

    private let contentLimit = 500

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection

                Button {
                    editingNotice = nil
                    draft = ""
                    showEditor = true
                } label: {
                    Text("새 공지 작성하기")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#2563EB"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 33)

                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case .failed(let message):
                    errorView(message)
                case .loaded:
                    if viewModel.isEmpty {
                        emptyView
                    } else {
                        noticeList
                    }
                }
            }
            .background(Color.white)

            if showEditor {
                NoticeEditorPopup(
                    text: $draft,
                    limit: contentLimit,
                    isEditing: editingNotice != nil,
                    isSaving: viewModel.isSaving,
                    onCancel: { showEditor = false },
                    onSubmit: save
                )
            }

            if let notice = detailTarget {
                noticeDetailPopup(notice)
            }
        }
        .overlay(alignment: .bottom) { toastView }
        .animation(.easeInOut(duration: 0.2), value: showEditor)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .confirmationDialog(
            "이 공지를 지금 활성화할까요?",
            isPresented: Binding(
                get: { pendingActivationId != nil },
                set: { if !$0 { pendingActivationId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("예") {
                if let id = pendingActivationId { viewModel.activate(id: id) }
                pendingActivationId = nil
            }
            Button("아니오", role: .cancel) { pendingActivationId = nil }
        } message: {
            Text("기존 활성 공지는 자동으로 내려갑니다")
        }
        .confirmationDialog(
            "공지",
            isPresented: Binding(
                get: { menuTarget != nil },
                set: { if !$0 { menuTarget = nil } }
            ),
            titleVisibility: .hidden
        ) {
            Button("수정") {
                if let target = menuTarget {
                    editingNotice = target
                    draft = target.content
                    showEditor = true
                }
                menuTarget = nil
            }
            Button("삭제", role: .destructive) {
                deleteTarget = menuTarget
                menuTarget = nil
            }
            Button("취소", role: .cancel) { menuTarget = nil }
        }
        .confirmationDialog(
            "이 공지를 삭제할까요?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let target = deleteTarget { viewModel.delete(target) }
                deleteTarget = nil
            }
            Button("취소", role: .cancel) { deleteTarget = nil }
        } message: {
            Text(deleteTarget?.isActive == true
                 ? "활성 공지입니다. 삭제하면 관광객 홈에 공지가 표시되지 않습니다"
                 : "삭제한 공지는 되돌릴 수 없습니다")
        }
        .alert("처리하지 못했어요", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            Button("재시도") { viewModel.saveError = nil; save() }
            Button("닫기", role: .cancel) { viewModel.saveError = nil }
        } message: {
            Text(viewModel.saveError ?? "")
        }
    }

    // MARK: - 저장

    private func save() {
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, content.count <= contentLimit else { return }

        if let editing = editingNotice {
            viewModel.update(id: editing.id, content: content) { _ in
                showEditor = false
                draft = ""
                editingNotice = nil
            }
        } else {
            viewModel.create(content: content) { created in
                showEditor = false
                draft = ""
                // 저장 직후 활성화 여부를 묻습니다
                pendingActivationId = created.id
            }
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        ZStack {
            Text("공지 설정")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
            .padding(.leading, 12)
        }
        .frame(height: 24)
        .padding(.top, 8)
    }

    // MARK: - 목록

    private var noticeList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.notices, id: \.id) { notice in
                    noticeCard(notice)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .refreshable { viewModel.refresh() }
    }

    private func noticeCard(_ notice: StaffNoticeDTO) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                activeToggle(notice)

                if notice.isActive {
                    Text("활성")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#2563EB"))
                        .frame(width: 44, height: 20)
                        .background(Color(hex: "#E8F0FF"))
                        .cornerRadius(4)
                }

                Text(viewModel.dateText(notice))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))

                Spacer()

                Button { menuTarget = notice } label: {
                    Text("⋮")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // 한글 기준 2줄 말줄임 — 넘치면 행을 눌러 전문을 봅니다
            Text(notice.content)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#333840"))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(height: 104, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(notice.isActive ? Color(hex: "#2563EB") : Color(hex: "#E5E7EB"),
                        lineWidth: notice.isActive ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { detailTarget = notice }
    }

    /// 활성 토글 — w44 h24, 노브 18
    private func activeToggle(_ notice: StaffNoticeDTO) -> some View {
        Button { viewModel.toggleActive(notice) } label: {
            ZStack(alignment: notice.isActive ? .trailing : .leading) {
                Capsule()
                    .fill(notice.isActive ? Color(hex: "#2563EB") : Color(hex: "#E5E7EB"))
                    .frame(width: 44, height: 24)
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .padding(.horizontal, 3)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: notice.isActive)
    }

    // MARK: - 전문 팝업

    private func noticeDetailPopup(_ notice: StaffNoticeDTO) -> some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { detailTarget = nil }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(viewModel.dateText(notice))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#6B7280"))
                    Spacer()
                    Button { detailTarget = nil } label: {
                        Text("✕")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    Text(notice.content)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#333840"))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 240)
                .padding(.top, 16)
            }
            .padding(20)
            .frame(width: 330)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("공지를 불러오는 중이에요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        Text("작성된 공지가 없어요")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "#6B7280"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Button { viewModel.load() } label: {
                Text("재시도")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast = viewModel.toast {
            Text(toast)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Color(hex: "#111827").opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 40)
                .task(id: toast) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    viewModel.toast = nil
                }
        }
    }
}

// MARK: - 공지 작성 팝업
/// Figma 12381:5429 — 330×320 카드

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
