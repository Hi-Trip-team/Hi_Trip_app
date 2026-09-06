import Foundation
import AVFoundation

// MARK: - VoiceRecorder
/// 꾹 눌러 녹음 — 떼면 파일을 돌려줍니다.
///
/// 서버 제한과 동일하게 최대 3분에서 스스로 멈춥니다.
/// 마이크 권한이 없으면 시작하지 않고 이유를 알려줍니다.

@MainActor
final class VoiceRecorder: NSObject, ObservableObject {

    enum StartResult {
        case started
        case permissionDenied
        case failed
    }

    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0

    /// 서버 duration 상한과 같습니다
    let maxDuration: TimeInterval = 180

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var fileURL: URL?

    /// 권한을 확인하고 녹음을 시작합니다.
    func start() async -> StartResult {
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
        }
        guard granted else { return .permissionDenied }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.record(forDuration: maxDuration)

            self.recorder = recorder
            self.fileURL = url
            self.isRecording = true
            self.elapsed = 0
            startTimer()
            return .started
        } catch {
            return .failed
        }
    }

    /// 녹음을 멈추고 (파일, 길이)를 돌려줍니다. 너무 짧으면 nil입니다.
    func stop() -> (data: Data, duration: Int)? {
        defer { cleanUp() }

        guard let recorder, let fileURL else { return nil }
        let duration = Int(recorder.currentTime.rounded())
        recorder.stop()

        // 손이 스친 정도(1초 미만)는 보내지 않습니다
        guard duration >= 1, let data = try? Data(contentsOf: fileURL) else { return nil }
        return (data, min(duration, Int(maxDuration)))
    }

    func cancel() {
        recorder?.stop()
        cleanUp()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let recorder = self.recorder else { return }
                self.elapsed = recorder.currentTime
            }
        }
    }

    private func cleanUp() {
        timer?.invalidate()
        timer = nil
        recorder = nil
        fileURL = nil
        isRecording = false
        elapsed = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
