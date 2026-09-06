import Foundation
import AVFoundation
import RxSwift

// MARK: - LocalLanguageViewModel
/// 현지 언어 쓰기 — GET /api/v1/tourist/local-phrases/
///
/// 서버는 audio_url · tts_text 도 함께 주지만 쓰지 않습니다.
/// 발음은 기기 음성 합성(AVSpeechSynthesizer)으로 출력하고,
/// 어떤 언어로 읽을지는 응답의 language_code로 정합니다.

@MainActor
final class LocalLanguageViewModel: NSObject, ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var data: TravelerLocalPhrasesDTO?
    /// 지금 읽고 있는 표현 id — 버튼 모양(▶/■) 전환에 사용
    @Published private(set) var speakingId: Int?

    /// 재생 실패 안내 — "재생할 수 없어요"
    @Published var toast: String?

    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()
    private let synthesizer = AVSpeechSynthesizer()

    init(repository: TravelerRepositoryProtocol = AppDIContainer.shared.travelerRepositoryForHome) {
        self.repository = repository
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Load

    func load() {
        guard state != .loading else { return }
        state = .loading

        repository.fetchLocalPhrases()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] dto in
                    self?.data = dto
                    self?.state = .loaded
                },
                onFailure: { [weak self] error in
                    self?.state = .failed(Self.message(for: error))
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 표시용

    /// display_order 기준 정렬
    var phrases: [LocalPhraseDTO] {
        (data?.phrases ?? []).sorted { $0.displayOrder < $1.displayOrder }
    }

    /// "🇯🇵 일본어" — 국기는 언어 코드로 정합니다.
    var languageChipText: String {
        guard let d = data else { return "" }
        let flag = Self.flag(for: d.languageCode)
        return flag.isEmpty ? d.languageName : "\(flag) \(d.languageName)"
    }

    var hasPhrases: Bool { !phrases.isEmpty }

    // MARK: - 음성 출력

    func toggleSpeak(_ phrase: LocalPhraseDTO) {
        if speakingId == phrase.id {
            stop()
            return
        }
        speak(phrase)
    }

    private func speak(_ phrase: LocalPhraseDTO) {
        // 읽을 문장이 없거나 해당 언어 음성이 기기에 없으면 소리 없이 끝나므로,
        // 시도하기 전에 걸러서 안내합니다.
        let text = phrase.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let voice = Self.voice(for: data?.languageCode) else {
            speakingId = nil
            toast = "재생할 수 없어요"
            return
        }

        configureAudioSession()
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.45

        speakingId = phrase.id
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speakingId = nil
        deactivateAudioSession()
    }

    /// 재생이 끝나면 세션을 놓아 다른 앱 오디오가 원래대로 돌아오게 합니다.
    fileprivate func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private

    /// 무음 스위치가 켜져 있어도 발음이 들리도록 재생 카테고리를 지정합니다.
    /// 지정하지 않으면 기기에서 소리가 안 나거나 다른 앱 오디오를 끊습니다.
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // 세션 설정에 실패해도 음성 합성 자체는 시도합니다.
        }
    }

    /// 언어 코드에 맞는 음성. 없으면 시스템 기본값으로 둡니다.
    private static func voice(for code: String?) -> AVSpeechSynthesisVoice? {
        guard let code, !code.isEmpty else { return nil }
        // "ja" → "ja-JP" 처럼 지역까지 붙은 식별자가 필요합니다.
        if let exact = AVSpeechSynthesisVoice(language: code) { return exact }
        let match = AVSpeechSynthesisVoice.speechVoices()
            .first { $0.language.lowercased().hasPrefix(code.lowercased()) }
        return match.flatMap { AVSpeechSynthesisVoice(language: $0.language) }
    }

    private static func flag(for code: String) -> String {
        switch code.lowercased().prefix(2) {
        case "ja": return "🇯🇵"
        case "en": return "🇺🇸"
        case "zh": return "🇨🇳"
        case "ko": return "🇰🇷"
        case "es": return "🇪🇸"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "th": return "🇹🇭"
        case "vi": return "🇻🇳"
        case "it": return "🇮🇹"
        default:   return ""
        }
    }

    private static func message(for error: Error) -> String {
        if let e = error as? HiTripError {
            switch e {
            case .unauthorized, .forbidden: return "로그인이 필요합니다"
            case .noConnection:             return "네트워크에 연결되어 있지 않습니다"
            case .timeout:                  return "서버 응답이 없습니다"
            default:                        break
            }
        }
        return "현지 표현을 불러오지 못했습니다"
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension LocalLanguageViewModel: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.speakingId = nil
            self.deactivateAudioSession()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speakingId = nil }
    }
}
