import SwiftUI

// MARK: - ScheduleListView
/// 일정 목록 화면 — CRUD의 [R] Read 담당
///
/// UI 구성:
/// - 네비게이션 바 (타이틀 + "+" 추가 버튼)
/// - 일정이 없으면 빈 상태 안내
/// - 일정이 있으면 리스트로 표시 (날짜순 정렬)
/// - 각 항목 탭 → 상세 화면으로 이동
/// - 스와이프 → 삭제

struct ScheduleListView: View {

    @ObservedObject var viewModel: ScheduleViewModel

    /// 일정 생성 화면 표시 여부
    @State private var showCreateView = false

    /// 상세 화면으로 이동할 일정
    @State private var selectedSchedule: Schedule?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.schedules.isEmpty && !viewModel.isLoading {
                    // 빈 상태
                    emptyStateView
                } else {
                    // 일정 목록
                    scheduleListContent
                }
            }
            .navigationTitle("일정")
            .toolbar {
                // 오른쪽 상단 "+" 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.resetForm()
                        showCreateView = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(HiTripColor.primary800)
                    }
                }
            }
            // 생성 화면 (시트로 표시)
            .sheet(isPresented: $showCreateView) {
                ScheduleCreateView(viewModel: viewModel)
            }
            // 상세 화면 (시트로 표시)
            .sheet(item: $selectedSchedule) { schedule in
                ScheduleDetailView(viewModel: viewModel, schedule: schedule)
            }
            // 생성/수정 화면 닫힌 후 목록 새로고침
            .onChange(of: showCreateView) { isShowing in
                if !isShowing { viewModel.fetchSchedules() }
            }
            .onChange(of: selectedSchedule) { selected in
                if selected == nil { viewModel.fetchSchedules() }
            }
            // 화면 진입 시 목록 로드
            .onAppear {
                viewModel.fetchSchedules()
            }
        }
    }

    // MARK: - Empty State

    /// 일정이 없을 때 표시하는 안내 화면
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(HiTripColor.gray300)

            Text("등록된 일정이 없습니다")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(HiTripColor.gray500)

            Text("오른쪽 상단 +를 눌러 일정을 추가해보세요")
                .font(.system(size: 14))
                .foregroundColor(HiTripColor.gray400)

            Spacer()
        }
    }

    // MARK: - Schedule List

    /// 일정 목록 리스트
    private var scheduleListContent: some View {
        List {
            ForEach(viewModel.schedules) { schedule in
                scheduleRow(schedule)
                    .contentShape(Rectangle()) // 전체 영역 탭 가능
                    .onTapGesture {
                        selectedSchedule = schedule
                    }
            }
            // 스와이프 삭제
            .onDelete { indexSet in
                for index in indexSet {
                    let schedule = viewModel.schedules[index]
                    viewModel.deleteSchedule(id: schedule.id)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Schedule Row

    /// 목록에서 하나의 일정을 표시하는 행
    private func scheduleRow(_ schedule: Schedule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 제목
            Text(schedule.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(HiTripColor.textBlack)

            // 날짜
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                Text(schedule.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13))
            }
            .foregroundColor(HiTripColor.gray500)

            // 장소 (있을 때만)
            if !schedule.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                    Text(schedule.location)
                        .font(.system(size: 13))
                }
                .foregroundColor(HiTripColor.gray400)
            }
        }
        .padding(.vertical, 4)
    }
}
