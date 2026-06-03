import Foundation

// MARK: - APIEnvironment
/// API 환경 설정
///
/// Mock ↔ Remote 전환을 중앙에서 관리.
/// 개발 중에는 .mock, 서버 연동 시 .remote로 전환.
///
/// 사용법:
/// - AppDIContainer에서 현재 environment를 참조하여
///   Mock 또는 Remote Repository를 주입
/// - NetworkService는 baseURL을 여기서 가져감

enum APIEnvironment {

    /// Mock 데이터 사용 (서버 없이 앱 개발)
    case mock

    /// 실제 백엔드 API 연동
    case remote

    // MARK: - 현재 환경 (여기서 전환)

    /// ⚠️ 서버 연동 시 .remote로 변경
    static let current: APIEnvironment = .remote

    // MARK: - Base URL

    /// API 서버 기본 URL
    var baseURL: String {
        switch self {
        case .mock:
            return "https://api.hitrip.example.com"
        case .remote:
            // TODO: 실제 배포 서버 URL로 변경
            return "http://100.124.191.47:18080"
        }
    }

    /// Mock 데이터 사용 여부
    var useMock: Bool {
        self == .mock
    }
}
