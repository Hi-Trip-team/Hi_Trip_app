import SwiftUI

// MARK: - StaffChatListView
/// 고객 관리 (메시지) — Figma 12381:4655
///
/// - GET /api/v1/chat/rooms/   여행객과 같은 엔드포인트 (세션 쿠키로도 인증됩니다)
///
/// 채팅방 화면은 여행객 것과 동일한 ChatRoomView를 그대로 씁니다.
/// 단체톡방은 여행 등록 시 자동 생성되고 나가기가 없어 항상 최상단에 고정합니다.

struct StaffChatListView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AppDIContainer.shared.makeChatViewModel()

    @State private var tab: Tab = .all
    @State private var selectedRoom: ChatRoom?
    @State private var showMarkAllConfirm = false

    /// 기획 재정의 — 기존 "최근·이전·확인됨"은 기준이 모호했습니다
    private enum Tab: String, CaseIterable, Identifiable {
        /// 단체 고정 + 최신순
        case all = "전체"
        /// 안읽음이 있는 방만
        case unread = "미확인"
        /// 단체톡방만
        case group = "단체"

        var id: String { rawValue }
        var width: CGFloat { self == .unread ? 76 : 60 }
    }

    // MARK: - 목록

    /// 단체톡방 최상단 고정, 이하 마지막 메시지 최신순
    private var sortedRooms: [ChatRoom] {
        viewModel.chatRooms.sorted { a, b in
            if a.isGroupChat != b.isGroupChat { return a.isGroupChat }
            return a.lastMessageDate > b.lastMessageDate
        }
    }

    private var rooms: [ChatRoom] {
        switch tab {
        case .all:    return sortedRooms
        case .unread: return sortedRooms.filter { $0.unreadCount > 0 }
        case .group:  return sortedRooms.filter { $0.isGroupChat }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            tabRow
                .padding(.top, 36)
                .padding(.bottom, AppSpacing.lg)

            if rooms.isEmpty {
                emptyView
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
        ZStack {
            Text("메시지 및 문의")
                .font(AppFont.headlineBold)
                .foregroundColor(AppColor.textPrimary)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(AppFont.title3Medium)
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                Spacer()
                // 즉시 실행하지 않고 한 번 확인합니다
                Button { showMarkAllConfirm = true } label: {
                    Text("모두 확인")
                        .font(AppFont.labelMedium)
                        .foregroundColor(AppColor.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.sm)
        }
        .frame(height: 24)
        .padding(.top, AppSpacing.xs)
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
                    Button { selectedRoom = room } label: { roomRow(room) }
                        .buttonStyle(.plain)

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
                Text(room.isGroupChat ? "📌 \(room.participantName)" : room.participantName)
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
                Text(Self.timeText(room.lastMessageDate))
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
                    Color.clear.frame(width: 0, height: 22)
                }
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .contentShape(Rectangle())
    }

    // MARK: - 빈 상태

    private var emptyView: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: tab == .unread ? "checkmark.circle" : "bubble.left.and.bubble.right")
                .font(AppFont.logo)
                .foregroundColor(AppColor.borderStrong)
            Text(tab == .unread ? "미확인 메시지가 없어요" : "메시지가 없어요")
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// 오늘=HH:mm, 어제="어제", 이번 주=요일+시각("일 12:40"), 그 이전=M.D
    private static func timeText(_ date: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")

        if cal.isDateInToday(date) {
            f.dateFormat = "HH:mm"
        } else if cal.isDateInYesterday(date) {
            return "어제"
        } else if let days = cal.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            f.dateFormat = "E HH:mm"
        } else {
            f.dateFormat = "M.d"
        }
        return f.string(from: date)
    }
}
