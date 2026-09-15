import SwiftUI

// MARK: - iOS 16 호환
/// 최소 지원 버전이 iOS 16이라, iOS 17에서 생긴 API를 대신하는 수정자를 모아 둡니다.
/// iOS 17 이상에서는 원래 API와 똑같이 동작합니다.

extension View {

    /// `navigationDestination(item:)`(iOS 17) 대신 — 값이 생기면 그 값으로 화면을 엽니다
    ///
    /// 뒤로 가면 값이 nil로 돌아갑니다. iOS 16에서는 `isPresented`로 같은 동작을 만듭니다.
    func navigationDestination<Item, Destination: View>(
        unwrapping item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        navigationDestination(
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { if !$0 { item.wrappedValue = nil } }
            )
        ) {
            if let value = item.wrappedValue {
                destination(value)
            }
        }
    }

    /// 가로 카드 목록의 한 장씩 멈춤 + 보이는 카드 id 연결 (iOS 17 이상에서만)
    ///
    /// iOS 16에서는 일반 가로 스크롤로 동작하고 id는 연결되지 않습니다.
    @ViewBuilder
    func pagingScrollPosition<ID: Hashable>(id: Binding<ID?>) -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: id)
        } else {
            self
        }
    }

    /// 한 장씩 멈출 대상 레이아웃 표시 — `pagingScrollPosition`과 함께 씁니다 (iOS 17 이상에서만)
    @ViewBuilder
    func pagingScrollTargetLayout() -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTargetLayout()
        } else {
            self
        }
    }
}
