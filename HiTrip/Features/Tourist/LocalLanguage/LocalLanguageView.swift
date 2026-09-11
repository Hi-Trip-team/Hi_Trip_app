import SwiftUI

struct LocalLanguageView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocalLanguageViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .failed(let message):
                errorView(message)
            case .loaded:
                if viewModel.hasPhrases {
                    languageChip
                    phraseList
                } else {
                    emptyView
                }
            }
        }
        .background(Color.white)
        .toast($viewModel.toast)
        .animation(.easeInOut(duration: 0.2), value: viewModel.toast)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - 토스트

    // MARK: - Header

    private var headerSection: some View {
        NavigationHeader(title: "현지 언어 쓰기") {
            viewModel.stop()
            dismiss()
        }
    }

    // MARK: - 언어 칩

    private var languageChip: some View {
        HStack {
            Spacer()
            Text(viewModel.languageChipText)
                .font(AppFont.bodyMedium)
                .foregroundColor(AppColor.textBody)
                .padding(.horizontal, AppSpacing.sm)
                .frame(height: 32)
                .background(AppColor.surface)
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, 7)
        .padding(.bottom, 13)
    }

    // MARK: - 목록

    private var phraseList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 구분선은 각 행 위에만 둡니다 (마지막 행 아래에는 없음)
                ForEach(viewModel.phrases) { phrase in
                    Divider()
                        .padding(.leading, 17)
                        .padding(.trailing, AppSpacing.lg)
                    phraseRow(phrase)
                }
            }
        }
    }

    private func phraseRow(_ phrase: LocalPhraseDTO) -> some View {
        let isSpeaking = viewModel.speakingId == phrase.id

        return HStack(alignment: .center, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text(phrase.koreanText)
                    .font(AppFont.bodyMBold)
                    .foregroundColor(AppColor.gray800)
                    .fixedSize(horizontal: false, vertical: true)

                Text(phrase.translatedText)
                    .font(AppFont.captionMedium)
                    .foregroundColor(AppColor.accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text("발음: \(phrase.pronunciation)")
                    .font(AppFont.captionMedium)
                    .foregroundColor(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button { viewModel.toggleSpeak(phrase) } label: {
                ZStack {
                    Circle()
                        .fill(isSpeaking ? AppColor.danger : AppColor.accent)
                        .frame(width: 44, height: 44)
                    Text(isSpeaking ? "■" : "▶")
                        .font(AppFont.bodyBold)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSpeaking ? "재생 중지" : "발음 듣기")
        }
        .padding(.leading, AppSpacing.xxl)
        .padding(.trailing, 30)
        .padding(.top, 13)
        .padding(.bottom, 14)
    }

    // MARK: - 로딩 / 빈 상태 / 에러

    private var loadingView: some View {
        SkeletonList(rows: 5, rowHeight: 70)
    }

    private var emptyView: some View {
        EmptyStateView(icon: "text.bubble", title: "등록된 문구가 없어요", message: "안내사가 현지 문구를 등록하면\n여기에 표시됩니다")
    }

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) { viewModel.load() }
    }
}
