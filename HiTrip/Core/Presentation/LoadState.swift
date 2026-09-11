import Foundation

// MARK: - LoadState
/// 화면 데이터 로딩 상태 — ViewModel들이 공통으로 씁니다

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}
