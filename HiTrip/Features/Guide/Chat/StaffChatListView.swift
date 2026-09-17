import SwiftUI

// MARK: - StaffChatListView
/// 고객 관리 (메시지) — Figma 12381:4655
///
/// - GET /api/v1/chat/rooms/   여행객과 같은 엔드포인트 (세션 쿠키로도 인증됩니다)
///
/// 채팅방 화면은 여행객 것과 동일한 ChatRoomView를 그대로 씁니다.
/// 정렬은 마지막 메시지 최신순이고, 길게 눌러 상단에 고정할 수 있습니다 (고정은 이 기기에만 저장).

struct StaffChatListView: View {

    /// 지금 담당 중인 여행 — "진행중" 필터 기준
    var currentTripId: Int?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AppDIContainer.shared.makeChatViewModel()

    @State private var tab: Tab = .ongoing
    @State private var selectedRoom: ChatRoom?
    @State private var showMarkAllConfirm = false
    @State private var searchText = ""

    /// 검색창 포커스 — 목록을 누르면 키보드를 내립니다
    @FocusState private var isSearchFocused: Bool

    /// 상단 고정한 방의 서버 ID (쉼표 구분) — 서버에 고정 필드가 없어 기기에 저장합니다
    @AppStorage("staffPinnedChatRoomIds") private var pinnedIdsRaw = ""

    private enum Tab: String, CaseIterable, Identifiable {
        /// 지금 담당 중인 여행의 방만
        case ongoing = "진행중"
        /// 고정 + 최신순
        case all = "전체"
        /// 안읽음이 있는 방만
        case unread = "미확인"
        /// 단체톡방만
        case group = "단체"
        /// 1:1 방만
        case direct = "개인"

        var id: String { rawValue }
        var width: CGFloat { self == .ongoing || self == .unread ? 68 : 56 }
    }

    // MARK: - 목록

    private var pinnedIds: Set<Int> {
        Set(pinnedIdsRaw.split(separator: ",").compactMap { Int($0) })
    }

    private func isPinned(_ room: ChatRoom) -> Bool {
        room.serverId.map(pinnedIds.contains) ?? false
    }

    private func togglePin(_ room: ChatRoom) {
        guard let id = room.serverId else { return }
        var ids = pinnedIds
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        pinnedIdsRaw = ids.sorted().map(String.init).joined(separator: ",")
    }

    /// 고정한 방 먼저, 이하 마지막 메시지 최신순
    private var sortedRooms: [ChatRoom] {
        viewModel.chatRooms.sorted { a, b in
            let pa = isPinned(a), pb = isPinned(b)
            if pa != pb { return pa }
            return a.lastMessageDate > b.lastMessageDate
        }
    }

    private var rooms: [ChatRoom] {
        let byTab: [ChatRoom]
        switch tab {
        case .ongoing: byTab = sortedRooms.filter { currentTripId != nil && $0.tripId == currentTripId }
        case .all:     byTab = sortedRooms
        case .unread:  byTab = sortedRooms.filter { $0.unreadCount > 0 }
        case .group:   byTab = sortedRooms.filter { $0.isGroupChat }
        case .direct:  byTab = sortedRooms.filter { !$0.isGroupChat }
        }
        guard !searchText.isEmpty else { return byTab }
        return byTab.filter {
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

            tabRow
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)

            if rooms.isEmpty {
                emptyView
            } else {
                roomList
                    .scrollDismissesKeyboard(.immediately)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .navigationDestination(unwrapping: $selectedRoom) { room in
            ChatRoomView(viewModel: viewModel, chatRoom: room)
        }
        .onAppear {
            // 담당 여행이 없으면 "진행중"이 비어 있으므로 전체부터
            if currentTripId == nil, tab == .ongoing { tab = .all }
            viewModel.fetchChatRooms()
        }
        .confirmationDialog(
            "모든 채팅을 읽음 처리할까요?",
            isPresented: $showMarkAllConfirm,
            titleVisibility: .visible
        ) {
            Button("확인") { viewModel.markAllAsRead() }
            Button("취소", role: .cancel) { }
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        NavigationHeader(title: "메시지 및 문의", horizontalInset: AppSpacing.lg, onBack: { dismiss() }) {
            // 즉시 실행하지 않고 한 번 확인합니다
            HeaderTextButton("모두 확인") { showMarkAllConfirm = true }
        }
    }

    // MARK: - 검색바 (여행객 목록과 같은 모양)

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

    // MARK: - 탭 필터

    private var tabRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(Tab.allCases) { item in
                let isOn = tab == item
                Button { tab = item } label: {
                    Text(item.rawValue)
                        .font(isOn ? AppFont.captionBold : AppFont.captionMedium)
                        .foregroundColor(isOn ? .white : AppColor.textSecondary)
                        .frame(width: item.width, height: 34)
                        .background(isOn ? AppColor.accent : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - 방 목록

    private var roomList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(rooms) { room in
                    Button {
                        isSearchFocused = false
                        selectedRoom = room
                    } label: { roomRow(room) }
                        .buttonStyle(.plain)
                        // 길게 눌러 상단 고정/해제
                        .contextMenu {
                            Button {
                                togglePin(room)
                            } label: {
                                Label(isPinned(room) ? "고정 해제" : "상단 고정",
                                      systemImage: isPinned(room) ? "pin.slash" : "pin")
                            }
                        }

                    Rectangle()
                        .fill(AppColor.divider)
                        .frame(height: 1)
                        .padding(.horizontal, AppSpacing.xl)
                }
            }
        }
        .refreshable { viewModel.fetchChatRooms() }
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
                HStack(spacing: 4) {
                    Text(room.participantName)
                        .font(AppFont.bodyBold)
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(1)
                    if isPinned(room) {
                        Image(systemName: "pin.fill")
                            .font(AppFont.icon(11))
                            .foregroundColor(AppColor.textTertiary)
                    }
                }

                Text(room.lastMessage.isEmpty ? "새로운 채팅방" : room.lastMessage)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(AppDate.chatListTime(room.lastMessageDate, showsWeekday: true))
                    .font(AppFont.caption2)
                    .foregroundColor(AppColor.textSecondary)

                if room.unreadCount > 0 {
                    CountBadge(text: room.unreadCount > 99 ? "99+" : "\(room.unreadCount)")
                } else {
                    Color.clear.frame(width: 0, height: 22)
                }
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .background(Color.white)
        .contentShape(Rectangle())
    }

    // MARK: - 빈 상태

    private var emptyView: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: emptyIcon)
                .font(AppFont.logo)
                .foregroundColor(AppColor.borderStrong)
            Text(emptyText)
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyIcon: String {
        if !searchText.isEmpty { return "magnifyingglass" }
        return tab == .unread ? "checkmark.circle" : "bubble.left.and.bubble.right"
    }

    private var emptyText: String {
        if !searchText.isEmpty { return "검색 결과가 없어요" }
        switch tab {
        case .unread:  return "미확인 메시지가 없어요"
        case .ongoing: return "진행 중인 여행의 채팅이 없어요"
        default:       return "메시지가 없어요"
        }
    }

}
