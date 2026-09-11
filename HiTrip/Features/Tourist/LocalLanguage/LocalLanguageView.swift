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
        .overlay(alignment: .bottom) { toastView }
        .animation(.easeInOut(duration: 0.2), value: viewModel.toast)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - 토스트

    @ViewBuilder
    private var toastView: some View {
        if let toast = viewModel.toast {
            Text(toast)
                .font(AppFont.labelMedium)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(AppColor.textPrimary.opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 40)
                .transition(.opacity)
                .task(id: toast) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    viewModel.toast = nil
                }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("현지 언어 쓰기")
                .font(AppFont.headlineBold)
                .foregroundColor(.black)
            HStack {
                Button {
                    viewModel.stop()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(AppFont.title3Medium)
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.sm)
        }
        .frame(height: 44)
        .padding(.top, AppSpacing.xs)
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
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text("현지 표현을 불러오는 중이에요")
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.bubble")
                .font(AppFont.logo)
                .foregroundColor(AppColor.borderStrong)
            Text("등록된 문구가 없어요")
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
            Text("안내사가 현지 문구를 등록하면\n여기에 표시됩니다")
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.bubble")
                .font(AppFont.emojiXL)
                .foregroundColor(AppColor.borderStrong)
            Text(message)
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Button { viewModel.load() } label: {
                Text("다시 시도")
                    .font(AppFont.bodyBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .frame(height: 44)
                    .background(AppColor.accent)
                    .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
