import SwiftUI

// MARK: - EmergencyView
/// 긴급 연락처 화면
///
/// 구성:
/// - 상단: 112 / 119 퀵 전화 버튼
/// - 담당자: 긴급 요청 전송 행
/// - 카테고리별 연락처 리스트 (긴급/의료/관광/개인)

struct EmergencyView: View {

    @ObservedObject var viewModel: EmergencyViewModel
    @Environment(\.openURL) private var openURL
    @State private var showEmergencyRequest = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 112 / 119 퀵버튼
                quickCallRow
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                // 담당자 긴급 요청 + 카테고리별 연락처
                contactList
                    .padding(.horizontal, 20)

                Spacer().frame(height: 40)
            }
        }
        .background(Color.white)
        .navigationTitle("긴급 연락")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showEmergencyRequest) {
            emergencyRequestSheet
        }
        .alert("긴급 요청 전송 완료", isPresented: $viewModel.emergencySentSuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("담당자에게 긴급 요청이 전송됐습니다. 잠시만 기다려주세요.")
        }
        .onAppear {
            viewModel.fetchContacts()
        }
    }

    // MARK: - 112 / 119 퀵버튼

    private var quickCallRow: some View {
        HStack(spacing: 12) {
            quickCallButton(number: "112", label: "경찰", color: .blue)
            quickCallButton(number: "119", label: "소방/ 구급", color: Color(red: 0.85, green: 0.25, blue: 0.22))
        }
    }

    private func quickCallButton(number: String, label: String, color: Color) -> some View {
        Button {
            if let url = viewModel.makeCallURL(phoneNumber: number) { openURL(url) }
        } label: {
            VStack(spacing: 6) {
                Text(number)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(color)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 연락처 리스트 카드

    private var contactList: some View {
        VStack(spacing: 0) {
            // 담당자에게 긴급 요청
            contactRow(
                title: "담당자에게 긴급 요청",
                subtitle: "도움 메시지를 여행사 담당자에게 전송합니다"
            ) {
                showEmergencyRequest = true
            }

            Divider()

            // 카테고리별 연락처
            ForEach(ContactCategory.allCases, id: \.self) { category in
                let items = viewModel.contactsByCategory(category)
                if !items.isEmpty {
                    // 섹션 헤더
                    HStack {
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HiTripColor.gray500)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                    ForEach(items) { contact in
                        Divider()
                        contactRow(title: contact.name, subtitle: nil) {
                            if let url = viewModel.makeCallURL(phoneNumber: contact.phoneNumber) {
                                openURL(url)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color(hex: "B4BCC9").opacity(0.30), radius: 6, x: 0, y: 2)
    }

    // MARK: - 연락처 행

    private func contactRow(title: String, subtitle: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(HiTripColor.textBlack)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray400)
                    }
                }

                Spacer()

                Image(systemName: "phone")
                    .font(.system(size: 18))
                    .foregroundColor(HiTripColor.textBlack)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 긴급 요청 시트

    private var emergencyRequestSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                    .padding(.top, 32)

                Text("긴급 요청 메시지")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)

                Text("담당자에게 전달할 내용을 입력하세요")
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray500)

                TextEditor(text: $viewModel.emergencyMessage)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(HiTripColor.gray200, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                Button {
                    viewModel.sendEmergencyRequest()
                    showEmergencyRequest = false
                } label: {
                    HStack {
                        if viewModel.isSendingEmergency {
                            ProgressView().tint(.white)
                        }
                        Text("긴급 요청 전송")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                }
                .disabled(viewModel.isSendingEmergency)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { showEmergencyRequest = false }
                }
            }
        }
    }
}
