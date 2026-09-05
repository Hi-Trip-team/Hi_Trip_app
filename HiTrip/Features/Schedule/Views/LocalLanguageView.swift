import SwiftUI
import AVFoundation

struct LocalLanguageView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var playingIndex: Int? = nil

    private let phrases: [LanguagePhrase] = [
        LanguagePhrase(korean: "안녕하세요. 커피 하나 부탁드려요.",
                       local: "こんにちは。コーヒーを一つお願いします。",
                       pronunciation: "발음: 곤니찌와, 코히 히토츠 오네가이시마스"),
        LanguagePhrase(korean: "메뉴판 부탁드립니다.",
                       local: "メニューをお願いします。",
                       pronunciation: "발음: 메뉴-오 오네가이시마스"),
        LanguagePhrase(korean: "계산 부탁드립니다.",
                       local: "お会計をお願いします。",
                       pronunciation: "발음: 오카이케-오 오네가이시마스"),
        LanguagePhrase(korean: "화장실이 어디인가요?",
                       local: "トイレはどこですか？",
                       pronunciation: "발음: 토이레와 도코데스카"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            // 언어 선택 칩
            HStack {
                Spacer()
                Text("🇯🇵 일본어")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#333840"))
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Color(hex: "#F3F4F6"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(phrases.enumerated()), id: \.offset) { idx, phrase in
                        phraseRow(phrase: phrase, index: idx)
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("현지 언어 쓰기")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
            HStack {
                Button { dismiss() } label: {
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
        .padding(.bottom, 8)
    }

    // MARK: - 문구 행

    private func phraseRow(phrase: LanguagePhrase, index: Int) -> some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(phrase.korean)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#313131"))
                Text(phrase.local)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#2563EB"))
                Text(phrase.pronunciation)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .padding(.leading, 20)
            .padding(.vertical, 18)

            Spacer()

            Button {
                if playingIndex == index {
                    playingIndex = nil
                } else {
                    playingIndex = index
                    speakPhrase(phrase.local)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(playingIndex == index ? Color(hex: "#EF4444") : Color(hex: "#2563EB"))
                        .frame(width: 44, height: 44)
                    Text(playingIndex == index ? "■" : "▶")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
        }
    }

    private func speakPhrase(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if playingIndex != nil { playingIndex = nil }
        }
    }
}

private struct LanguagePhrase {
    let korean: String
    let local: String
    let pronunciation: String
}
