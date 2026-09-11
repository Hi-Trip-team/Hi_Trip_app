import SwiftUI

// MARK: - NavigationHeader
/// 화면 상단 헤더 — 가운데 제목 + 왼쪽 뒤로가기 + (선택) 오른쪽 버튼
///
/// - `.compact`: 높이 24 — 안내사 화면 Figma
/// - `.regular`: 높이 44 — 관광객 화면 Figma
///
/// ```swift
/// NavigationHeader(title: "알림", style: .compact) { dismiss() }
/// NavigationHeader(title: "메시지 및 문의", onBack: { dismiss() }) {
///     HeaderTextButton("모두 확인") { viewModel.markAllAsRead() }
/// }
/// ```

struct NavigationHeader<Trailing: View>: View {

    enum Style {
        case compact, regular

        var height: CGFloat {
            switch self {
            case .compact: return 24
            case .regular: return 44
            }
        }
    }

    let title: String
    var style: Style = .regular
    var horizontalInset: CGFloat = AppSpacing.sm
    let onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            Text(title)
                .font(AppFont.headlineBold)
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(AppFont.title3Medium)
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("뒤로")

                Spacer()
                trailing()
            }
            .padding(.horizontal, horizontalInset)
        }
        .frame(height: style.height)
        .padding(.top, AppSpacing.xs)
    }
}

extension NavigationHeader where Trailing == EmptyView {
    init(title: String, style: Style = .regular, horizontalInset: CGFloat = AppSpacing.sm, onBack: @escaping () -> Void) {
        self.init(title: title, style: style, horizontalInset: horizontalInset, onBack: onBack) { EmptyView() }
    }
}

// MARK: - HeaderTextButton
/// 헤더 오른쪽 글자 버튼 (예: 「모두 확인」)

struct HeaderTextButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.labelMedium)
                .foregroundColor(AppColor.accent)
        }
        .buttonStyle(.plain)
    }
}
