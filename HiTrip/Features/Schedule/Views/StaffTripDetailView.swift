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
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                Spacer()
            }
            .padding(.leading, 12)
        }
        .frame(height: 24)
        .padding(.top, 8)
    }

    // MARK: - 본문

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                tripSummary
                    .padding(.horizontal, 24)
                    .padding(.top, 33)
                    .padding(.bottom, 20)

                ForEach(viewModel.days) { day in
                    daySection(day)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }

                Spacer().frame(height: 32)
            }
        }
        .refreshable { viewModel.refresh() }
    }

    /// 여행 요약 — SaaS 등록값, 읽기 전용
    private var tripSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.tripTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            Text(viewModel.tripSubtitle)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .padding(.horizontal, 16)
        .frame(height: 72, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#F3F4F6"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 일차

    private func daySection(_ day: StaffTripDetailViewModel.DaySection) -> some View {
        let isExpanded = viewModel.expandedDay == day.dayNumber

        return VStack(spacing: 12) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggle(day: day.dayNumber) } } label: {
                HStack(spacing: 10) {
                    Text("\(day.dayNumber)일차")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isExpanded ? .white : Color(hex: "#6B7280"))
                        .frame(width: 48, height: 24)
                        .background(isExpanded ? Color(hex: "#2563EB") : Color(hex: "#E5E7EB"))
                        .cornerRadius(6)

                    Text(day.date)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isExpanded ? Color(hex: "#111827") : Color(hex: "#6B7280"))

                    Spacer()

                    Text(isExpanded ? "∧" : "∨")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(isExpanded ? Color(hex: "#E8F0FF") : Color(hex: "#F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if isExpanded {
                if day.items.isEmpty {
                    Text("등록된 일정이 없어요")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(hex: "#F9FAFB"))
                        .cornerRadius(12)
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                    .lineLimit(1)

                Text(StaffTripDetailViewModel.timeRange(item.startTime, item.endTime))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }

            Spacer()

            Button { menuTarget = item } label: {
                Text("⋮")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
        )
    }

    private func addButton(day: Int) -> some View {
        Button { openAddSheet(day: day) } label: {
            Text("+ 일정 추가")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#2563EB"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(hex: "#F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: "#6B7280"), style: StrokeStyle(lineWidth: 1, dash: [4]))
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
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(width: 52, height: 5)
                Spacer()
            }
            .padding(.top, 10)

            Text(sheetTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.top, 22)
                .padding(.bottom, 16)

            if needsTitleField {
                Text(isMemoMode ? "메모" : "제목")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))

                TextField(isMemoMode ? "메모를 입력하세요" : "예: 자유시간", text: $draftTitle)
                    .focused($isTextFocused)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
            }

            if needsTimeFields {
                Text("시간")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))

                HStack(spacing: 12) {
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
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.top, 6)
                } else if hasOverlap {
                    Text("기존 일정과 시간이 겹칩니다")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EB8C0D"))
                        .padding(.top, 6)
                }
            }

            Button { submit() } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("저장")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canSubmit ? Color(hex: "#2563EB") : Color(hex: "#C3CDDA"))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .padding(.top, 20)
            .padding(.bottom, 34)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

    private func timeField(_ prefix: String, value: String, field: TimeField) -> some View {
        Button { openPicker = (openPicker == field) ? nil : field } label: {
            HStack(spacing: 8) {
                Text(prefix)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "#F3F4F6"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(openPicker == field ? Color(hex: "#2563EB") : .clear, lineWidth: 1)
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
        VStack(spacing: 12) {
            ProgressView()
            Text("일정을 불러오는 중이에요")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Button { viewModel.load() } label: {
                Text("재시도")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast = viewModel.toast {
            Text(toast)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Color(hex: "#111827").opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 40)
                .task(id: toast) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    viewModel.toast = nil
                }
        }
    }
}
