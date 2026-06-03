import Foundation
import RxSwift
import RxRelay

// MARK: - Single + HiTripError 편의 Operator
/// ViewModel에서 반복되는 에러 처리 패턴을 간결하게 작성할 수 있는 확장
///
/// Before (반복 코드):
/// ```swift
/// useCase.fetchTrips()
///     .observe(on: MainScheduler.instance)
///     .subscribe(
///         onSuccess: { trips in self.trips = trips },
///         onFailure: { error in
///             let htError = ErrorHandler.classify(error)
///             self.errorHandler.handle(error)
///             if htError.isRetryable { ... }
///         }
///     )
/// ```
///
/// After (간결):
/// ```swift
/// useCase.fetchTrips()
///     .withErrorHandling(errorHandler, context: "여행 목록 조회")
///     .subscribe(onSuccess: { trips in self.trips = trips })
/// ```

extension PrimitiveSequence where Trait == SingleTrait {

    // MARK: - 에러 핸들링 연결

    /// ErrorHandler와 연결하여 에러 자동 처리
    /// - Parameters:
    ///   - handler: 에러를 처리할 ErrorHandler
    ///   - context: 로그에 표시할 작업 이름 (예: "여행 목록 조회")
    /// - Returns: 에러 발생 시 ErrorHandler에 전달하고 에러를 전파하는 Single
    func withErrorHandling(
        _ handler: ErrorHandler,
        context: String? = nil
    ) -> Single<Element> {
        self.do(onError: { error in
            handler.handle(error, context: context)
        })
        .observe(on: MainScheduler.instance)
    }

    /// 에러 발생 시 ErrorHandler에 전달하되, fallback 값으로 대체
    /// - Parameters:
    ///   - handler: 에러를 처리할 ErrorHandler
    ///   - fallback: 에러 시 사용할 대체 값
    ///   - context: 로그에 표시할 작업 이름
    /// - Returns: 에러 발생 시 fallback 값을 방출하는 Single
    func withErrorFallback(
        _ handler: ErrorHandler,
        fallback: Element,
        context: String? = nil
    ) -> Single<Element> {
        self.do(onError: { error in
            handler.handle(error, context: context)
        })
        .catch { _ in .just(fallback) }
        .observe(on: MainScheduler.instance)
    }

    /// 에러 발생 시 조용히 로깅만 하고 fallback 값으로 대체
    /// - 사용자에게 Alert를 표시하지 않는 경우 (백그라운드 로딩 등)
    func withSilentFallback(
        _ handler: ErrorHandler,
        fallback: Element,
        context: String? = nil
    ) -> Single<Element> {
        self.do(onError: { error in
            handler.handleSilently(error, context: context)
        })
        .catch { _ in .just(fallback) }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - 자동 재시도

    /// 재시도 가능한 에러에 대해 자동 재시도 (지수 백오프)
    /// - Parameters:
    ///   - maxRetries: 최대 재시도 횟수 (기본 2)
    ///   - delay: 초기 지연 시간 (초, 기본 1.0 → 2회차 2.0 → 3회차 4.0)
    /// - Returns: 재시도 로직이 적용된 Single
    func retryOnNetworkError(
        maxRetries: Int = 2,
        delay: Double = 1.0
    ) -> Single<Element> {
        self.retry(when: { errors in
            errors.enumerated().flatMap { attempt, error -> Observable<Void> in
                // 최대 재시도 초과 시 에러 전파
                guard attempt < maxRetries else {
                    return .error(error)
                }

                // 재시도 가능한 에러만 재시도
                let htError = ErrorHandler.classify(error)
                guard htError.isRetryable else {
                    return .error(error)
                }

                // 지수 백오프: 1초 → 2초 → 4초
                let retryDelay = delay * pow(2.0, Double(attempt))
                print("🔄 [Retry] \(attempt + 1)/\(maxRetries) — \(retryDelay)초 후 재시도 | \(htError.debugDescription)")

                return Observable<Void>.just(())
                    .delay(.milliseconds(Int(retryDelay * 1000)), scheduler: MainScheduler.instance)
            }
        })
    }

    // MARK: - isLoading 바인딩

    /// 로딩 상태를 BehaviorRelay에 자동 바인딩
    /// - Parameter relay: true/false를 방출할 로딩 Relay
    /// - Returns: 구독 시작 시 true, 완료/에러 시 false를 방출하는 Single
    func trackLoading(_ relay: BehaviorRelay<Bool>) -> Single<Element> {
        self.do(
            onSubscribe: { relay.accept(true) },
            onDispose: { relay.accept(false) }
        )
    }
}

// MARK: - Observable + Error Handling

extension ObservableType {

    /// ErrorHandler와 연결하여 에러 자동 처리
    func withErrorHandling(
        _ handler: ErrorHandler,
        context: String? = nil
    ) -> Observable<Element> {
        self.do(onError: { error in
            handler.handle(error, context: context)
        })
        .observe(on: MainScheduler.instance)
    }
}

// MARK: - DisposeBag + 편의 구독

extension PrimitiveSequence where Trait == SingleTrait {

    /// ErrorHandler 연결 + 성공 핸들러만 작성하는 간편 구독
    ///
    /// 사용법:
    /// ```swift
    /// useCase.fetchTrips()
    ///     .handleAndSubscribe(
    ///         errorHandler: errorHandler,
    ///         disposeBag: disposeBag,
    ///         context: "여행 목록",
    ///         onSuccess: { [weak self] trips in
    ///             self?.trips.accept(trips)
    ///         }
    ///     )
    /// ```
    @discardableResult
    func handleAndSubscribe(
        errorHandler: ErrorHandler,
        disposeBag: DisposeBag,
        context: String? = nil,
        onSuccess: @escaping (Element) -> Void
    ) -> Disposable {
        let disposable = self
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: onSuccess,
                onFailure: { error in
                    errorHandler.handle(error, context: context)
                }
            )
        disposable.disposed(by: disposeBag)
        return disposable
    }
}
