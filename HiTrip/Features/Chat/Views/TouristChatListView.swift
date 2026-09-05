import SwiftUI

// MARK: - TouristChatListView
/// 여행객 메시지 목록 — 홈의 "메시지 및 문의"로 진입
///
/// - GET /api/v1/chat/rooms/
///
/// 헤더는 한 줄입니다. 뒤로가기 / "메시지 및 문의" / "모두 확인".
/// 접속 상태(초록 점)는 서버가 주지 않아 표시하지 않습니다.

struct TouristChatListView: View {

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRoom: ChatRoom?
    @State private var searchText = ""

    private var filteredRooms: [ChatRoom] {
        guard !searchText.isEmpty else { return viewModel.chatRooms }
        return viewModel.chatRooms.filter {
            $0.participantName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            searchBar
                .padding(.horizontal, 24)
                .padding(.top, 3)
                .padding(.bottom, 20)

            if filteredRooms.isEmpty {
                emptyState
            } else {
                roomList
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedRoom) { room in
            ChatRoomView(viewModel: viewModel, chatRoom: room)
        }
        .onAppear { viewModel.fetchChatRooms() }
    }

    // MARK: - 헤더

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
                Button { viewModel.markAllAsRead() } label: {
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

    // MARK: - 검색바

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6B7280"))
            TextField("채팅 및 메시지 검색", text: $searchText)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#111827"))
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
        .background(Color(hex: "#F3F4F6"))
        .clipShape(Capsule())
    }

    // MARK: - 목록

    private var roomList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredRooms) { room in
                    Button { selectedRoom = room } label: {
                        roomRow(room)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private func roomRow(_ room: ChatRoom) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: room.isGroupChat ? "person.3.fill" : "person.fill")
                        .font(.system(size: room.isGroupChat ? 17 : 19))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(room.participantName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                    .lineLimit(1)

                Text(room.lastMessage.isEmpty ? "새로운 채팅방" : room.lastMessage)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatTime(room.lastMessageDate))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#6B7280"))

                if room.unreadCount > 0 {
                    Text("\(room.unreadCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Color(hex: "#EF4444"))
                        .clipShape(Capsule())
                } else {
                    // 뱃지 자리를 비워 이름·시각 줄이 흔들리지 않게 합니다.
                    Color.clear.frame(width: 0, height: 22)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#D1D5DB"))
            Text("메시지가 없습니다")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Text("여행사에서 채팅방을 개설하면\n여기에 표시됩니다")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// 오늘이면 시각, 어제면 "어제", 그 이전은 날짜
    private func formatTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInYesterday(date) { return "어제" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = cal.isDateInToday(date) ? "a h:mm" : "M/d"
        return f.string(from: date)
    }
}
