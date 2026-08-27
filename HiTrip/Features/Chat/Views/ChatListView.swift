import SwiftUI

// MARK: - ChatFilter
enum ChatFilter: String, CaseIterable {
    case all     = "전체"
    case unread  = "미확인"
    case group   = "단체"
}

// MARK: - ChatListView
/// 메시지 및 문의 목록 화면
///
/// 피그마 0827 수정본:
/// - 헤더: "메시지 및 문의" + "모두 확인" 버튼
/// - 검색바
/// - 탭 필터: 전체 / 미확인 / 단체
/// - 채팅방 목록 (그룹톡, 1:1)

struct ChatListView: View {

    @ObservedObject var viewModel: ChatViewModel
    @State private var selectedRoom: ChatRoom?
    @State private var navigateToRoom = false
    @State private var searchText   = ""
    @State private var filter: ChatFilter = .all

    private var filteredRooms: [ChatRoom] {
        let base: [ChatRoom]
        switch filter {
        case .all:    base = viewModel.chatRooms
        case .unread: base = viewModel.chatRooms.filter { $0.unreadCount > 0 }
        case .group:  base = viewModel.chatRooms.filter { $0.isGroupChat }
        }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.participantName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sectionHeader
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.md)

                searchBar
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.md)

                filterTabBar
                    .padding(.top, HiTripSpacing.md)

                Divider()
                    .padding(.top, HiTripSpacing.smd)

                if filteredRooms.isEmpty {
                    emptyState
                } else {
                    roomList
                }
            }
            .background(Color.white)
            .navigationTitle("메시지")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToRoom) {
                if let room = selectedRoom {
                    ChatRoomView(viewModel: viewModel, chatRoom: room)
                }
            }
            .onAppear { viewModel.fetchChatRooms() }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("메시지 및 문의")
                .font(HiTripFont.title2)
                .foregroundColor(HiTripColor.textBlack)
            Spacer()
            Button {
                viewModel.markAllAsRead()
            } label: {
                Text("모두 확인")
                    .font(HiTripFont.captionM)
                    .foregroundColor(HiTripColor.primary800)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: HiTripSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray400)
            TextField("채팅 및 메시지 검색", text: $searchText)
                .font(HiTripFont.body)
        }
        .padding(.horizontal, HiTripSpacing.mdl)
        .padding(.vertical, HiTripSpacing.smd)
        .background(HiTripColor.gray100)
        .cornerRadius(HiTripRadius.card)
    }

    // MARK: - Filter Tab Bar

    private var filterTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ChatFilter.allCases, id: \.self) { tab in
                filterTab(tab)
            }
        }
        .padding(.horizontal, HiTripSpacing.pagePadding)
    }

    private func filterTab(_ tab: ChatFilter) -> some View {
        Button {
            filter = tab
        } label: {
            Text(tab.rawValue)
                .font(HiTripFont.labelM)
                .foregroundColor(filter == tab ? HiTripColor.primary800 : HiTripColor.gray400)
                .padding(.vertical, HiTripSpacing.sm)
                .padding(.horizontal, HiTripSpacing.mdl)
                .background(
                    filter == tab
                        ? HiTripColor.primary800.opacity(0.08)
                        : Color.clear
                )
                .cornerRadius(HiTripRadius.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Room List

    private var roomList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredRooms) { room in
                    Button {
                        selectedRoom = room
                        navigateToRoom = true
                    } label: {
                        roomRow(room)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 86)
                }
            }
            .padding(.top, HiTripSpacing.xs)
        }
    }

    // MARK: - Room Row

    private func roomRow(_ room: ChatRoom) -> some View {
        HStack(spacing: HiTripSpacing.mdl) {
            // 아바타
            avatarView(room)
                .frame(width: 52, height: 52)

            // 이름 + 마지막 메시지
            VStack(alignment: .leading, spacing: HiTripSpacing.xs) {
                Text(room.participantName)
                    .font(HiTripFont.bodyBold)
                    .foregroundColor(HiTripColor.textBlack)

                Text(room.lastMessage.isEmpty ? "새로운 채팅방" : room.lastMessage)
                    .font(HiTripFont.label)
                    .foregroundColor(
                        room.lastMessage.lowercased().contains("typing")
                            ? HiTripColor.primary800
                            : HiTripColor.gray500
                    )
                    .lineLimit(1)
            }

            Spacer()

            // 시간 + 뱃지
            VStack(alignment: .trailing, spacing: HiTripSpacing.xs) {
                Text(formatTime(room.lastMessageDate))
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.gray400)

                if room.unreadCount > 0 {
                    Text("\(room.unreadCount)")
                        .font(HiTripFont.badge)
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(HiTripColor.error)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, HiTripSpacing.pagePadding)
        .padding(.vertical, HiTripSpacing.md)
    }

    // MARK: - Avatar

    @ViewBuilder
    private func avatarView(_ room: ChatRoom) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(HiTripColor.gray100)
                .overlay(
                    Image(systemName: room.isGroupChat ? "person.3.fill" : "person.fill")
                        .font(.system(size: room.isGroupChat ? 18 : 20))
                        .foregroundColor(HiTripColor.gray400)
                )

            if room.isOnline && !room.isGroupChat {
                Circle()
                    .fill(HiTripColor.onlineGreen)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: HiTripSpacing.md) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)
            Text("메시지가 없습니다")
                .font(HiTripFont.bodyBold)
                .foregroundColor(HiTripColor.textBlack)
            Text("여행사에서 채팅방을 개설하면\n여기에 표시됩니다")
                .font(HiTripFont.body)
                .foregroundColor(HiTripColor.gray500)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "a h:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return "어제"
        } else {
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }
}
