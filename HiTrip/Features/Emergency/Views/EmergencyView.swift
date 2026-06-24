import SwiftUI

// MARK: - EmergencyView
/// 긴급 연락처 화면
///
/// 구성:
/// - 상단: 112 / 119 퀵 전화 버튼
/// - 담당자: 서버에서 받은 여행사 담당자 연락처
/// - 긴급 요청 전송: POST /api/traveler/emergency-requests/
/// - 카테고리별 연락처 리스트 (긴급/의료/관광/개인)

struct EmergencyView: View {

    @ObservedObject var viewModel: EmergencyViewModel
    @Environment(\.openURL) private var openURL
    @State private var showAddSheet = false
    @State private var showEmergencyRequest = false

    var body: some View {
        NavigationStack {
            List {
                // 112 / 119 퀵버튼
                quickCallSection

                // 담당자에게 긴급 요청 전송
                emergencyRequestSection

                // 카테고리별 연락처
                ForEach(ContactCategory.allCases, id: \.self) { category in
                    let categoryContacts = viewModel.contactsByCategory(category)
                    if !categoryContacts.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categoryContacts) { contact in
                                contactRow(contact)
                            }
                            .onDelete { indexSet in
                                deleteContacts(in: categoryContacts, at: indexSet)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("긴급 연락")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                EmergencyAddView(viewModel: viewModel)
            }
            .sheet(isPresented: $showEmergencyRequest) {
                emergencyRequestSheet
            }
            .onChange(of: showAddSheet) { isPresented in
                if !isPresented {
                    viewModel.fetchContacts()
                    viewModel.resetForm()
                }
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
    }

    // MARK: - 112 / 119 퀵버튼

    private var quickCallSection: some View {
        Section {
            HStack(spacing: 12) {
                quickCallButton(title: "경찰", number: "112", icon: "shield.fill", color: .blue)
                quickCallButton(title: "소방/구급", number: "119", icon: "flame.fill", color: .red)
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
    }

    private func quickCallButton(title: String, number: String, icon: String, color: Color) -> some View {
        Button {
            if let url = viewModel.makeCallURL(phoneNumber: number) { openURL(url) }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 28)).foregroundColor(.white)
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(number).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 긴급 요청 전송

    private var emergencyRequestSection: some View {
        Section {
            Button {
                showEmergencyRequest = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.orange)
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("담당자에게 긴급 요청")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HiTripColor.textBlack)
                        Text("도움 메시지를 여행사 담당자에게 전송합니다")
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray400)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray300)
                }
            }
            .buttonStyle(.plain)
        }
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
                    .background(HiTripColor.screenBackground)
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

    // MARK: - 연락처 행

    private func contactRow(_ contact: EmergencyContact) -> some View {
        Button {
            if let url = viewModel.makeCallURL(phoneNumber: contact.phoneNumber) { openURL(url) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: contact.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor(for: contact.category))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HiTripColor.textGrayA)
                    Text(contact.phoneNumber)
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray400)
                }

                Spacer()

                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(HiTripColor.primary800)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 헬퍼

    private func iconColor(for category: ContactCategory) -> Color {
        switch category {
        case .manager:   return HiTripColor.primary800
        case .emergency: return .red
        case .medical:   return .orange
        case .tourism:   return HiTripColor.primary800
        case .personal:  return .gray
        }
    }

    private func deleteContacts(in categoryContacts: [EmergencyContact], at indexSet: IndexSet) {
        for index in indexSet {
            let contact = categoryContacts[index]
            if !contact.isPreset { viewModel.deleteContact(id: contact.id) }
        }
    }
}
