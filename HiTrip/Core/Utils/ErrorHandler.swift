import Foundation
import RxSwift
import RxRelay

// MARK: - ErrorHandler
/// ViewModel에서 공통으로 사용하는 에러 핸들링 유틸리티
///
/// 설계 의도:
/// - 모든 ViewModel이 동일한 방식으로 에러를 처리하도록 중앙화
/// - HiTripError → 사용자 Alert 메시지 자동 변환
/// - 재시도 가능 여부 판단 + 자동 재시도 지원
/// - 토큰 만료 시 로그인 화면 전환 트리거
///
/// 사용법:
/// ```swift
/// class TripViewModel {
///     let errorHandler = ErrorHandler()
///
///     func loadTrips() {
///         useCase.fetchTrips()
///             .subscribe(
///                 onSuccess: { [weak self] trips in ... },
///                 onFailure: { [weak self] error in
///                     self?.errorHandler.handle(error)
///                 }
///             )
///     }
/// }
/// ```
///
/// SwiftUI View에서:
/// ```swift
/// .alert(item: $viewModel.errorHandler.alertItem) { item in
///     Alert(title: Text(item.title), message: Text(item.message), ...)
/// }
/// ```

final class ErrorHandler: ObservableObject {

    // MARK: - Published (SwiftUI 바인딩용)

    /// 현재 표시할 에러 Alert 정보
    @Published var alertItem: AlertItem?

    /// 에러 발생 여부 (로딩 상태 전환 등에 활용)
    @Published var hasError: Bool = false

    // MARK: - RxSwift (MVVM 바인딩용)

    /// 에러 메시지를 방출하는 Relay (ViewModel → View 바인딩)
    let errorMessage = PublishRelay<String>()

    /// 에러 상세를 방출하는 Relay (디버깅/로깅용)
    let errorDetail = PublishRelay<HiTripError>()

    /// 재시도 트리거 Relay
    let retryTrigger = PublishRelay<Void>()

    // MARK: - Handle

    /// 에러를 처리하여 사용자 메시지로 변환
    ///
    /// 동작:
    /// 1. HiTripError로 변환 (아니면 래핑)
    /// 2. 토큰 만료면 Notification 발송 (로그인 화면 전환)
    /// 3. 사용자 메시지를 alertItem + errorMessage Relay로 방출
    /// 4. 재시도 가능 에러면 Alert에 재시도 버튼 포함
    func handle(_ error: Error, context: String? = nil) {
        let hiTripError = Self.classify(error)
        let message = hiTripError.localizedDescription

        // 콘솔 로깅
        if let context {
            print("⚠️ [ErrorHandler] \(context): \(hiTripError.debugDescription)")
        } else {
            print("⚠️ [ErrorHandler] \(hiTripError.debugDescription)")
        }

        // Rx Relay 방출
        errorMessage.accept(message)
        errorDetail.accept(hiTripError)

        // SwiftUI 바인딩
        hasError = true
        alertItem = AlertItem(
            title: Self.alertTitle(for: hiTripError),
            message: message,
            isRetryable: hiTripError.isRetryable
        )
    }

    /// 에러를 조용히 처리 (사용자에게 표시하지 않음, 로깅만)
    func handleSilently(_ error: Error, context: String? = nil) {
        let hiTripError = Self.classify(error)
        if let context {
            print("🔇 [ErrorHandler] \(context): \(hiTripError.debugDescription)")
        } else {
            print("🔇 [ErrorHandler] \(hiTripError.debugDescription)")
        }
        errorDetail.accept(hiTripError)
    }

    /// Alert 닫기
    func dismissAlert() {
        alertItem = nil
        hasError = false
    }

    // MARK: - Static Helpers

    /// 임의의 Error를 HiTripError로 분류
    static func classify(_ error: Error) -> HiTripError {
        // 이미 HiTripError인 경우
        if let htError = error as? HiTripError {
            return htError
        }

        // 기존 NetworkError인 경우 (마이그레이션)
        if let networkError = error as? NetworkError {
            return networkError.toHiTripError
        }

        // 기존 도메인 에러들은 그대로 전파
        // (LoginError, SignUpError 등은 LocalizedError이므로 메시지가 있음)

        // URLError인 경우
        if let urlError = error as? URLError {
            return HiTripError.from(urlError: urlError)
        }

        // 기타 — networkFailure로 래핑
        return .networkFailure(error.localizedDescription)
    }

    /// 에러 유형별 Alert 제목
    static func alertTitle(for error: HiTripError) -> String {
        switch error {
        case .noConnection, .timeout:
            return "연결 오류"
        case .unauthorized:
            return "인증 만료"
        case .forbidden:
            return "접근 제한"
        case .validationFailed:
            return "입력 오류"
        case .notFound:
            return "찾을 수 없음"
        case .rateLimited:
            return "요청 제한"
        case .serverError:
            return "서버 오류"
        default:
            return "오류"
        }
    }

    /// 재시도 가능 여부 확인
    static func isRetryable(_ error: Error) -> Bool {
        classify(error).isRetryable
    }

    /// 토큰 만료 에러인지 확인
    static func requiresReauth(_ error: Error) -> Bool {
        classify(error).requiresReauth
    }
}

// MARK: - AlertItem
/// Alert 표시에 필요한 정보를 담는 모델

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isRetryable: Bool

    init(title: String = "오류", message: String, isRetryable: Bool = false) {
        self.title = title
        self.message = message
        self.isRetryable = isRetryable
    }
}
