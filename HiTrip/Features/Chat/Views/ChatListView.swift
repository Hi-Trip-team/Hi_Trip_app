import SwiftUI

// MARK: - ChatListView
/// 메시지 목록 화면
///
/// 피그마 디자인:
/// - 상단: ← "메시지" ... (네비게이션)
/// - "메시지 및 문의" 헤더 + 새 메시지 아이콘
/// - 검색바
/// - 채팅방 리스트 (단체톡방 + 가이드 개인톡)
///
/// 여행사가 그룹을 만들면 자동으로 단체톡방과 가이드 개인톡이 생성됨.
/// 사용자가 직접 채팅방을 만들 수는 없음.

struct ChatListView: View {

    @ObservedObject var viewModel: ChatViewModel
    @State private var navigateToRoom: Bool = false
    @State private var selectedRoom: ChatRoom?
    @State private var searchText: String = ""

    /// 검색 필터 적용
    private var filteredRooms: [ChatRoom] {
        if searchText.isEmpty {
            return viewModel.chatRooms
        }
        return viewModel.chatRooms.filter {
            $0.participantName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // "메시지 및 문의" 헤더
                sectionHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // 검색바
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // 채팅방 리스트
                if filteredRooms.isEmpty {
                    emptyStateView
                } else {
                    chatRoomList
                }

                Spacer()
            }
            .background(Color.white)
            .navigationTitle("메시지")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToRoom) {
                if let room = selectedRoom {
                    ChatRoomView(viewModel: viewModel, chatRoom: room)
                }
            }
            .onAppear {
                viewModel.fetchChatRooms()
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("메시지 및 문의")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)

            Spacer()

            Image(systemName: "square.and.pencil")
                .font(.system(size: 18))
                .foregroundColor(HiTripColor.textBlack)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(HiTripColor.gray400)

            TextField("채팅 및 메시지 검색", text: $searchText)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HiTripColor.gray100)
        .cornerRadius(12)
    }

    // MARK: - Chat Room List

    private var chatRoomList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredRooms) { room in
                    Button {
                        selectedRoom = room
                        navigateToRoom = true
                    } label: {
                        chatRoomRow(room)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Chat Room Row

    private func chatRoomRow(_ room: ChatRoom) -> some View {
        HStack(spacing: 14) {
            // 아바타 + 온라인 표시
            ZStack(alignment: .bottomLeading) {
                Circle()
                    .fill(HiTripColor.gray200)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: room.isGroupChat ? "person.3.fill" : "person.fill")
                            .font(.system(size: room.isGroupChat ? 18 : 20))
                            .foregroundColor(HiTripColor.gray400)
                    )

                // 온라인 도트
                if room.isOnline {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 2, y: -2)
                }
            }

            // 이름 + 마지막 메시지
            VStack(alignment: .leading, spacing: 4) {
                Text(room.participantName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)

                Text(room.lastMessage.isEmpty ? "새로운 채팅방" : room.lastMessage)
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray500)
                    .lineLimit(1)
            }

            Spacer()

            // 읽음 체크 + 시간
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    // 읽음 체크마크
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(HiTripColor.gray400)

                    Text(formatTime(room.lastMessageDate))
                        .font(.system(size: 12))
                        .foregroundColor(HiTripColor.gray400)
                }

                if room.unreadCount > 0 {
                    Text("\(room.unreadCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(HiTripColor.error)
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(HiTripColor.gray300)

            Text("메시지가 없습니다")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            Text("여행사에서 채팅방을 개설하면\n여기에 표시됩니다")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray500)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Time Format

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }
}
