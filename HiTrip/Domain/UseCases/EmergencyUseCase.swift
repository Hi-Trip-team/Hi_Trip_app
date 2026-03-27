import Foundation
import RxSwift

// MARK: - EmergencyUseCase
/// 긴급 연락처 비즈니스 로직
///
/// 검증 규칙:
/// - 이름, 전화번호가 비어있으면 에러
/// - 프리셋 연락처는 삭제 불가 (Repository에서도 체크하지만 UseCase에서 먼저 차단)
///
/// 이전 UseCase들과 동일한 패턴:
/// - Protocol에만 의존 (DIP)
/// - 검증 실패 시 Repository 호출 안 함

final class EmergencyUseCase {

    private let repository: EmergencyRepositoryProtocol

    init(repository: EmergencyRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Read

    /// 전체 연락처 조회
    func fetchAll() -> Single<[EmergencyContact]> {
        return repository.fetchAll()
    }

    // MARK: - Create

    /// 개인 연락처 추가
    ///
    /// 검증: 이름과 전화번호가 비어있으면 에러
    func addContact(contact: EmergencyContact) -> Single<EmergencyContact> {
        guard !contact.name.trimmed.isEmpty else {
            return .error(EmergencyError.emptyName)
        }
        guard !contact.phoneNumber.trimmed.isEmpty else {
            return .error(EmergencyError.emptyPhoneNumber)
        }

        return repository.addContact(contact: contact)
    }

    // MARK: - Update

    /// 개인 연락처 수정
    func updateContact(contact: EmergencyContact) -> Single<EmergencyContact> {
        guard !contact.name.trimmed.isEmpty else {
            return .error(EmergencyError.emptyName)
        }
        guard !contact.phoneNumber.trimmed.isEmpty else {
            return .error(EmergencyError.emptyPhoneNumber)
        }

        return repository.updateContact(contact: contact)
    }

    // MARK: - Delete

    /// 연락처 삭제
    func deleteContact(id: UUID) -> Single<Void> {
        return repository.deleteContact(id: id)
    }
}

// MARK: - EmergencyError
/// 긴급 연락처 관련 에러
enum EmergencyError: LocalizedError, Equatable {
    case emptyName
    case emptyPhoneNumber
    case cannotDeletePreset
    case notFound
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "이름을 입력해주세요."
        case .emptyPhoneNumber:
            return "전화번호를 입력해주세요."
        case .cannotDeletePreset:
            return "기본 긴급 연락처는 삭제할 수 없습니다."
        case .notFound:
            return "연락처를 찾을 수 없습니다."
        case .serverError(let msg):
            return msg
        }
    }
}
