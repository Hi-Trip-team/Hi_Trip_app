import SwiftUI

// MARK: - ToastView
/// 짧은 알림 — 어두운 캡슐에 흰 글자

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(AppFont.labelMedium)
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(AppColor.textPrimary.opacity(0.92))
            .clipShape(Capsule())
    }
}

// MARK: - .toast(_:)

extension View {
    /// 메시지가 들어오면 토스트를 띄우고 2초 뒤 nil로 되돌립니다
    /// - Parameters:
    ///   - alignment: `.bottom`(기본) 또는 `.top`
    ///   - inset: 화면 끝에서 떨어진 거리
    func toast(_ message: Binding<String?>, alignment: Alignment = .bottom, inset: CGFloat = 40) -> some View {
        overlay(alignment: alignment) {
            if let text = message.wrappedValue {
                ToastView(message: text)
                    .padding(alignment == .top ? .top : .bottom, inset)
                    .transition(.opacity)
                    .task(id: text) {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        message.wrappedValue = nil
                    }
            }
        }
    }
}
