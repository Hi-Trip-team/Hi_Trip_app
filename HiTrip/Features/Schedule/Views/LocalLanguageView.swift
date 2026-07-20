import SwiftUI
import AVFoundation

// MARK: - LocalLanguageView
/// 현지 언어 쓰기 화면
///
/// 여행 목적지 언어로 된 필수 회화 문장과 발음 가이드를 제공.
/// 데이터: 서버 연동 전 Mock 데이터 사용

struct LocalLanguageView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechSynthesizer = SpeechSynthesizerService()

    // Mock 데이터 — 서버 연동 시 ViewModel + Repository로 교체
    private let phrases: [LocalPhrase] = LocalPhrase.mockData

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(phrases) { phrase in
                    phraseRow(phrase)
                    Divider()
                }
            }
            .background(Color.white)
        }
        .background(Color.white)
        .navigationTitle("현지 언어 쓰기")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
    }

    // MARK: - 문장 행

    private func phraseRow(_ phrase: LocalPhrase) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(phrase.korean)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)

                HStack(spacing: 4) {
                    Text("발음:")
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray500)
                    Text(phrase.pronunciation)
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray500)
                }
            }

            Spacer()

            // 스피커 버튼
            Button {
                speechSynthesizer.speak(phrase.local, language: phrase.languageCode)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(HiTripColor.primary800)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }
}

// MARK: - LocalPhrase Model

struct LocalPhrase: Identifiable {
    let id = UUID()
    let korean: String        // 한국어 표시 문장
    let local: String         // 현지 언어 문장 (TTS용)
    let pronunciation: String // 한글 발음 표기
    let languageCode: String  // BCP-47 언어 코드

    static let mockData: [LocalPhrase] = [
        LocalPhrase(korean: "안녕하세요. 커피 하나 부탁드려요.",
                    local: "こんにちは、コーヒーを一つお願いします。",
                    pronunciation: "곤니찌와, 코히 히토츠 오네가이시마스",
                    languageCode: "ja-JP"),
        LocalPhrase(korean: "안녕하세요. 메뉴판 부탁드립니다.",
                    local: "こんにちは、メニューをお願いします。",
                    pronunciation: "곤니찌와, 메-뉴오 오네가이시마스",
                    languageCode: "ja-JP"),
        LocalPhrase(korean: "계산 부탁드립니다.",
                    local: "お会計をお願いします。",
                    pronunciation: "오칸조오 오네가이시마스",
                    languageCode: "ja-JP"),
        LocalPhrase(korean: "이것은 얼마인가요?",
                    local: "これはいくらですか？",
                    pronunciation: "코레와 이쿠라데스카",
                    languageCode: "ja-JP"),
        LocalPhrase(korean: "화장실이 어디에 있나요?",
                    local: "トイレはどこですか？",
                    pronunciation: "토이레와 도코데스카",
                    languageCode: "ja-JP"),
        LocalPhrase(korean: "사진 찍어도 될까요?",
                    local: "写真を撮ってもいいですか？",
                    pronunciation: "샤신오 톳테모 이이데스카",
                    languageCode: "ja-JP"),
        LocalPhrase(korean: "영어를 할 수 있으신가요?",
                    local: "英語を話せますか？",
                    pronunciation: "에-고오 하나세마스카",
                    languageCode: "ja-JP"),
    ]
}

// MARK: - SpeechSynthesizerService

final class SpeechSynthesizerService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
}
