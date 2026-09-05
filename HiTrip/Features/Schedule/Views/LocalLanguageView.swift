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
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("현지 언어 쓰기")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
            HStack {
                Button {
                    viewModel.stop()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    // MARK: - 언어 칩

    private var languageChip: some View {
        HStack {
            Spacer()
            Text(viewModel.languageChipText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#333840"))
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color(hex: "#F3F4F6"))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
        .padding(.top, 7)
        .padding(.bottom, 13)
    }

    // MARK: - 목록

    private var phraseList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Divider().padding(.horizontal, 17)

                ForEach(viewModel.phrases) { phrase in
                    phraseRow(phrase)
                    Divider().padding(.horizontal, 17)
                }
            }
        }
    }

    private func phraseRow(_ phrase: LocalPhraseDTO) -> some View {
        let isSpeaking = viewModel.speakingId == phrase.id

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(phrase.koreanText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#313131"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(phrase.translatedText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#2563EB"))
                    .fixedSize(horizontal: false, vertical: true)

                Text("발음: \(phrase.pronunciation)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button { viewModel.toggleSpeak(phrase) } label: {
                ZStack {
                    Circle()
                        .fill(isSpeaking ? Color(hex: "#EF4444") : Color(hex: "#2563EB"))
                        .frame(width: 44, height: 44)
                    Text(isSpeaking ? "■" : "▶")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSpeaking ? "재생 중지" : "발음 듣기")
        }
        .padding(.leading, 32)
        .padding(.trailing, 30)
        .padding(.vertical, 13)
    }

    // MARK: - 로딩 / 빈 상태 / 에러

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("현지 표현을 불러오는 중이에요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#D1D5DB"))
            Text("등록된 표현이 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Text("안내사가 현지 표현을 등록하면\n여기에 표시됩니다")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 34))
                .foregroundColor(Color(hex: "#D1D5DB"))
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
                .multilineTextAlignment(.center)
            Button { viewModel.load() } label: {
                Text("다시 시도")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
