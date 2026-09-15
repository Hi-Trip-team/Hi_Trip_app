import SwiftUI

// MARK: - StaffTripDetailView
/// 전체일정 확인·수정 (안내사) — Figma 12381:5209
///
/// 일차 아코디언 + ⋮ 메뉴(시간 변경·메모 수정·삭제) + 일정 추가.
/// 수정은 즉시 서버에 저장하고, 실패하면 [재시도]를 띄웁니다.
///
/// 일정 추가 때 장소를 카카오에서 검색해 지정할 수 있습니다 (adopt → place_id, SaaS와 같은 흐름).
/// 기존 일정의 장소 변경은 SaaS에서 합니다.
///
/// 여행 카드·일차 머리·빈 일차·추가 버튼·시트는 여행객 "여행 일정"과 같은 공통 부품입니다.

struct StaffTripDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: StaffTripDetailViewModel

    /// - Parameter focusDay: 처음 펼칠 일차 — nil이면 여행 중일 때 오늘 일차
    init(focusDay: Int? = nil) {
        _viewModel = StateObject(wrappedValue: StaffTripDetailViewModel(focusDay: focusDay))
    }

    /// ⋮ 메뉴 대상
    @State private var menuTarget: StaffScheduleDTO?
    /// 삭제 확인 대상
    @State private var deleteTarget: StaffScheduleDTO?

    /// 시트 상태
    @State private var showSheet = false
    @State private var sheetMode: SheetMode = .add(day: 1)
    @State private var draftTitle = ""
    @State private var draftStart = Date()
    @State private var draftEnd = Date()
    @State private var openPicker: TimeField?
    /// 장소 지정 (일정 추가만) — 카카오 검색 → 서버 장소 등록
    @State private var placeQuery = ""
    @State private var selectedPlace: KakaoPlaceResultDTO?

    private enum SheetMode: Equatable {
        case add(day: Int)
        case time(StaffScheduleDTO)
        case memo(StaffScheduleDTO)

        static func == (l: SheetMode, r: SheetMode) -> Bool {
            switch (l, r) {
            case let (.add(a), .add(b)):   return a == b
            case let (.time(a), .time(b)): return a.id == b.id
            case let (.memo(a), .memo(b)): return a.id == b.id
            default: return false
            }
        }
    }

    private enum TimeField { case start, end }

    /// 제목·메모 입력 포커스
    ///
    /// 딤 위에 겹쳐 띄우는 시트라 TextField가 탭만으로는 포커스를 잡지 못했습니다.
    /// 시트를 열 때 직접 포커스를 줍니다.
    @FocusState private var isTextFocused: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection

                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case .failed(let message):
                    errorView(message)
                case .loaded:
                    content
                }
            }
            .background(Color.white)

            if showSheet {
                BottomSheetOverlay(onDismissRequest: closeSheet) { keyboardVisible in
                    sheetCard(isKeyboardVisible: keyboardVisible)
                }
            }
        }
        .toast($viewModel.toast)
        .animation(.easeInOut(duration: 0.25), value: showSheet)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        // 일정을 누르면 여행객과 같은 장소 상세
        .navigationDestination(unwrapping: $viewModel.selectedPlace) { place in
            NearbySpotDetailView(
                name: place.name,
                address: place.address,
                description: place.tourOverview,
                imageUrl: place.imageUrl,
                latitude: place.latitude.flatMap(Double.init),
                longitude: place.longitude.flatMap(Double.init),
                categoryName: place.kakaoCategory
            )
        }
        .confirmationDialog(
            "일정",
            isPresented: Binding(get: { menuTarget != nil }, set: { if !$0 { menuTarget = nil } }),
            titleVisibility: .hidden
        ) {
            Button("시간 변경") { if let t = menuTarget { openTimeSheet(t) }; menuTarget = nil }
            Button("메모 수정") { if let t = menuTarget { openMemoSheet(t) }; menuTarget = nil }
            Button("삭제", role: .destructive) { deleteTarget = menuTarget; menuTarget = nil }
            Button("취소", role: .cancel) { menuTarget = nil }
        }
        .confirmationDialog(
            "이 일정을 삭제할까요?",
            isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let target = deleteTarget { viewModel.delete(target) }
                deleteTarget = nil
            }
            Button("취소", role: .cancel) { deleteTarget = nil }
        }
        .alert("저장하지 못했어요", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            Button("재시도") { viewModel.saveError = nil; submit() }
            Button("닫기", role: .cancel) { viewModel.saveError = nil }
        } message: {
            Text(viewModel.saveError ?? "")
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        NavigationHeader(title: "전체 일정") { dismiss() }
    }

    // MARK: - 본문

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    TripInfoCard(title: viewModel.tripTitle, subtitle: viewModel.tripSubtitle)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)

                    ForEach(viewModel.days) { day in
                        daySection(day)
                            .padding(.horizontal, AppSpacing.xl)
                            .padding(.bottom, 14)
                            .id(day.dayNumber)
                    }

                    Spacer().frame(height: 32)
                }
            }
            .refreshable { viewModel.refresh() }
            // 펼친 일차(홈에서 누른 일정의 일차 / 오늘)가 화면 아래에 있어도 보이도록 스크롤합니다
            .onAppear { scrollToExpandedDay(proxy) }
            .onChange(of: viewModel.days.count) { _ in scrollToExpandedDay(proxy) }
        }
    }

    private func scrollToExpandedDay(_ proxy: ScrollViewProxy) {
        guard let day = viewModel.expandedDay else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(day, anchor: .top) }
        }
    }

    // MARK: - 일차

    private func daySection(_ day: StaffTripDetailViewModel.DaySection) -> some View {
        let isExpanded = viewModel.expandedDay == day.dayNumber

        return VStack(spacing: 0) {
            DayAccordionHeader(dayNumber: day.dayNumber, date: day.date, isExpanded: isExpanded) {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggle(day: day.dayNumber) }
            }

            if isExpanded {
                VStack(spacing: AppSpacing.sm) {
                    if day.items.isEmpty { EmptyDayRow() }

                    ForEach(day.items, id: \.id) { item in
                        scheduleRow(item)
                    }

                    DashedAddButton(title: "+ 일정 추가") { openAddSheet(day: day.dayNumber) }
                }
                .padding(.top, AppSpacing.sm)
            }
        }
    }

    private func scheduleRow(_ item: StaffScheduleDTO) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(StaffTripDetailViewModel.title(of: item))
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)

                Text(StaffTripDetailViewModel.timeRange(item.startTime, item.endTime))
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            Button { menuTarget = item } label: {
                Text("⋮")
                    .font(AppFont.bodyLBold)
                    .foregroundColor(AppColor.textSecondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 60)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.divider, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { viewModel.openPlace(of: item) }
    }

    // MARK: - 시트

    private func sheetCard(isKeyboardVisible: Bool) -> some View {
        BottomSheetCard(title: sheetTitle) {
            VStack(alignment: .leading, spacing: 0) {
                if needsTitleField {
                    SheetFieldLabel(isMemoMode ? "메모" : "제목")

                    TextField(isMemoMode ? "메모를 입력하세요" : "예: 자유시간", text: $draftTitle)
                        .focused($isTextFocused)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 48)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.lg)
                        .padding(.top, 6)
                        .padding(.bottom, AppSpacing.sm)
                }

                if case .add = sheetMode {
                    placeSection
                }

                if needsTimeFields {
                    SheetFieldLabel("시간")

                    HStack(spacing: AppSpacing.sm) {
                        timeField("시작", value: AppDate.hhmm(draftStart), field: .start)
                        timeField("종료", value: AppDate.hhmm(draftEnd), field: .end)
                    }
                    .padding(.top, 6)

                    if let field = openPicker {
                        DatePicker(
                            "",
                            selection: field == .start ? $draftStart : $draftEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 140)
                    }

                    if isEndBeforeStart {
                        Text("종료 시간이 시작 시간보다 빠릅니다")
                            .font(AppFont.caption2)
                            .foregroundColor(AppColor.danger)
                            .padding(.top, 6)
                    } else if hasOverlap {
                        Text("기존 일정과 시간이 겹칩니다")
                            .font(AppFont.caption2)
                            .foregroundColor(AppColor.warning)
                            .padding(.top, 6)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            SheetPrimaryButton(
                isEnabled: canSubmit,
                isLoading: viewModel.isSaving,
                isKeyboardVisible: isKeyboardVisible,
                action: submit
            )
        }
    }

    private func timeField(_ prefix: String, value: String, field: TimeField) -> some View {
        SheetTimeField(prefix: prefix, value: value, isActive: openPicker == field) {
            openPicker = (openPicker == field) ? nil : field
        }
    }

    // MARK: - 장소 (선택)

    /// SaaS와 같은 흐름 — 카카오에서 검색해 고르면 저장할 때 서버 장소로 등록합니다
    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SheetFieldLabel("장소 (선택)")

            if let place = selectedPlace {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(AppColor.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.placeName)
                            .font(AppFont.bodyMedium)
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(1)
                        Text(place.addressText)
                            .font(AppFont.caption2)
                            .foregroundColor(AppColor.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button { selectedPlace = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 52)
                .background(AppColor.accentSubtle)
                .cornerRadius(AppRadius.lg)
            } else {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColor.textSecondary)
                    TextField("장소 검색 (2자 이상)", text: $placeQuery)
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textPrimary)
                        .submitLabel(.search)
                        .onSubmit { viewModel.searchPlaces(placeQuery) }
                    if viewModel.isSearchingPlace {
                        ProgressView()
                    } else if placeQuery.trimmingCharacters(in: .whitespaces).count >= 2 {
                        Button("검색") { viewModel.searchPlaces(placeQuery) }
                            .font(AppFont.labelMedium)
                            .foregroundColor(AppColor.accent)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 48)
                .background(AppColor.surface)
                .cornerRadius(AppRadius.lg)

                if !viewModel.placeResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.placeResults) { place in
                                Button {
                                    selectedPlace = place
                                    viewModel.clearPlaceResults()
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(place.placeName)
                                            .font(AppFont.labelMedium)
                                            .foregroundColor(AppColor.textPrimary)
                                        Text(place.addressText)
                                            .font(AppFont.caption2)
                                            .foregroundColor(AppColor.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, AppSpacing.xs)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .frame(maxHeight: 160)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColor.divider, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - 시트 상태

    private var sheetTitle: String {
        switch sheetMode {
        case .add:  return "일정 추가"
        case .time: return "시간 변경"
        case .memo: return "메모 수정"
        }
    }

    private var isMemoMode: Bool { if case .memo = sheetMode { return true }; return false }
    private var needsTitleField: Bool { if case .time = sheetMode { return false }; return true }
    private var needsTimeFields: Bool { if case .memo = sheetMode { return false }; return true }

    private var isEndBeforeStart: Bool { AppDate.hhmm(draftEnd) <= AppDate.hhmm(draftStart) }

    private var hasOverlap: Bool {
        guard needsTimeFields, !isEndBeforeStart else { return false }
        switch sheetMode {
        case .add(let day):
            return viewModel.overlaps(dayNumber: day, start: AppDate.hhmm(draftStart), end: AppDate.hhmm(draftEnd))
        case .time(let item):
            return viewModel.overlaps(
                dayNumber: item.dayNumber,
                start: AppDate.hhmm(draftStart), end: AppDate.hhmm(draftEnd),
                excluding: item.id
            )
        case .memo:
            return false
        }
    }

    private var canSubmit: Bool {
        if viewModel.isSaving { return false }
        switch sheetMode {
        case .add:
            // 제목이 없어도 장소를 골랐으면 장소명이 제목이 됩니다
            let hasTitle = !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty || selectedPlace != nil
            return hasTitle && !isEndBeforeStart
        case .time:
            return !isEndBeforeStart
        case .memo:
            return true
        }
    }

    // MARK: - 시트 동작

    private func openAddSheet(day: Int) {
        sheetMode = .add(day: day)
        draftTitle = ""
        draftStart = AppDate.today(hour: 9)
        draftEnd = AppDate.today(hour: 10)
        openPicker = nil
        showSheet = true
        focusTextSoon()
    }

    private func openTimeSheet(_ item: StaffScheduleDTO) {
        sheetMode = .time(item)
        draftStart = AppDate.today(hhmm: item.startTime, fallbackHour: 9)
        draftEnd = AppDate.today(hhmm: item.endTime, fallbackHour: 9)
        openPicker = nil
        showSheet = true
    }

    private func openMemoSheet(_ item: StaffScheduleDTO) {
        sheetMode = .memo(item)
        draftTitle = item.mainContent ?? ""
        openPicker = nil
        showSheet = true
        focusTextSoon()
    }

    /// 시트가 올라온 뒤에 포커스를 줘야 키보드가 뜹니다
    private func focusTextSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isTextFocused = true }
    }

    private func submit() {
        guard canSubmit else { return }
        switch sheetMode {
        case .add(let day):
            let title = draftTitle.trimmingCharacters(in: .whitespaces)
            viewModel.addSchedule(
                dayNumber: day,
                title: title.isEmpty ? (selectedPlace?.placeName ?? "") : title,
                start: AppDate.hhmm(draftStart), end: AppDate.hhmm(draftEnd),
                place: selectedPlace, placeQuery: placeQuery
            ) { closeSheet() }

        case .time(let item):
            viewModel.updateTime(item, start: AppDate.hhmm(draftStart), end: AppDate.hhmm(draftEnd)) { closeSheet() }

        case .memo(let item):
            viewModel.updateMemo(item, content: draftTitle) { closeSheet() }
        }
    }

    private func closeSheet() {
        isTextFocused = false
        showSheet = false
        openPicker = nil
        draftTitle = ""
        placeQuery = ""
        selectedPlace = nil
        viewModel.clearPlaceResults()
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        SkeletonList(rows: 5)
    }

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) { viewModel.load() }
    }

}
