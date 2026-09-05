import SwiftUI

struct EmergencyView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var showCallDialog = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                Spacer()
                emergencyButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
            .background(Color.white)

            if showCallDialog {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { showCallDialog = false }
                callDialog
            }
        }
        .navigationBarHidden(true)
    }

    private var headerSection: some View {
        ZStack {
            Text("뉴진스 바다여행")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    private var emergencyButton: some View {
        Button { showCallDialog = true } label: {
            Text("긴급 즉시 연락")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#EF4444"))
                .frame(width: 149, height: 65)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#EF4444"), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 8)
    }

    private var callDialog: some View {
        VStack(spacing: 0) {
            Text("☎")
                .font(.system(size: 26))
                .foregroundColor(Color(hex: "#EF4444"))
                .padding(.top, 24)
                .padding(.bottom, 8)
            Text("긴급 통역 연결")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.bottom, 8)
            VStack(spacing: 4) {
                Text("통역사에게 바로 전화를 연결할까요?")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#333840"))
                Text("운영시간 09:00 - 22:00 (현지 기준)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#333840"))
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, 24)
            HStack(spacing: 10) {
                Button { showCallDialog = false } label: {
                    Text("취소")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#333840"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                Button { showCallDialog = false } label: {
                    Text("전화하기")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#EF4444"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 310)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
    }
}
