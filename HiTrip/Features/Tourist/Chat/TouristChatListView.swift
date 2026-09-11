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

    /// 검색창 포커스 — 목록을 누르면 키보드를 내립니다
    @FocusState private var isSearchFocused: Bool

    /// 단체톡방을 맨 위에 고정하고, 나머지는 마지막 메시지 최신순입니다.
    private var sortedRooms: [ChatRoom] {
        viewModel.chatRooms.sorted { a, b in
            if a.isGroupChat != b.isGroupChat { return a.isGroupChat }
            return a.lastMessageDate > b.lastMessageDate
        }
    }

    private var filteredRooms: [ChatRoom] {
        guard !searchText.isEmpty else { return sortedRooms }
        return sortedRooms.filter {
            $0.participantName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            searchBar
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, 3)
                .padding(.bottom, AppSpacing.lg)

            if filteredRooms.isEmpty {
                emptyState(isSearching: !searchText.isEmpty)
            } else {
                roomList
                    .scrollDismissesKeyboard(.immediately)
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
                .font(AppFont.headlineBold)
                .foregroundColor(AppColor.textPrimary)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(AppFont.title3Medium)
                        .foregroundColor(.black)
                }
                Spacer()
                Button { viewModel.markAllAsRead() } label: {
                    Text("모두 확인")
                        .font(AppFont.labelMedium)
                        .foregroundColor(AppColor.accent)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
        }
        .frame(height: 44)
        .padding(.top, AppSpacing.xs)
    }

    // MARK: - 검색바

    private var searchBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(AppFont.body)
                .foregroundColor(AppColor.textSecondary)
            TextField("채팅 및 메시지 검색", text: $searchText)
                .focused($isSearchFocused)
                .font(AppFont.label)
                .foregroundColor(AppColor.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 44)
        .background(AppColor.surface)
        .clipShape(Capsule())
    }

    // MARK: - 목록

    private var roomList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredRooms) { room in
                    Button {
                        isSearchFocused = false
                        selectedRoom = room
                    } label: {
                        roomRow(room)
                    }
                    .buttonStyle(.plain)

                    // Figma 구분선 #E5E7EB 1pt — 기본 Divider는 시스템 색이라 더 진합니다
                    Rectangle()
                        .fill(AppColor.divider)
                        .frame(height: 1)
                        .padding(.horizontal, AppSpacing.xl)
                }
            }
        }
    }

    private func roomRow(_ room: ChatRoom) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(AppColor.surface)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: room.isGroupChat ? "person.3.fill" : "person.fill")
                        .font(AppFont.icon(room.isGroupChat ? 17 : 19))
                        .foregroundColor(AppColor.textTertiary)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(room.participantName)
                    .font(AppFont.bodyBold)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)

                Text(room.lastMessage.isEmpty ? "새로운 채팅방" : room.lastMessage)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatTime(room.lastMessageDate))
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textSecondary)

                if room.unreadCount > 0 {
                    Text(room.unreadCount > 99 ? "99+" : "\(room.unreadCount)")
                        .font(AppFont.captionBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(AppColor.danger)
                        .clipShape(Capsule())
                } else {
                    // 뱃지 자리를 비워 이름·시각 줄이 흔들리지 않게 합니다.
                    Color.clear.frame(width: 0, height: 22)
                }
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }

    // MARK: - 빈 상태

    private func emptyState(isSearching: Bool) -> some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: isSearching ? "magnifyingglass" : "bubble.left.and.bubble.right")
                .font(AppFont.logo)
                .foregroundColor(AppColor.borderStrong)
            Text(isSearching ? "검색 결과가 없어요" : "메시지가 없어요")
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
            Text(isSearching
                 ? "다른 이름이나 내용으로 검색해 보세요"
                 : "여행사에서 채팅방을 개설하면\n여기에 표시됩니다")
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// 오늘=HH:mm, 어제="어제", 그 이전=M.D
    private func formatTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInYesterday(date) { return "어제" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = cal.isDateInToday(date) ? "HH:mm" : "M.d"
        return f.string(from: date)
    }
}
