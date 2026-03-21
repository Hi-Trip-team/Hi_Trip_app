import SwiftUI

// MARK: - ChatListView
/// 채팅방 목록 화면
///
/// 카카오톡 채팅 목록과 유사한 구조:
/// - 상대방 이름, 마지막 메시지, 시간, 읽지 않은 수 표시
/// - 탭하면 ChatRoomView로 이동
/// - 스와이프로 채팅방 삭제
/// - 우상단 + 버튼으로 새 채팅방 생성
///
/// ScheduleListView와 동일한 패턴:
/// - @ObservedObject로 ViewModel 관찰
/// - .onAppear에서 데이터 로드
/// - .sheet로 생성 화면 표시

struct ChatListView: View {

    @ObservedObject var viewModel: ChatViewModel
    @State private var showCreateSheet = false
    @State private var selectedRoom: ChatRoom?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.chatRooms.isEmpty {
                    emptyStateView
                } else {
                    chatRoomList
                }
            }
            .navigationTitle("채팅")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                ChatCreateView(viewModel: viewModel)
            }
            .onChange(of: showCreateSheet) { isPresented in
                // 시트가 닫힐 때 목록 새로고침
                if !isPresented {
                    viewModel.fetchChatRooms()
                    viewModel.resetForm()
                }
            }
            .onAppear {
                viewModel.fetchChatRooms()
            }
        }
    }

    // MARK: - 채팅방 목록

    private var chatRoomList: some View {
        List {
            ForEach(viewModel.chatRooms) { room in
                Button {
                    selectedRoom = room
                } label: {
                    chatRoomRow(room)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let room = viewModel.chatRooms[index]
                    viewModel.deleteChatRoom(id: room.id)
                }
            }
        }
        .listStyle(.plain)
        .sheet(item: $selectedRoom) { room in
            ChatRoomView(viewModel: viewModel, chatRoom: room)
        }
    }

    // MARK: - 채팅방 행 (Row)

    /// 각 채팅방의 한 줄 표시
    /// - 왼쪽: 이니셜 아바타 + 이름 + 마지막 메시지
    /// - 오른쪽: 시간 + 읽지 않은 수 뱃지
    private func chatRoomRow(_ room: ChatRoom) -> some View {
        HStack(spacing: 12) {
            // 아바타 (이니셜)
            Circle()
                .fill(HiTripColor.primary800.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(room.participantName.prefix(1)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(HiTripColor.primary800)
                )

            // 이름 + 마지막 메시지
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(room.participantName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(HiTripColor.textGrayA)

                    // 안내사/관광객 배지
                    Text(room.participantType == "guide" ? "안내사" : "관광객")
                        .font(.system(size: 10))
                        .foregroundColor(HiTripColor.primary800)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HiTripColor.secondary100)
                        .cornerRadius(4)
                }

                Text(room.lastMessage.isEmpty ? "새로운 채팅방" : room.lastMessage)
                    .font(.system(size: 14))
                    .foregroundColor(HiTripColor.gray400)
                    .lineLimit(1)
            }

            Spacer()

            // 시간 + 읽지 않은 수
            VStack(alignment: .trailing, spacing: 6) {
                Text(formatDate(room.lastMessageDate))
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)

                if room.unreadCount > 0 {
                    Text("\(room.unreadCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(HiTripColor.error)
                        .cornerRadius(10)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 빈 상태

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(HiTripColor.gray300)
            Text("채팅방이 없습니다")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(HiTripColor.textGrayA)
            Text("+ 버튼을 눌러 새 채팅을 시작해보세요")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)
            Spacer()
        }
    }

    // MARK: - 날짜 포맷

    /// 오늘이면 "오후 3:42", 아니면 "3/21"
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "a h:mm"
        } else {
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }
}
