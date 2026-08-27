import SwiftUI

// MARK: - TouristChatListView
/// 여행객(Tourist) 전용 메시지 목록 화면
///
/// 피그마 0827 여행객 측:
/// - 헤더: "메시지 및 문의" + "모두 확인" 버튼
/// - 검색바 (채팅 및 메시지 검색)
/// - 채팅방 목록 (필터 태그 없음)

struct TouristChatListView: View {

    @ObservedObject var viewModel: ChatViewModel
    @State private var selectedRoom: ChatRoom?
    @State private var navigateToRoom = false
    @State private var searchText = ""

    private var filteredRooms: [ChatRoom] {
        guard !searchText.isEmpty else { return viewModel.chatRooms }
        return viewModel.chatRooms.filter {
            $0.participantName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Row 1: 헤더
                sectionHeader
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.md)

                // Row 2: 검색바
                searchBar
                    .padding(.horizontal, HiTripSpacing.pagePadding)
                    .padding(.top, HiTripSpacing.md)
                    .padding(.bottom, HiTripSpacing.smd)

                Divider()

                // Row 3: 채팅방 목록
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

    // MARK: - Row 1: 헤더

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

    // MARK: - Row 2: 검색바

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

    // MARK: - Row 3: 채팅방 목록

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

    private func roomRow(_ room: ChatRoom) -> some View {
        HStack(spacing: HiTripSpacing.mdl) {
            avatarView(room)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: HiTripSpacing.xs) {
                Text(room.participantName)
                    .font(HiTripFont.bodyBold)
                    .foregroundColor(HiTripColor.textBlack)

                Text(room.lastMessage.isEmpty ? "새로운 채팅방" : room.lastMessage)
                    .font(HiTripFont.label)
                    .foregroundColor(HiTripColor.gray500)
                    .lineLimit(1)
            }

            Spacer()

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
