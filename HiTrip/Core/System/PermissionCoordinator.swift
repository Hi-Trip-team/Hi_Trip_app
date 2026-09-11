import SwiftUI
import CoreLocation
import UserNotifications
import HealthKit

// MARK: - PermissionCoordinator
/// 약관 동의 후 OS 권한을 순서대로 요청하고, 위치 권한 상태를 앱 전체에 알립니다.
///
/// 순서: ① 위치(앱 사용 중 허용) ② 알림 ③ (관광객) 워치 헬스
/// - 거부해도 홈 진입은 막지 않습니다.
/// - 위치가 거부된 상태면 홈 상단에 "안전 서비스 제한 중" 배너를 띄웁니다.
/// - "한 번 허용"은 다음 실행 때 iOS가 상태를 notDetermined로 되돌리므로 홈에서 다시 요청합니다.

@MainActor
final class PermissionCoordinator: NSObject, ObservableObject {

    static let shared = PermissionCoordinator()

    @Published private(set) var locationStatus: CLAuthorizationStatus

    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()
    private var locationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    private override init() {
        locationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }

    /// 위치 권한이 없어 안전 서비스(이탈 감지·위치 공유)가 제한되는 상태
    var isLocationRestricted: Bool {
        locationStatus == .denied || locationStatus == .restricted
    }

    var isLocationUndetermined: Bool {
        locationStatus == .notDetermined
    }

    /// 설정 앱에서 돌아왔을 때 상태 갱신
    func refresh() {
        locationStatus = locationManager.authorizationStatus
    }

    // MARK: - 요청

    func requestLocation() async -> CLAuthorizationStatus {
        guard locationManager.authorizationStatus == .notDetermined else {
            refresh()
            return locationStatus
        }
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestNotification() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// 워치에서 측정한 심박·산소포화도를 읽습니다 (관광객 전용)
    func requestHealth() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let types: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.oxygenSaturation)
        ]
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
            return true
        } catch {
            print("⚠️ [Permission] 헬스 권한 요청 실패: \(error.localizedDescription)")
            return false
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionCoordinator: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationStatus = status
            // 생성 직후에도 notDetermined로 한 번 불리므로, 사용자가 고른 뒤에만 응답합니다.
            guard status != .notDetermined, let continuation = self.locationContinuation else { return }
            self.locationContinuation = nil
            continuation.resume(returning: status)
        }
    }
}
