import SwiftUI

// MARK: - EmergencyCallDialog
/// 긴급 통역 연결 — 홈의 "긴급 즉시 연락" 버튼으로 뜨는 팝업
///
/// 별도 화면이 아니라 홈 위에 겹쳐 띄웁니다.
/// 전화번호는 홈 응답의 manager_contact에서 받아 tel: 링크로 겁니다.

struct EmergencyCallDialog: View {

    @Binding var isPresented: Bool

    /// 연결할 전화번호. 없으면 "전화하기"를 누를 수 없습니다.
    var phoneNumber: String?
    var operatingHours: String = "09:00 - 22:00"

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            dialogCard
        }
    }

    private var dialogCard: some View {
        VStack(spacing: 0) {
            Text("☎")
                .font(.system(size: 26))
                .foregroundColor(Color(hex: "#EF4444"))
                .padding(.top, 24)

            Text("긴급 통역 연결")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.top, 16)

            VStack(spacing: 2) {
                Text(canCall
                     ? "통역사에게 바로 전화를 연결할까요?"
                     : "연결할 수 있는 번호가 없습니다")
                Text("운영시간 \(operatingHours) (현지 기준)")
            }
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "#333840"))
            .multilineTextAlignment(.center)
            .padding(.top, 14)

            HStack(spacing: 10) {
                Button { isPresented = false } label: {
                    Text("취소")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#333840"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button { call() } label: {
                    Text("전화하기")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canCall ? Color(hex: "#EF4444") : Color(hex: "#C3CDDA"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!canCall)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 22)
        }
        .frame(width: 310)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var canCall: Bool {
        guard let phoneNumber else { return false }
        return !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 전화 앱으로 넘깁니다. 시뮬레이터에는 전화 앱이 없어 동작하지 않습니다.
    private func call() {
        guard let phoneNumber else { return }
        let digits = phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) else {
            isPresented = false
            return
        }
        UIApplication.shared.open(url)
        isPresented = false
    }
}
