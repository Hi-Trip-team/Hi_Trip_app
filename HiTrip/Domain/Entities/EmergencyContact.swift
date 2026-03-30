import Foundation

// MARK: - EmergencyContact
/// 긴급 연락처 데이터 모델
///
/// 두 가지 종류의 연락처를 하나의 모델로 관리:
/// 1. 프리셋 (preset): 112, 119, 관광불편신고 등 기본 제공 번호
/// 2. 개인 (personal): 사용자가 직접 추가한 보호자/동행자 연락처
///
/// 필드 설계 기준:
/// - id: 고유 식별자 (UUID)
/// - name: 연락처 이름 (예: "경찰", "엄마")
/// - phoneNumber: 전화번호 (예: "112", "010-1234-5678")
/// - category: 분류 (긴급기관/의료/관광/개인)
/// - isPreset: 기본 제공 여부 (true면 삭제 불가)
/// - iconName: SF Symbol 아이콘 이름

struct EmergencyContact: Identifiable, Codable, Equatable {

    /// 고유 식별자
    let id: UUID

    /// 연락처 이름
    /// 예: "경찰 (112)", "엄마", "관광불편신고"
    var name: String

    /// 전화번호
    /// 예: "112", "010-1234-5678", "1330"
    var phoneNumber: String

    /// 분류 카테고리
    var category: ContactCategory

    /// 기본 제공 연락처 여부
    /// true: 삭제 불가 (112, 119 등)
    /// false: 사용자가 추가한 연락처 (삭제 가능)
    let isPreset: Bool

    /// SF Symbol 아이콘 이름
    /// 예: "shield.fill", "cross.fill", "phone.fill"
    var iconName: String

    /// 기본 생성자
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        category: ContactCategory,
        isPreset: Bool = false,
        iconName: String = "phone.fill"
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.category = category
        self.isPreset = isPreset
        self.iconName = iconName
    }
}

// MARK: - ContactCategory
/// 긴급 연락처 분류
///
/// 화면에서 섹션별로 그룹핑하기 위한 카테고리
enum ContactCategory: String, Codable, CaseIterable, Equatable {
    /// 긴급 기관 (경찰, 소방)
    case emergency = "긴급"
    /// 의료 기관 (응급의료정보센터)
    case medical = "의료"
    /// 관광 관련 (관광불편신고, 외국인종합안내)
    case tourism = "관광"
    /// 개인 연락처 (보호자, 동행자)
    case personal = "개인"
}
