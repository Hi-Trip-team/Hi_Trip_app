import Foundation
import RxSwift

// MARK: - EmergencyViewModel
/// 긴급 연락처 화면의 ViewModel
///
/// 이전 ViewModel들과 동일한 @Published 패턴
/// 추가 기능: 카테고리별 그룹핑, 전화 걸기 URL 생성

final class EmergencyViewModel: ObservableObject {

    // MARK: - 목록 상태

    /// 전체 연락처 목록
    @Published var contacts: [EmergencyContact] = []

    // MARK: - 입력 폼 상태 (개인 연락처 추가용)

    /// 이름 입력
    @Published var name: String = ""

    /// 전화번호 입력
    @Published var phoneNumber: String = ""

    /// 카테고리 — 개인 연락처는 항상 .personal
    @Published var category: ContactCategory = .personal

    // MARK: - UI 상태

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isCompleted: Bool = false

    // MARK: - Dependencies

    private let emergencyUseCase: EmergencyUseCase
    private let disposeBag = DisposeBag()

    init(emergencyUseCase: EmergencyUseCase) {
        self.emergencyUseCase = emergencyUseCase
    }

    // MARK: - Read

    /// 전체 연락처 불러오기
    func fetchContacts() {
        isLoading = true

        emergencyUseCase.fetchAll()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] contacts in
                    self?.isLoading = false
                    self?.contacts = contacts
                },
                onFailure: { [weak self] error in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Create

    /// 개인 연락처 추가
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

    /// 개인 연락처 삭제
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

    /// 카테고리 순서대로 연락처를 그룹핑하여 반환
    /// Section 표시에 사용: "긴급", "의료", "관광", "개인"
    func contactsByCategory(_ category: ContactCategory) -> [EmergencyContact] {
        contacts.filter { $0.category == category }
    }

    /// 개인 연락처가 있는지 (섹션 표시 여부 판단용)
    var hasPersonalContacts: Bool {
        contacts.contains { $0.category == .personal }
    }

    // MARK: - 전화 걸기

    /// 전화번호로 tel:// URL 생성
    /// iOS에서 이 URL을 열면 전화 앱이 실행됨
    func makeCallURL(phoneNumber: String) -> URL? {
        let cleaned = phoneNumber.replacingOccurrences(of: "-", with: "")
        return URL(string: "tel://\(cleaned)")
    }

    // MARK: - 폼 헬퍼

    /// 폼 초기화
    func resetForm() {
        name = ""
        phoneNumber = ""
        isCompleted = false
        errorMessage = nil
    }

    /// 폼 유효성 (추가 버튼 활성화용)
    var isFormValid: Bool {
        !name.trimmed.isEmpty && !phoneNumber.trimmed.isEmpty
    }
}
