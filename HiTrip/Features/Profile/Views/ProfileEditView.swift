import SwiftUI

// MARK: - ProfileEditView
/// 내 정보 화면 (읽기 전용)
///
/// GET /api/traveler/me/ 데이터를 표시
/// 여행객 정보: 이름, 전화번호, 이메일, 생년월일, 성별
/// 결제/서류: 결제 상태, 여권 확인, 예약 확인

struct ProfileEditView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    profileAvatarSection
                        .padding(.top, 24)

                    personalInfoSection
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    statusSection
                        .padding(.top, 16)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("내 정보")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 4, y: 2)
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var profileAvatarSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FADADD").opacity(0.14))
                    .frame(width: 110, height: 110)
                Text("🙋‍♀️")
                    .font(.system(size: 56))
            }

            Text(viewModel.userName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
                .padding(.top, 4)

            Text("여행객")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(HiTripColor.primary800)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(HiTripColor.primary800.opacity(0.14))
                .cornerRadius(8)
        }
    }

    // MARK: - Personal Info Section

    private var personalInfoSection: some View {
        VStack(spacing: 0) {
            sectionHeader("개인 정보")

            infoRow(icon: "person.fill", label: "이름", value: viewModel.userName)
            divider
            if !viewModel.userPhone.isEmpty {
                infoRow(icon: "phone.fill", label: "전화번호", value: viewModel.userPhone)
                divider
            }
            if !viewModel.userEmail.isEmpty {
                infoRow(icon: "envelope.fill", label: "이메일", value: viewModel.userEmail)
                divider
            }
            if !viewModel.birthDateDisplayText.isEmpty {
                infoRow(icon: "calendar", label: "생년월일", value: viewModel.birthDateDisplayText)
                divider
            }
            if !viewModel.userGender.isEmpty {
                infoRow(icon: "person.2.fill", label: "성별", value: viewModel.userGender)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 6, y: 2)
    }

    // MARK: - Status Section (결제/서류)

    private var statusSection: some View {
        VStack(spacing: 0) {
            sectionHeader("결제 / 서류 상태")

            if !viewModel.paymentSummaryText.isEmpty {
                infoRow(icon: "creditcard.fill", label: "결제", value: viewModel.paymentSummaryText)
                divider
            }
            if !viewModel.paymentStatusDisplay.isEmpty {
                infoRow(icon: "wonsign.circle.fill", label: "결제 상태", value: viewModel.paymentStatusDisplay)
                divider
            }
            statusRow(icon: "doc.text.fill", label: "여권 확인", isVerified: viewModel.passportVerified)
            divider
            statusRow(icon: "checkmark.seal.fill", label: "예약 확인", isVerified: viewModel.bookingVerified)
            if !viewModel.docStatusDisplay.isEmpty {
                divider
                infoRow(icon: "folder.fill", label: "서류 상태", value: viewModel.docStatusDisplay)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 6, y: 2)
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HiTripColor.gray500)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(HiTripColor.gray100.opacity(0.14))
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(HiTripColor.primary800)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)
                Text(value.isEmpty ? "-" : value)
                    .font(.system(size: 16))
                    .foregroundColor(HiTripColor.textBlack)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func statusRow(icon: String, label: String, isVerified: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(HiTripColor.primary800)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(HiTripColor.gray400)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: isVerified ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isVerified ? .green : .red.opacity(0.14))
                Text(isVerified ? "확인됨" : "미확인")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isVerified ? .green : .red.opacity(0.14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Divider().padding(.leading, 62)
    }
}
