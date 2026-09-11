import UIKit
import RxSwift

// MARK: - EmergencyCallViewModel
/// 긴급 통역 연결 — 운영시간 판단, 안내사 요청 전송, 전화 연결
///
/// 1) POST /api/v1/tourist/emergency-requests/ 로 담당 안내사에게 요청을 남기고
/// 2) OS 다이얼러로 넘깁니다 (인앱 통화가 아닙니다)
/// 요청 전송이 실패해도 전화는 겁니다 — 긴급 상황에서 발신이 막히면 안 됩니다.

@MainActor
final class EmergencyCallViewModel: ObservableObject {

    @Published private(set) var isSending = false

    let phoneNumber: String?
    let openHour: Int
    let closeHour: Int

    private let repository: TravelerRepositoryProtocol
    private let disposeBag = DisposeBag()

    init(
        phoneNumber: String?,
        openHour: Int = 9,
        closeHour: Int = 22,
        repository: TravelerRepositoryProtocol = AppDIContainer.shared.travelerRepositoryForHome
    ) {
        self.phoneNumber = phoneNumber
        self.openHour = openHour
        self.closeHour = closeHour
        self.repository = repository
    }

    // MARK: - 표시

    /// 운영시간 안이면 전화 안내, 밖이면 대체 동선을 보여줍니다
    var isWithinOperatingHours: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= openHour && hour < closeHour
    }

    var canCall: Bool {
        guard let phoneNumber else { return false }
        return !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var title: String {
        isWithinOperatingHours ? "긴급 통역 연결" : "지금은 연결이 어려워요"
    }

    var guideText: String {
        if !isWithinOperatingHours { return "통역 센터 운영시간이 아닙니다" }
        return canCall ? "통역사에게 바로 전화를 연결할까요?" : "연결할 수 있는 번호가 없습니다"
    }

    var operatingHoursText: String {
        "운영시간 " + String(format: "%02d:00 - %02d:00", openHour, closeHour) + " (현지 기준)"
    }

    // MARK: - 전화

    /// 안내사에게 요청을 남기고 전화 앱으로 넘깁니다. 끝나면 onFinish를 부릅니다.
    func call(onFinish: @escaping () -> Void) {
        guard let phoneNumber, !isSending else { return }
        isSending = true

        repository.sendEmergencyRequest(message: "긴급 통역을 요청했습니다", latitude: nil, longitude: nil, accuracyM: nil)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in self?.dial(phoneNumber, onFinish: onFinish) },
                onFailure: { [weak self] _ in self?.dial(phoneNumber, onFinish: onFinish) }
            )
            .disposed(by: disposeBag)
    }

    private func dial(_ number: String, onFinish: () -> Void) {
        isSending = false
        let digits = number.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        onFinish()
    }
}
