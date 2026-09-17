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
    /// 비활성 확인 대상 — 서버가 재게시를 막아서 되돌릴 수 없습니다
    @State private var archiveTarget: StaffNoticeDTO?
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
                        .font(AppFont.bodyMBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.xl)
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
        .toast($viewModel.toast)
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
            "이 공지를 내릴까요?",
            isPresented: Binding(
                get: { archiveTarget != nil },
                set: { if !$0 { archiveTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("공지 내리기", role: .destructive) {
                if let target = archiveTarget { viewModel.toggleActive(target) }
                archiveTarget = nil
            }
            Button("취소", role: .cancel) { archiveTarget = nil }
        } message: {
            Text("한 번 내린 공지는 다시 활성화할 수 없습니다. 관광객 홈에는 공지가 표시되지 않습니다")
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
        NavigationHeader(title: "공지 설정", style: .compact) { dismiss() }
    }

    // MARK: - 목록

    private var noticeList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(viewModel.notices, id: \.id) { notice in
                    noticeCard(notice)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxl)
        }
        .refreshable { viewModel.refresh() }
    }

    private func noticeCard(_ notice: StaffNoticeDTO) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                activeToggle(notice)

                if notice.isActive {
                    Text("활성")
                        .font(AppFont.caption2Bold)
                        .foregroundColor(AppColor.accent)
                        .frame(width: 44, height: 20)
                        .background(AppColor.accentSubtle)
                        .cornerRadius(4)
                }

                Text(viewModel.dateText(notice))
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textSecondary)

                Spacer()

                Button { menuTarget = notice } label: {
                    Text("⋮")
                        .font(AppFont.bodyLBold)
                        .foregroundColor(AppColor.textSecondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // 한글 기준 2줄 말줄임 — 넘치면 행을 눌러 전문을 봅니다
            Text(notice.content)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textBody)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.lg)

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(height: 104, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(notice.isActive ? AppColor.accent : AppColor.divider,
                        lineWidth: notice.isActive ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { detailTarget = notice }
    }

    /// 활성 토글 — w44 h24, 노브 18
    ///
    /// 끄는 쪽은 되돌릴 수 없어(서버가 재게시를 막습니다) 한 번 확인합니다.
    private func activeToggle(_ notice: StaffNoticeDTO) -> some View {
        Button {
            if notice.isActive { archiveTarget = notice }
            else { viewModel.toggleActive(notice) }
        } label: {
            ZStack(alignment: notice.isActive ? .trailing : .leading) {
                Capsule()
                    .fill(notice.isActive ? AppColor.accent : AppColor.divider)
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
            DimmedBackground { detailTarget = nil }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(viewModel.dateText(notice))
                        .font(AppFont.caption2)
                        .foregroundColor(AppColor.textSecondary)
                    Spacer()
                    Button { detailTarget = nil } label: {
                        Text("✕")
                            .font(AppFont.bodyL)
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    Text(notice.content)
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textBody)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 240)
                .padding(.top, AppSpacing.md)
            }
            .padding(AppSpacing.lg)
            .frame(width: 330)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        }
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        SkeletonList(rows: 3, rowHeight: 104)
    }

    private var emptyView: some View {
        EmptyStateView(icon: "megaphone", title: "작성된 공지가 없어요")
    }

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) { viewModel.load() }
    }

}

// MARK: - 공지 작성 팝업
/// Figma 12381:5429 — 330×320 카드
