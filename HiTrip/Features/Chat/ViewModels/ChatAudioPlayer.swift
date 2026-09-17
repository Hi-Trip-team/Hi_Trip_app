import AVFoundation
import Foundation

// MARK: - ChatAudioPlayer
/// 채팅 음성 메시지 재생 — 여행객·안내사 채팅방이 같이 씁니다
///
/// 다운로드 주소는 로그인이 필요해 사진(RemoteImage)과 같은 규칙으로 인증을 붙여 받은 뒤
/// 임시 파일로 저장해 재생합니다. 한 번에 하나만 재생하고, 같은 음성을 다시 누르면 멈춥니다.

@MainActor
final class ChatAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {

    static let shared = ChatAudioPlayer()

    /// 재생 중인 첨부 id
    @Published private(set) var playingId: Int?
    /// 받는 중인 첨부 id
    @Published private(set) var loadingId: Int?

    private var player: AVAudioPlayer?
    /// 받은 파일 재사용 — 첨부 id → 임시 파일
    private var files: [Int: URL] = [:]

    func toggle(_ attachment: MessageAttachment) {
        if playingId == attachment.id { stop(); return }
        stop()

        if let file = files[attachment.id] { play(file, id: attachment.id); return }
        guard let url = RemoteImageCache.resolve(attachment.downloadUrl) else { return }

        loadingId = attachment.id
        Task {
            defer { if loadingId == attachment.id { loadingId = nil } }
            do {
                let file = try await Self.download(url, id: attachment.id)
                files[attachment.id] = file
                // 받는 사이에 다른 음성을 눌렀으면 재생하지 않습니다
                guard loadingId == attachment.id else { return }
                play(file, id: attachment.id)
            } catch {
                loadingId = nil
            }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        playingId = nil
    }

    private func play(_ file: URL, id: Int) {
        do {
            // 무음 모드에서도 들리게 재생 전용 세션으로
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: file)
            player.delegate = self
            player.play()
            self.player = player
            playingId = id
        } catch {
            playingId = nil
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.stop() }
    }

    /// 우리 API 서버로 가는 요청에만 인증을 붙입니다 (안내사는 세션 쿠키가 자동으로 붙음)
    private static func download(_ url: URL, id: Int) async throws -> URL {
        var request = URLRequest(url: url)
        if url.host == URL(string: APIEnvironment.current.baseURL)?.host,
           let token = KeychainManager.shared.getToken(),
           token != AuthRepository.staffSessionMarker {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("chat-audio-\(id).wav")
        try data.write(to: file, options: .atomic)
        return file
    }
}
