import Foundation
import RxSwift

// MARK: - EmergencyRepository
/// 긴급 연락처 저장소 구현체 (메모리 저장)
///
/// 이전 Repository들과 다른 점:
/// - 초기화 시 **프리셋 긴급번호**가 미리 등록되어 있음
/// - 프리셋(isPreset: true)은 삭제 불가
///
/// 프리셋 연락처:
/// - 경찰 (112), 소방/구급 (119)
/// - 응급의료정보센터 (1339)
/// - 관광불편신고 (1330), 외국인종합안내 (1345)

final class EmergencyRepository: EmergencyRepositoryProtocol {

    // MARK: - 저장소

    /// 긴급 연락처 배열 — 프리셋 + 개인 연락처
    private var contacts: [EmergencyContact]

    // MARK: - Init

    init() {
        // 프리셋 긴급번호 초기 등록
        self.contacts = Self.presetContacts
    }

    // MARK: - 프리셋 긴급번호

    /// 기본 제공 긴급 연락처 목록
    /// 여행 중 필요한 핵심 번호들
    private static let presetContacts: [EmergencyContact] = [
        // 긴급 기관
        EmergencyContact(
            name: "경찰",
            phoneNumber: "112",
            category: .emergency,
            isPreset: true,
            iconName: "shield.fill"
        ),
        EmergencyContact(
            name: "소방/구급",
            phoneNumber: "119",
            category: .emergency,
            isPreset: true,
            iconName: "flame.fill"
        ),

        // 의료
        EmergencyContact(
            name: "응급의료정보센터",
            phoneNumber: "1339",
            category: .medical,
            isPreset: true,
            iconName: "cross.fill"
        ),

        // 관광
        EmergencyContact(
            name: "관광불편신고",
            phoneNumber: "1330",
            category: .tourism,
            isPreset: true,
            iconName: "exclamationmark.bubble.fill"
        ),
        EmergencyContact(
            name: "외국인종합안내",
            phoneNumber: "1345",
            category: .tourism,
            isPreset: true,
            iconName: "globe"
        ),
    ]

    // MARK: - Read

    /// 전체 연락처 조회 — 카테고리 순서대로 반환
    func fetchAll() -> Single<[EmergencyContact]> {
        return Single.create { [weak self] single in
            let sorted = self?.contacts ?? []
            single(.success(sorted))
            return Disposables.create()
        }
    }

    // MARK: - Create

    /// 개인 연락처 추가
    func addContact(contact: EmergencyContact) -> Single<EmergencyContact> {
        return Single.create { [weak self] single in
            self?.contacts.append(contact)
            single(.success(contact))
            return Disposables.create()
        }
    }

    // MARK: - Update

    /// 개인 연락처 수정 — 프리셋은 수정 불가
    func updateContact(contact: EmergencyContact) -> Single<EmergencyContact> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(EmergencyError.notFound))
                return Disposables.create()
            }

            if let index = self.contacts.firstIndex(where: { $0.id == contact.id }) {
                // 프리셋은 수정 불가
                if self.contacts[index].isPreset {
                    single(.failure(EmergencyError.cannotDeletePreset))
                } else {
                    self.contacts[index] = contact
                    single(.success(contact))
                }
            } else {
                single(.failure(EmergencyError.notFound))
            }
            return Disposables.create()
        }
    }

    // MARK: - Delete

    /// 개인 연락처 삭제 — 프리셋은 삭제 불가
    func deleteContact(id: UUID) -> Single<Void> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(EmergencyError.notFound))
                return Disposables.create()
            }

            if let index = self.contacts.firstIndex(where: { $0.id == id }) {
                // 프리셋 삭제 방지
                if self.contacts[index].isPreset {
                    single(.failure(EmergencyError.cannotDeletePreset))
                } else {
                    self.contacts.remove(at: index)
                    single(.success(()))
                }
            } else {
                single(.failure(EmergencyError.notFound))
            }
            return Disposables.create()
        }
    }
}
