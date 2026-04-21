import SwiftUI

// MARK: - ProfileEditView
/// 프로필 수정 화면 — 피그마 디자인
///
/// UI 구성:
/// - 네비바: 뒤로가기 + "프로필 수정" + 완료 버튼
/// - 아바타 + 이름 + "프로필 변경하기" 링크
/// - 폼: 닉네임, 생년월일, 거주 국가, 휴대번호
///
/// ProfileView에서 공유되는 ProfileViewModel을 받아서
/// 수정 폼 상태와 저장 로직을 ViewModel에 위임한다.

struct ProfileEditView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            HiTripColor.screenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 아바타 + 이름 + 프로필 변경하기
                    profileAvatarSection
                        .padding(.top, 24)

                    // 폼 영역
                    formSection
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("프로필 수정")
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
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    viewModel.saveProfile()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.primary800)
            }
        }
        .alert("저장 완료", isPresented: $viewModel.showSaveAlert) {
            Button("확인") { dismiss() }
        } message: {
            Text("프로필이 저장되었습니다.")
        }
    }

    // MARK: - Avatar Section

    private var profileAvatarSection: some View {
        VStack(spacing: 8) {
            // 아바타
            ZStack {
                Circle()
                    .fill(Color(hex: "FADADD").opacity(0.5))
                    .frame(width: 110, height: 110)

                Text("🙋‍♀️")
                    .font(.system(size: 56))
            }

            // 이름
            Text(viewModel.userName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
                .padding(.top, 4)

            // 프로필 변경하기 링크
            Button { } label: {
                Text("프로필 변경하기")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(HiTripColor.primary800)
            }
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 닉네임
            formField(
                label: "닉네임",
                placeholder: "15자 이내 영문, 숫자로 입력해주세요",
                text: $viewModel.editNickname
            )

            // 생년월일
            birthdayField

            // 거주 국가
            formField(
                label: "거주 국가",
                placeholder: "국가를 입력해주세요",
                text: $viewModel.editCountry
            )

            // 휴대번호
            phoneField
        }
    }

    // MARK: - Form Field (텍스트 입력)

    private func formField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(HiTripColor.gray100)
                .cornerRadius(12)
        }
    }

    // MARK: - Birthday Field

    private var birthdayField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("생년월일")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Button {
                viewModel.showBirthdayPicker.toggle()
            } label: {
                HStack {
                    Text(viewModel.isBirthdayDefault ? "생년월일을 선택해주세요" : viewModel.birthdayText)
                        .font(.system(size: 15))
                        .foregroundColor(
                            viewModel.isBirthdayDefault
                                ? HiTripColor.gray400
                                : HiTripColor.textBlack
                        )
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(HiTripColor.gray100)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            if viewModel.showBirthdayPicker {
                DatePicker(
                    "",
                    selection: $viewModel.editBirthday,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))
            }
        }
    }

    // MARK: - Phone Field

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("휴대번호")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            HStack(spacing: 8) {
                // 국가 코드
                Menu {
                    Button("+82 🇰🇷") { viewModel.editCountryCode = "+82" }
                    Button("+1 🇺🇸") { viewModel.editCountryCode = "+1" }
                    Button("+81 🇯🇵") { viewModel.editCountryCode = "+81" }
                    Button("+86 🇨🇳") { viewModel.editCountryCode = "+86" }
                    Button("+213 🇩🇿") { viewModel.editCountryCode = "+213" }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.editCountryCode)
                            .font(.system(size: 15))
                            .foregroundColor(HiTripColor.textBlack)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                            .foregroundColor(HiTripColor.gray400)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(HiTripColor.gray100)
                    .cornerRadius(12)
                }

                // 전화번호
                TextField("전화번호를 입력해주세요", text: $viewModel.editPhoneNumber)
                    .font(.system(size: 15))
                    .keyboardType(.phonePad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(HiTripColor.gray100)
                    .cornerRadius(12)
            }
        }
    }
}
