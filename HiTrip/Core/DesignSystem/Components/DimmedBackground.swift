import SwiftUI

// MARK: - DimmedBackground
/// 팝업·시트 뒤의 어두운 배경. 탭하면 onTap을 실행합니다(없으면 탭 무시).

struct DimmedBackground: View {
    var opacity: Double = 0.45
    var onTap: (() -> Void)? = nil

    var body: some View {
        Color.black.opacity(opacity)
            .ignoresSafeArea()
            .onTapGesture { onTap?() }
    }
}
