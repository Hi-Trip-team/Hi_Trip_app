import Foundation

// MARK: - NotificationCategory

enum NotificationCategory: String, CaseIterable, Identifiable {
    case all     = "전체"
    case danger  = "위험"
    case warning = "경고"
    case leave   = "이탈"
    case normal  = "알반"

    var id: String { rawValue }
}

// MARK: - NotificationItem

struct NotificationItem: Identifiable {
    let id: UUID
    let category: NotificationCategory
    let title: String
    let subtitle: String
    let time: String
    /// 위험 알림에만 표시되는 "확인" 버튼
    var requiresAction: Bool
    var isActioned: Bool

    init(
        id: UUID = UUID(),
        category: NotificationCategory,
        title: String,
        subtitle: String,
        time: String,
        requiresAction: Bool = false,
        isActioned: Bool = false
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.time = time
        self.requiresAction = requiresAction
        self.isActioned = isActioned
    }
}
