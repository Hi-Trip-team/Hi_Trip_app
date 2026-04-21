import SwiftUI

// MARK: - TripDetailView
/// 화면2+3 컨테이너: 여행 상세
///
/// 피그마 디자인:
/// - 뒤로가기 + 더보기(...)
/// - 멤버 아바타 영역 + 추가 버튼
/// - "할일 | 캘린더" 세그먼트 탭
/// - 탭에 따라 TripTodoView 또는 TripCalendarView 표시
///
/// 화면1(TripListView)에서 NavigationLink로 push되어 진입

struct TripDetailView: View {

    @StateObject var viewModel: TripDetailViewModel
    @Environment(\.dismiss) var dismiss

    private let initialTab: TripDetailViewModel.DetailTab

    init(trip: Trip, initialTab: TripDetailViewModel.DetailTab = .todo) {
        _viewModel = StateObject(wrappedValue: TripDetailViewModel(trip: trip))
        self.initialTab = initialTab
    }

    var body: some View {
        VStack(spacing: 0) {
            // 멤버 아바타 영역
            memberSection
                .padding(.top, 12)

            // 할일 / 캘린더 탭
            tabSelector
                .padding(.top, 16)

            // 탭 콘텐츠
            tabContent
        }
        .background(HiTripColor.screenBackground)
        .onAppear { viewModel.selectedTab = initialTab }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(HiTripColor.textBlack)
                }
            }
        }
    }

    // MARK: - Member Section

    /// 멤버 아바타 원형 + 추가 버튼
    private var memberSection: some View {
        HStack(spacing: -8) {
            // 멤버 아바타들 (겹쳐서 표시)
            ForEach(0..<min(viewModel.trip.memberAvatars.count, 3), id: \.self) { index in
                Circle()
                    .fill(memberColor(index))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
            }

            // + 추가 버튼
            Button { } label: {
                Circle()
                    .fill(HiTripColor.gray100)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(HiTripColor.gray400)
                    )
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    /// 멤버별 색상 (피그마 기준 파란 그라데이션)
    private func memberColor(_ index: Int) -> Color {
        let colors = [HiTripColor.primary800, HiTripColor.secondary500, HiTripColor.secondary200]
        return colors[index % colors.count]
    }

    // MARK: - Tab Selector

    /// "할일 | 캘린더" 세그먼트 탭
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

                        // 하단 인디케이터 라인
                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? HiTripColor.primary800 : Color.clear)
                            .frame(height: 2)
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
        case .todo:
            TripTodoView(viewModel: viewModel)
        case .calendar:
            TripCalendarView(viewModel: viewModel)
        }
    }
}
