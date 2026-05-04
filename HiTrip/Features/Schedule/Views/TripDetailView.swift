import SwiftUI

// MARK: - TripDetailView
/// 화면2+3 컨테이너: 여행 상세
///
/// 피그마 디자인:
/// - 뒤로가기(←) + 더보기(...)
/// - 주간 캘린더 스트립 (흰색 카드, radius 24) — 탭 공용
/// - "내 일정 | 할일" 세그먼트 탭 (인디케이터 3px, radius 10)
/// - 내 일정 탭: 여행 카드 리스트 (썸네일 + 날짜 + 제목 + 위치)
/// - 할일 탭: 체크리스트 (TripTodoView)

struct TripDetailView: View {

    @StateObject var viewModel: TripDetailViewModel
    @Environment(\.dismiss) var dismiss

    private let initialTab: TripDetailViewModel.DetailTab

    init(trip: Trip, initialTab: TripDetailViewModel.DetailTab = .mySchedule) {
        _viewModel = StateObject(wrappedValue: TripDetailViewModel(trip: trip))
        self.initialTab = initialTab
    }

    var body: some View {
        VStack(spacing: 0) {
            // 주간 캘린더 스트립 — 양 탭 공용
            calendarCard
                .padding(.top, 12)
                .padding(.horizontal, 20)

            // "내 일정 | 할일" 탭 셀렉터
            tabSelector
                .padding(.top, 16)

            // 탭 콘텐츠
            tabContent
        }
        .background(HiTripColor.screenBackground)
        .onAppear { viewModel.selectedTab = initialTab }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
    }

    // MARK: - Calendar Card (탭 공용)

    /// 주간 캘린더 카드 — 흰색 배경, radius 16, 디자인 스펙 shadow
    private var calendarCard: some View {
        WeekCalendarStripView(
            selectedDate: $viewModel.selectedDate,
            style: .sundayStart
        )
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(hex: "B4BCC9").opacity(0.12), radius: 12, x: 0, y: 4)
    }

    // MARK: - Tab Selector

    /// "내 일정 | 할일" 세그먼트 탭
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(TripDetailViewModel.DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(
                                viewModel.selectedTab == tab
                                    ? HiTripColor.textBlack
                                    : HiTripColor.gray400
                            )

                        // 하단 인디케이터 라인 (3px, radius 10, 검정)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.selectedTab == tab ? HiTripColor.textBlack : Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .mySchedule:
            MyScheduleListView(viewModel: viewModel)
        case .todo:
            TripTodoView(viewModel: viewModel)
        }
    }
}
