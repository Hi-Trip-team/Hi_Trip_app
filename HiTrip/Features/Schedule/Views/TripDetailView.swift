import SwiftUI

struct TripDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TripScheduleViewModel()

    @State private var showAddSheet = false
    @State private var addDayNumber: Int?
    @State private var addTitle = ""
    @State private var addMemo = ""
    @State private var addStart = "20:00"
    @State private var addEnd = "21:00"

    private let titleLimit = 20
    private let memoLimit = 100

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

            if showAddSheet {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { closeSheet() }

                VStack(spacing: 0) {
                    Spacer()
                    addScheduleSheet
                        .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showAddSheet)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .alert("저장하지 못했습니다", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.saveError = nil }
        } message: {
            Text(viewModel.saveError ?? "")
        }
        .alert("일정이 겹칩니다", isPresented: Binding(
            get: { viewModel.overlapNotice != nil },
            set: { if !$0 { viewModel.overlapNotice = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.overlapNotice = nil }
        } message: {
            Text(viewModel.overlapNotice ?? "")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("여행 일정")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .padding(.top, 8)
    }

    // MARK: - 로딩 / 에러

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
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 34))
                .foregroundColor(Color(hex: "#D1D5DB"))
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
                .multilineTextAlignment(.center)
            Button { viewModel.load() } label: {
                Text("다시 시도")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 본문

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                tripInfoCard
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                todaySection

                if viewModel.days.isEmpty {
                    Text("등록된 일정이 없습니다")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.days) { day in
                        daySection(day)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 14)
                    }
                }

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: - 여행 정보 카드

    private var tripInfoCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#D9DEE5"))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "suitcase")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.tripTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                Text("진행일자 \(viewModel.tripPeriod)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
    }

    // MARK: - 오늘의 일정

    /// 오늘 날짜에 해당하는 일정이 있을 때만 표시합니다.
    /// 출발 전이거나 이미 끝난 여행이면 이 섹션 자체가 없습니다.
    @ViewBuilder
    private var todaySection: some View {
        if viewModel.isTripToday {
            VStack(alignment: .leading, spacing: 0) {
                Text("오늘의 일정")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.bottom, 12)

                // 오늘 일정 전체 구간의 경과 비율
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#E5E7EB"))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#2563EB"))
                            .frame(width: geo.size.width * viewModel.todayProgress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.bottom, 14)

                if let current = viewModel.todayCurrentSchedule {
                    HStack {
                        Text(current.placeName ?? current.mainContent ?? "일정")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#111827"))
                        Spacer()
                        Text(TripScheduleViewModel.timeRange(current.startTime, current.endTime))
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
                } else {
                    Text("오늘 일정이 모두 끝났어요")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 일차 섹션

    private func daySection(_ day: TripScheduleViewModel.DaySection) -> some View {
        let isExpanded = viewModel.expandedDay == day.dayNumber

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.expandedDay = isExpanded ? nil : day.dayNumber
                }
            } label: {
                HStack(spacing: 10) {
                    // 펼친 일차만 파란 칩, 나머지는 회색
                    Text("\(day.dayNumber)일차")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isExpanded ? .white : Color(hex: "#6B7280"))
                        .frame(width: 48, height: 24)
                        .background(isExpanded ? Color(hex: "#2563EB") : Color(hex: "#E5E7EB"))
                        .cornerRadius(6)

                    Text(day.date.replacingOccurrences(of: "-", with: "."))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isExpanded ? Color(hex: "#111827") : Color(hex: "#6B7280"))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(isExpanded ? Color(hex: "#E8F0FF") : Color(hex: "#F3F4F6"))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(day.items) { item in
                        switch item {
                        case .shared(let s):   sharedRow(s)
                        case .personal(let p): personalRow(p)
                        }
                    }

                    addPersonalButton(dayNumber: day.dayNumber)
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - 공용 일정 행

    private func sharedRow(_ s: TravelerScheduleDTO) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EF4444"))
                    Text(s.placeName ?? s.mainContent ?? "일정")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#111827"))
                }

                if let address = s.placeAddress, !address.isEmpty {
                    Text(address)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(1)
                }

                Text(TripScheduleViewModel.timeRange(s.startTime, s.endTime))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))

                if let content = s.mainContent, !content.isEmpty, content != s.placeName {
                    Text(content)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#374151"))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            SpotImageView(imageUrl: nil, categoryName: s.transport, iconSize: 20)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
        )
    }

    // MARK: - 개인 일정 행

    private func personalRow(_ p: TravelerPersonalScheduleDTO) -> some View {
        HStack(spacing: 10) {
            Text("내 일정")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#2563EB"))
                .frame(width: 52, height: 22)
                .background(Color(hex: "#E8F0FF"))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(p.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                if let memo = p.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(TripScheduleViewModel.timeRange(p.startTime, p.endTime))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
                if p.overlapWarning {
                    Text("겹침")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#EB8C0D"))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: "#2563EB"), style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deletePersonalSchedule(id: p.id)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - 개인 일정 추가 버튼

    private func addPersonalButton(dayNumber: Int) -> some View {
        Button {
            addDayNumber = dayNumber
            showAddSheet = true
        } label: {
            Text("+ 개인 일정 추가")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#2563EB"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: "#6B7280"), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 개인 일정 추가 시트

    private var addScheduleSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(width: 52, height: 5)
                Spacer()
            }
            .padding(.top, 10)

            Text("개인 일정 추가")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 16)

            // 제목
            VStack(alignment: .leading, spacing: 6) {
                Text("제목")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.horizontal, 24)

                // 입력 중에는 자르지 않습니다. 한국어·일본어·중국어는 여러 타를
                // 조합해 한 글자를 만들기 때문에, 조합 중 바인딩을 덮어쓰면 입력이 깨집니다.
                // 대신 초과분을 카운터에 빨간색으로 표시하고 저장을 막습니다.
                TextField("예: 기념품 쇼핑", text: $addTitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTitleOverLimit ? Color(hex: "#EF4444") : Color.clear, lineWidth: 1)
                            .padding(.horizontal, 24)
                    )
                    .padding(.horizontal, 24)

                HStack {
                    Spacer()
                    Text("\(addTitle.count)/\(titleLimit)")
                        .font(.system(size: 11, weight: isTitleOverLimit ? .bold : .regular))
                        .foregroundColor(isTitleOverLimit ? Color(hex: "#EF4444") : Color(hex: "#9CA3AF"))
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            // 시간
            VStack(alignment: .leading, spacing: 6) {
                Text("시간")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    timeField(prefix: "시작", value: $addStart)
                    timeField(prefix: "종료", value: $addEnd)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            // 메모
            VStack(alignment: .leading, spacing: 4) {
                TextField("메모 (선택 · \(memoLimit)자)", text: $addMemo)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isMemoOverLimit ? Color(hex: "#EF4444") : Color.clear, lineWidth: 1)
                    )

                if isMemoOverLimit {
                    HStack {
                        Spacer()
                        Text("\(addMemo.count)/\(memoLimit)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#EF4444"))
                    }
                }
            }
            .padding(.horizontal, 24)

            // 저장
            Button { save() } label: {
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
                .background(canSave ? Color(hex: "#2563EB") : Color(hex: "#C3CDDA"))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!canSave || viewModel.isSaving)
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

    private func timeField(prefix: String, value: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Text(prefix)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
            TextField("00:00", text: value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
                .keyboardType(.numbersAndPunctuation)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
    }

    // MARK: - 동작

    private var isTitleOverLimit: Bool { addTitle.count > titleLimit }
    private var isMemoOverLimit: Bool { addMemo.count > memoLimit }

    private var canSave: Bool {
        !addTitle.trimmingCharacters(in: .whitespaces).isEmpty
            && !isTitleOverLimit
            && !isMemoOverLimit
            && isValidTime(addStart)
            && isValidTime(addEnd)
            && addStart < addEnd
    }

    /// "HH:mm" 형식이고 실제 시각인지
    private func isValidTime(_ text: String) -> Bool {
        let parts = text.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              (0...23).contains(h), (0...59).contains(m) else { return false }
        return true
    }

    private func save() {
        guard let day = addDayNumber else { return }
        viewModel.addPersonalSchedule(
            dayNumber: day,
            title: addTitle.trimmingCharacters(in: .whitespaces),
            start: addStart,
            end: addEnd,
            memo: addMemo.isEmpty ? nil : addMemo
        )
        closeSheet()
    }

    private func closeSheet() {
        showAddSheet = false
        addTitle = ""
        addMemo = ""
        addStart = "20:00"
        addEnd = "21:00"
    }
}

// MARK: - 특정 모서리만 둥글게

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
