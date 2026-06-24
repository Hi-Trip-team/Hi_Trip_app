import Foundation
import Combine
import RxSwift

// MARK: - EmergencyViewModel
/// 긴급 연락처 화면의 ViewModel
///
/// 데이터 구성:
/// 1. 담당자: 서버에서 제공 (TripDataStore.managerContact)
/// 2. 프리셋: 로컬 (112, 119, 1339 등)
/// 3. 개인: 사용자가 추가한 연락처 (로컬)
/// 긴급 요청 전송: POST /api/traveler/emergency-requests/

final class EmergencyViewModel: ObservableObject {

    // MARK: - 목록 상태

    @Published var contacts: [EmergencyContact] = []

    // MARK: - 긴급 요청 상태

    @Published var emergencyMessage: String = ""
    @Published var isSendingEmergency: Bool = false
    @Published var emergencySentSuccess: Bool = false

    // MARK: - 입력 폼 상태 (개인 연락처 추가용)

    @Published var name: String = ""
    @Published var phoneNumber: String = ""
    @Published var category: ContactCategory = .personal

    // MARK: - UI 상태

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isCompleted: Bool = false

    // MARK: - Dependencies

    private let emergencyUseCase: EmergencyUseCase
    private let travelerRepository: TravelerRepositoryProtocol
    private let store = TripDataStore.shared
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(
        emergencyUseCase: EmergencyUseCase,
        travelerRepository: TravelerRepositoryProtocol = TravelerRepository()
    ) {
        self.emergencyUseCase = emergencyUseCase
        self.travelerRepository = travelerRepository

        // 서버 매니저 연락처 변경 감지
        store.$managerContact
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.mergeContacts()
            }
            .store(in: &cancellables)
    }

    // MARK: - Read

    func fetchContacts() {
        isLoading = true
        emergencyUseCase.fetchAll()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] localContacts in
                    self?.isLoading = false
                    self?.mergeContacts(local: localContacts)
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    /// 로컬 프리셋/개인 + 서버 담당자 연락처를 병합
    private func mergeContacts(local: [EmergencyContact]? = nil) {
        let localList = local ?? contacts.filter { $0.category != .manager }

        var merged: [EmergencyContact] = []

        // 1. 서버 담당자 연락처 (앞에 배치)
        if let mc = store.managerContact {
            let managerName = mc["name"] ?? mc["manager_name"] ?? "여행 담당자"
            let managerPhone = mc["phone"] ?? mc["contact"] ?? mc["phone_number"] ?? ""
            if !managerPhone.isEmpty {
                merged.append(EmergencyContact(
                    name: managerName,
                    phoneNumber: managerPhone,
                    category: .manager,
                    isPreset: true,
                    iconName: "person.badge.shield.checkmark.fill"
                ))
            }
        }

        // 2. 로컬 프리셋 + 개인 연락처
        merged.append(contentsOf: localList)
        contacts = merged
    }

    // MARK: - 긴급 요청 전송 (서버)

    func sendEmergencyRequest(latitude: String? = nil, longitude: String? = nil) {
        let msg = emergencyMessage.trimmed.isEmpty ? "도움이 필요합니다." : emergencyMessage.trimmed
        isSendingEmergency = true

        travelerRepository.sendEmergencyRequest(
            message: msg,
            latitude: latitude,
            longitude: longitude,
            accuracyM: nil
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] _ in
                self?.isSendingEmergency = false
                self?.emergencySentSuccess = true
                self?.emergencyMessage = ""
                print("✅ [Emergency] 긴급 요청 전송 완료")
            },
            onFailure: { [weak self] error in
                self?.isSendingEmergency = false
                self?.errorMessage = "긴급 요청 전송에 실패했습니다. 직접 연락해주세요."
                print("⚠️ [Emergency] 긴급 요청 전송 실패: \(error.localizedDescription)")
            }
        )
        .disposed(by: disposeBag)
    }

    // MARK: - Create (개인 연락처 추가)

    func addContact() {
        let newContact = EmergencyContact(
            name: name.trimmed,
            phoneNumber: phoneNumber.trimmed,
            category: .personal,
            isPreset: false,
            iconName: "person.fill"
        )
        isLoading = true
        errorMessage = nil

        emergencyUseCase.addContact(contact: newContact)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    self?.isCompleted = true
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Delete

    func deleteContact(id: UUID) {
        isLoading = true
        errorMessage = nil

        emergencyUseCase.deleteContact(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.isLoading = false
                    self?.contacts.removeAll { $0.id == id }
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - 카테고리별 그룹핑

    func contactsByCategory(_ category: ContactCategory) -> [EmergencyContact] {
        contacts.filter { $0.category == category }
    }

    var hasPersonalContacts: Bool {
        contacts.contains { $0.category == .personal }
    }

    // MARK: - 전화 걸기

    func makeCallURL(phoneNumber: String) -> URL? {
        let cleaned = phoneNumber.replacingOccurrences(of: "-", with: "")
        return URL(string: "tel://\(cleaned)")
    }

    // MARK: - 폼 헬퍼

    func resetForm() {
        name = ""
        phoneNumber = ""
        isCompleted = false
        errorMessage = nil
    }

    var isFormValid: Bool {
        !name.trimmed.isEmpty && !phoneNumber.trimmed.isEmpty
    }
}
