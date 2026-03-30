import SwiftUI

// MARK: - EmergencyView
/// 긴급 연락처 화면
///
/// 구성:
/// - 상단: 긴급 전화 퀵버튼 (112, 119 원탭 호출)
/// - 중간: 카테고리별 연락처 리스트 (긴급/의료/관광/개인)
/// - 개인 연락처 추가/삭제 가능
///
/// 새로운 패턴:
/// - openURL: 전화 걸기 (tel://) 용
/// - Section + ForEach with category: enum 기반 그룹핑

struct EmergencyView: View {

    @ObservedObject var viewModel: EmergencyViewModel
    @Environment(\.openURL) private var openURL
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 긴급 전화 퀵버튼
                quickCallSection

                // MARK: - 카테고리별 연락처
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
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                EmergencyAddView(viewModel: viewModel)
            }
            .onChange(of: showAddSheet) { isPresented in
                if !isPresented {
                    viewModel.fetchContacts()
                    viewModel.resetForm()
                }
            }
            .onAppear {
                viewModel.fetchContacts()
            }
        }
    }

    // MARK: - 긴급 전화 퀵버튼

    /// 112, 119 원탭 전화 버튼
    /// 화면 최상단에 크게 배치하여 긴급 상황에서 빠르게 접근
    private var quickCallSection: some View {
        Section {
            HStack(spacing: 12) {
                quickCallButton(
                    title: "경찰",
                    number: "112",
                    icon: "shield.fill",
                    color: .blue
                )

                quickCallButton(
                    title: "소방/구급",
                    number: "119",
                    icon: "flame.fill",
                    color: .red
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
    }

    /// 퀵 전화 버튼 개별 UI
    private func quickCallButton(
        title: String,
        number: String,
        icon: String,
        color: Color
    ) -> some View {
        Button {
            if let url = viewModel.makeCallURL(phoneNumber: number) {
                openURL(url)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(number)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 연락처 행

    /// 각 연락처의 한 줄 표시
    /// 탭하면 전화 연결
    private func contactRow(_ contact: EmergencyContact) -> some View {
        Button {
            if let url = viewModel.makeCallURL(phoneNumber: contact.phoneNumber) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 12) {
                // 아이콘
                Image(systemName: contact.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor(for: contact.category))
                    .frame(width: 32, height: 32)

                // 이름 + 전화번호
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(HiTripColor.textGrayA)

                    Text(contact.phoneNumber)
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray400)
                }

                Spacer()

                // 전화 아이콘
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(HiTripColor.primary800)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 헬퍼

    /// 카테고리별 아이콘 색상
    private func iconColor(for category: ContactCategory) -> Color {
        switch category {
        case .emergency: return .red
        case .medical:   return .orange
        case .tourism:   return HiTripColor.primary800
        case .personal:  return .gray
        }
    }

    /// 스와이프 삭제 처리 — 프리셋은 삭제 불가
    private func deleteContacts(
        in categoryContacts: [EmergencyContact],
        at indexSet: IndexSet
    ) {
        for index in indexSet {
            let contact = categoryContacts[index]
            if !contact.isPreset {
                viewModel.deleteContact(id: contact.id)
            }
        }
    }
}
