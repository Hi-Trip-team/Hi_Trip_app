import SwiftUI

struct StaffChatListView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter = "전체"

    private let filters = ["전체", "미확인", "단체"]

    private let chats: [StaffChatItem] = [
        StaffChatItem(name: "📌 여행 단체톡방", lastMessage: "오늘 저녁 집합 시간 안내드립니다",
                      time: "일 12:40", unread: 9, isGroup: true),
        StaffChatItem(name: "둘리", lastMessage: "가이드님 위치 확인 부탁드려요",
                      time: "일 11:50", unread: 1, isGroup: false),
        StaffChatItem(name: "이연세", lastMessage: "감사합니다!",
                      time: "화 10:56", unread: 0, isGroup: false),
        StaffChatItem(name: "펭수", lastMessage: "내일 일정 관련 문의드립니다",
                      time: "화 10:56", unread: 0, isGroup: false),
    ]

    private var filtered: [StaffChatItem] {
        switch selectedFilter {
        case "미확인": return chats.filter { $0.unread > 0 }
        case "단체": return chats.filter { $0.isGroup }
        default: return chats
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            // 필터 칩
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { f in
                    Button { selectedFilter = f } label: {
                        Text(f)
                            .font(.system(size: 12, weight: selectedFilter == f ? .bold : .medium))
                            .foregroundColor(selectedFilter == f ? .white : Color(hex: "#6B7280"))
                            .frame(width: f == "미확인" ? 76 : 60, height: 34)
                            .background(selectedFilter == f ? Color(hex: "#2563EB") : Color(hex: "#F3F4F6"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { chat in
                        chatRow(chat)
                        Divider()
                            .padding(.leading, 24)
                    }
                }
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("메시지 및 문의")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
                Button { } label: {
                    Text("모두 확인")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#2563EB"))
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    // MARK: - 채팅 행

    private func chatRow(_ chat: StaffChatItem) -> some View {
        HStack(spacing: 14) {
            // 아바타
            Circle()
                .fill(Color(hex: "#E5E7EB"))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(chat.isGroup ? "👥" : String(chat.name.prefix(1)))
                        .font(.system(size: chat.isGroup ? 20 : 18, weight: .medium))
                        .foregroundColor(Color(hex: "#6B7280"))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(chat.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                Text(chat.lastMessage)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(chat.time)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))

                if chat.unread > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 22, height: 22)
                        Text("\(chat.unread)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

private struct StaffChatItem: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unread: Int
    let isGroup: Bool
}
