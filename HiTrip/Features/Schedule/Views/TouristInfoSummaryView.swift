import SwiftUI

// MARK: - TouristInfoItem

struct TouristInfoItem: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let passportNumber: String
    let phone: String
    let age: Int
    let note: String?
}

// MARK: - TouristInfoSummaryView
/// 관광객 정보 목록 화면 (여행사용)

struct TouristInfoSummaryView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTourist: TouristInfoItem?

    private let tourists: [TouristInfoItem] = [
        TouristInfoItem(name: "이연서", country: "대한민국", passportNumber: "DND***000",
                        phone: "010-1234-5678", age: 34, note: nil),
        TouristInfoItem(name: "김민준", country: "대한민국", passportNumber: "KIM***123",
                        phone: "010-2345-6789", age: 28, note: "심장 질환 주의"),
        TouristInfoItem(name: "박서연", country: "대한민국", passportNumber: "PAK***456",
                        phone: "010-3456-7890", age: 45, note: nil),
        TouristInfoItem(name: "정우진", country: "미국", passportNumber: "JEO***789",
                        phone: "010-4567-8901", age: 52, note: nil),
        TouristInfoItem(name: "최지훈", country: "일본", passportNumber: "CHO***012",
                        phone: "010-5678-9012", age: 31, note: "고혈압"),
        TouristInfoItem(name: "툴리", country: "대한민국", passportNumber: "TUL***345",
                        phone: "010-6565-8485", age: 38, note: nil),
    ]

    private var filtered: [TouristInfoItem] {
        searchText.isEmpty
            ? tourists
            : tourists.filter { $0.name.contains(searchText) || $0.country.contains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            searchBar
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            touristList
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(HiTripColor.textBlack)
            }
            Spacer()
            Text("관광객 정보")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            Color.clear.frame(width: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
            TextField("이름으로 검색", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.textBlack)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HiTripColor.gray100)
        .cornerRadius(10)
    }

    // MARK: - List

    private var touristList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { tourist in
                    touristRow(tourist)
                    Divider().padding(.leading, 20)
                }
            }
        }
    }

    private func touristRow(_ tourist: TouristInfoItem) -> some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(HiTripColor.gray100)
                .frame(width: 46, height: 46)
                .overlay(
                    Text(String(tourist.name.prefix(1)))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(HiTripColor.gray500)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(tourist.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(HiTripColor.textBlack)
                    Text("\(tourist.age)세")
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray400)
                    if let note = tourist.note {
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 8) {
                    Text(tourist.country)
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray500)
                    Text("·")
                        .foregroundColor(HiTripColor.gray300)
                    Text(tourist.passportNumber)
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray500)
                }
            }

            Spacer()

            Button {
                // 전화걸기
            } label: {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(HiTripColor.primary800)
                    .frame(width: 36, height: 36)
                    .background(HiTripColor.primary800.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
