import Foundation
import RxSwift

// MARK: - EmergencyRepositoryProtocol
/// 긴급 연락처 데이터 접근 인터페이스 (Domain 레이어)
///
/// Schedule, Chat과 동일한 DIP 패턴
/// - 프리셋 연락처(112, 119 등) + 개인 연락처를 함께 관리
/// - 추후 서버 연동 시 구현체만 교체

protocol EmergencyRepositoryProtocol {

    /// 전체 연락처 조회 — 프리셋 + 개인 연락처 모두 포함
    func fetchAll() -> Single<[EmergencyContact]>

    /// 개인 연락처 추가
    func addContact(contact: EmergencyContact) -> Single<EmergencyContact>

    /// 개인 연락처 수정
    func updateContact(contact: EmergencyContact) -> Single<EmergencyContact>

    /// 개인 연락처 삭제 — 프리셋은 삭제 불가
    func deleteContact(id: UUID) -> Single<Void>
}
