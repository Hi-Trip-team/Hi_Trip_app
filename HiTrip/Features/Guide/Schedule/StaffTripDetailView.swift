import SwiftUI

// MARK: - StaffTripDetailView
/// 전체일정 확인·수정 (안내사) — Figma 12381:5209
///
/// 일차 아코디언 + ⋮ 메뉴(시간 변경·메모 수정·삭제) + 일정 추가.
/// 수정은 즉시 서버에 저장하고, 실패하면 [재시도]를 띄웁니다.
///
/// 앱에서는 당일 운영 조정(시간·메모)만 다룹니다.
/// 장소 변경·일정 신규 구성은 SaaS 권장 — 서버가 장소를 place_id로만 받습니다.

struct StaffTripDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StaffTripDetailViewModel()

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
                sheetOverlay
            }
        }
        .overlay(alignment: .bottom) { toastView }
        .animation(.easeInOut(duration: 0.2), value: showSheet)
        .navigationBarHidden(true)
        .task { viewModel.load() }
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
        ZStack {
            Text("전체 일정")
                .font(AppFont.headlineBold)
                .foregroundColor(.black)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(AppFont.title3Medium)
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
            .padding(.leading, AppSpacing.sm)
        }
        .frame(height: 24)
        .padding(.top, AppSpacing.xs)
    }

    // MARK: - 본문

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                tripSummary
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, 33)
                    .padding(.bottom, AppSpacing.lg)

                ForEach(viewModel.days) { day in
                    daySection(day)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.md)
                }

                Spacer().frame(height: 32)
            }
        }
        .refreshable { viewModel.refresh() }
    }

    /// 여행 요약 — SaaS 등록값, 읽기 전용
    private var tripSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(viewModel.tripTitle)
                .font(AppFont.bodyMBold)
                .foregroundColor(AppColor.textPrimary)
            Text(viewModel.tripSubtitle)
                .font(AppFont.caption)
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 72, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - 일차

    private func daySection(_ day: StaffTripDetailViewModel.DaySection) -> some View {
        let isExpanded = viewModel.expandedDay == day.dayNumber

        return VStack(spacing: AppSpacing.sm) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggle(day: day.dayNumber) } } label: {
                HStack(spacing: 10) {
                    Text("\(day.dayNumber)일차")
                        .font(AppFont.captionBold)
                        .foregroundColor(isExpanded ? .white : AppColor.textSecondary)
                        .frame(width: 48, height: 24)
                        .background(isExpanded ? AppColor.accent : AppColor.divider)
                        .cornerRadius(AppRadius.xs)

                    Text(day.date)
                        .font(AppFont.labelMedium)
                        .foregroundColor(isExpanded ? AppColor.textPrimary : AppColor.textSecondary)

                    Spacer()

                    Text(isExpanded ? "∧" : "∨")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(isExpanded ? AppColor.accentSubtle : AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .buttonStyle(.plain)

            if isExpanded {
                if day.items.isEmpty {
                    Text("등록된 일정이 없어요")
                        .font(AppFont.label)
                        .foregroundColor(AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(AppColor.surfaceSubtle)
                        .cornerRadius(AppRadius.lg)
                }

                ForEach(day.items, id: \.id) { item in
                    scheduleRow(item)
                }

                addButton(day: day.dayNumber)
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
    }

    private func addButton(day: Int) -> some View {
        Button { openAddSheet(day: day) } label: {
            Text("+ 일정 추가")
                .font(AppFont.labelMedium)
                .foregroundColor(AppColor.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .strokeBorder(AppColor.textSecondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 시트

    private var sheetOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { closeSheet() }

            VStack(spacing: 0) {
                Spacer()
                sheetCard
                    .transition(.move(edge: .bottom))
            }
            .ignoresSafeArea(edges: .bottom)
            .zIndex(1)
        }
    }

    private var sheetCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColor.divider)
                    .frame(width: 52, height: 5)
                Spacer()
            }
            .padding(.top, 10)

            Text(sheetTitle)
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.top, 22)
                .padding(.bottom, AppSpacing.md)

            if needsTitleField {
                Text(isMemoMode ? "메모" : "제목")
                    .font(AppFont.captionMedium)
                    .foregroundColor(AppColor.textSecondary)

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

            if needsTimeFields {
                Text("시간")
                    .font(AppFont.captionMedium)
                    .foregroundColor(AppColor.textSecondary)

                HStack(spacing: AppSpacing.sm) {
                    timeField("시작", value: hhmm(draftStart), field: .start)
                    timeField("종료", value: hhmm(draftEnd), field: .end)
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

            Button { submit() } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("저장")
                            .font(AppFont.bodyLBold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canSubmit ? AppColor.accent : AppColor.borderMuted)
                .cornerRadius(AppRadius.lg)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, 34)
        }
        .padding(.horizontal, AppSpacing.xl)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

    private func timeField(_ prefix: String, value: String, field: TimeField) -> some View {
        Button { openPicker = (openPicker == field) ? nil : field } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(prefix)
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
                Text(value)
                    .font(AppFont.bodyMedium)
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppColor.surface)
            .cornerRadius(AppRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(openPicker == field ? AppColor.accent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

    private var isEndBeforeStart: Bool { hhmm(draftEnd) <= hhmm(draftStart) }

    private var hasOverlap: Bool {
        guard needsTimeFields, !isEndBeforeStart else { return false }
        switch sheetMode {
        case .add(let day):
            return viewModel.overlaps(dayNumber: day, start: hhmm(draftStart), end: hhmm(draftEnd))
        case .time(let item):
            return viewModel.overlaps(
                dayNumber: item.dayNumber,
                start: hhmm(draftStart), end: hhmm(draftEnd),
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
            return !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty && !isEndBeforeStart
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
        draftStart = Self.time(hour: 9)
        draftEnd = Self.time(hour: 10)
        openPicker = nil
        showSheet = true
        focusTextSoon()
    }

    private func openTimeSheet(_ item: StaffScheduleDTO) {
        sheetMode = .time(item)
        draftStart = Self.time(from: item.startTime)
        draftEnd = Self.time(from: item.endTime)
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
            viewModel.addSchedule(
                dayNumber: day,
                title: draftTitle.trimmingCharacters(in: .whitespaces),
                start: hhmm(draftStart), end: hhmm(draftEnd)
            ) { closeSheet() }

        case .time(let item):
            viewModel.updateTime(item, start: hhmm(draftStart), end: hhmm(draftEnd)) { closeSheet() }

        case .memo(let item):
            viewModel.updateMemo(item, content: draftTitle) { closeSheet() }
        }
    }

    private func closeSheet() {
        isTextFocused = false
        showSheet = false
        openPicker = nil
        draftTitle = ""
    }

    // MARK: - 시각 헬퍼

    private func hhmm(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private static func time(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private static func time(from text: String) -> Date {
        let parts = text.split(separator: ":")
        let h = parts.count >= 2 ? Int(parts[0]) ?? 9 : 9
        let m = parts.count >= 2 ? Int(parts[1]) ?? 0 : 0
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
    }

    // MARK: - 상태 화면

    private var loadingView: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
            Text("일정을 불러오는 중이에요")
                .font(AppFont.label)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
            Button { viewModel.load() } label: {
                Text("재시도")
                    .font(AppFont.bodyBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .frame(height: 44)
                    .background(AppColor.accent)
                    .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast = viewModel.toast {
            Text(toast)
                .font(AppFont.labelMedium)
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(AppColor.textPrimary.opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 40)
                .task(id: toast) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    viewModel.toast = nil
                }
        }
    }
}
