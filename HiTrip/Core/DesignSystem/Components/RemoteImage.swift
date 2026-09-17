import SwiftUI
import UIKit

// MARK: - RemoteImage
/// 서버 이미지 로더 — AsyncImage 대신 씁니다
///
/// AsyncImage로는 안 되는 두 가지를 처리합니다.
/// 1. 서버가 도메인 없는 경로(`/media/...`, `/api/v1/chat/attachments/1/download/`)를 주면
///    API 기본 주소를 붙여 완성합니다.
/// 2. 채팅 첨부처럼 로그인이 필요한 이미지에 REST와 같은 인증을 붙입니다
///    (관광객 Bearer 토큰, 안내사는 공유 쿠키 저장소의 세션 쿠키).
///
/// 불러온 이미지는 메모리에 캐시해 목록을 스크롤할 때 다시 받지 않습니다.
/// 내용 클로저는 AsyncImage와 같은 AsyncImagePhase를 받아 기존 화면을 그대로 옮길 수 있습니다.

struct RemoteImage<Content: View>: View {

    private let url: URL?
    private let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else {
            phase = .failure(URLError(.badURL))
            return
        }
        if let cached = RemoteImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }
        phase = .empty
        do {
            let image = try await RemoteImageCache.shared.fetch(url)
            phase = .success(Image(uiImage: image))
        } catch {
            phase = .failure(error)
        }
    }
}

// MARK: - RemoteImageCache

final class RemoteImageCache {

    static let shared = RemoteImageCache()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        return URLSession(configuration: config)
    }()

    private init() {
        cache.countLimit = 200
    }

    /// 서버 주소 완성 — 절대 주소는 그대로, `/`로 시작하면 API 기본 주소를 붙입니다
    static func resolve(_ raw: String?) -> URL? {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else { return nil }
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") { return URL(string: raw) }
        let base = APIEnvironment.current.baseURL
        return URL(string: raw.hasPrefix("/") ? base + raw : base + "/" + raw)
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func fetch(_ url: URL) async throws -> UIImage {
        var request = URLRequest(url: url)
        // 우리 API 서버로 가는 요청에만 인증을 붙입니다 (외부 이미지 주소로 토큰이 새지 않게)
        if url.host == URL(string: APIEnvironment.current.baseURL)?.host,
           let token = KeychainManager.shared.getToken(),
           token != AuthRepository.staffSessionMarker {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
