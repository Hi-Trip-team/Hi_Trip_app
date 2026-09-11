import SwiftUI

struct TripDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TripScheduleViewModel()

    @State private var showAddSheet = false
    @State private var addDayNumber: Int?
    @State private var addTitle = ""
    @State private var addMemo = ""
    /// 휠 피커가 다루는 값. 문자열 addStart/addEnd는 여기서 파생됩니다.
    @State private var startDate = TripDetailView.defaultTime(hour: 20)
    @State private var endDate   = TripDetailView.defaultTime(hour: 21)
    /// 수정 중인 개인 일정 id — nil이면 새로 추가
    @State private var editingId: Int?

    /// 어떤 시간 피커를 펼쳐 두었는지
    @State private var openPicker: TimeField?
    /// 스와이프로 열려 있는 개인 일정 id
    @State private var swipedId: Int?
    /// 설명을 펼친 공용 일정 id
    @State private var expandedDescriptions: Set<Int> = []
    /// 작성 중 닫기 확인
    @State private var showDiscardConfirm = false
    /// 일정 카드 탭 → 스팟 상세
    @State private var selectedSchedule: SchedulePlace?
    /// 삭제 확인 대기 중인 개인 일정
    @State private var pendingDelete: TravelerPersonalScheduleDTO?

    private enum TimeField { case start, end }

    /// 일정 카드에서 스팟 상세로 넘길 장소 정보
    private struct SchedulePlace: Identifiable, Hashable {
        let id: Int
        let name: String
        let address: String?
        let description: String?
        let latitude: Double?
        let longitude: Double?
        let categoryName: String?
    }

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
                DimmedBackground { requestCloseSheet() }

                VStack(spacing: 0) {
                    Spacer()
                    addScheduleSheet
                        .transition(.move(edge: .bottom))
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.height > 80 { requestCloseSheet() }
                                }
                        )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .toast($viewModel.toast)
        .animation(.easeInOut(duration: 0.25), value: showAddSheet)
        .navigationBarHidden(true)
        .task { viewModel.load() }
        .navigationDestination(item: $selectedSchedule) { place in
            NearbySpotDetailView(
                name: place.name,
                address: place.address,
                description: place.description,
                imageUrl: nil,
                latitude: place.latitude,
                longitude: place.longitude,
                categoryName: place.categoryName
            )
        }
        .alert("저장하지 못했어요", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            // 입력값은 그대로 두고 다시 저장을 시도할 수 있게 합니다.
            Button("재시도") { viewModel.saveError = nil; save() }
            Button("닫기", role: .cancel) { viewModel.saveError = nil }
        } message: {
            Text(viewModel.saveError ?? "")
        }
        .confirmationDialog(
            "이 일정을 삭제할까요?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let target = pendingDelete { viewModel.deletePersonalSchedule(id: target.id) }
                pendingDelete = nil
                swipedId = nil
            }
            Button("취소", role: .cancel) { pendingDelete = nil }
        }
        .confirmationDialog("작성을 취소할까요?", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button("작성 취소", role: .destructive) { closeSheet() }
            Button("계속 작성", role: .cancel) { }
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

    // MARK: - 토스트

    // MARK: - Header

    private var headerSection: some View {
        NavigationHeader(title: "여행 일정") { dismiss() }
    }

    // MARK: - 로딩 / 에러

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
            Image(systemName: "calendar.badge.exclamationmark")
                .font(AppFont.emojiXL)
                .foregroundColor(AppColor.borderStrong)
            Text(message)
                .font(AppFont.bodyMMedium)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
            Button { viewModel.load() } label: {
                Text("다시 시도")
                    .font(AppFont.bodyBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .frame(height: 44)
                    .background(AppColor.accent)
                    .cornerRadius(AppRadius.md)
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
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xl)

                todaySection

                if viewModel.days.isEmpty {
                    Text("등록된 일정이 없습니다")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.days) { day in
                        daySection(day)
                            .padding(.horizontal, AppSpacing.xl)
                            .padding(.bottom, 14)
                    }
                }

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: - 여행 정보 카드

    private var tripInfoCard: some View {
        HStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(AppColor.borderSoft)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "suitcase")
                        .font(AppFont.title1Light)
                        .foregroundColor(AppColor.textTertiary)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.tripTitle)
                    .font(AppFont.bodyMBold)
                    .foregroundColor(AppColor.textPrimary)
                Text("진행일자 \(viewModel.tripPeriod)")
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
            }
            Spacer()
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .cornerRadius(AppRadius.lg)
    }

    // MARK: - 오늘의 일정

    /// 오늘 날짜에 해당하는 일정이 있을 때만 표시합니다.
    /// 출발 전이거나 이미 끝난 여행이면 이 섹션 자체가 없습니다.
    @ViewBuilder
    private var todaySection: some View {
        if viewModel.isTripToday {
            VStack(alignment: .leading, spacing: 0) {
                Text("오늘의 일정")
                    .font(AppFont.bodyMBold)
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.bottom, AppSpacing.sm)

                // 오늘 일정 전체 구간의 경과 비율
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppColor.divider)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppColor.accent)
                            .frame(width: geo.size.width * viewModel.todayProgress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.bottom, 14)

                if let current = viewModel.todayCurrentSchedule {
                    HStack {
                        Text(current.placeName ?? current.mainContent ?? "일정")
                            .font(AppFont.bodyMedium)
                            .foregroundColor(AppColor.textPrimary)
                        Spacer()
                        Text(TripScheduleViewModel.timeRange(current.startTime, current.endTime))
                            .font(AppFont.label)
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 48)
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.lg)
                } else {
                    Text("오늘 일정이 모두 끝났어요")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColor.surface)
                        .cornerRadius(AppRadius.lg)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
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
                        .font(AppFont.captionBold)
                        .foregroundColor(isExpanded ? .white : AppColor.textSecondary)
                        .frame(width: 48, height: 24)
                        .background(isExpanded ? AppColor.accent : AppColor.divider)
                        .cornerRadius(AppRadius.xs)

                    Text(day.date.replacingOccurrences(of: "-", with: "."))
                        .font(AppFont.labelMedium)
                        .foregroundColor(isExpanded ? AppColor.textPrimary : AppColor.textSecondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AppFont.captionSemiBold)
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(isExpanded ? AppColor.accentSubtle : AppColor.surface)
                .cornerRadius(AppRadius.lg)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: AppSpacing.sm) {
                    if day.items.isEmpty {
                        Text("등록된 일정이 없어요")
                            .font(AppFont.label)
                            .foregroundColor(AppColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(AppColor.surfaceSubtle)
                            .cornerRadius(AppRadius.lg)
                    }

                    ForEach(day.items) { item in
                        switch item {
                        case .shared(let s):   sharedRow(s)
                        case .personal(let p): personalRow(p, dayNumber: day.dayNumber)
                        }
                    }

                    addPersonalButton(dayNumber: day.dayNumber)
                }
                .padding(.top, AppSpacing.sm)
            }
        }
    }

    // MARK: - 공용 일정 행

    private func sharedRow(_ s: TravelerScheduleDTO) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "mappin")
                        .font(AppFont.caption2)
                        .foregroundColor(AppColor.danger)
                    Text(s.placeName ?? s.mainContent ?? "일정")
                        .font(AppFont.bodyBold)
                        .foregroundColor(AppColor.textPrimary)
                }

                if let address = s.placeAddress, !address.isEmpty {
                    Text(address)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Text(TripScheduleViewModel.timeRange(s.startTime, s.endTime))
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)

                if let content = s.mainContent, !content.isEmpty, content != s.placeName {
                    let isOpen = expandedDescriptions.contains(s.id)
                    Text(content)
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.textDark)
                        .lineLimit(isOpen ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)

                    // 2줄을 넘길 만한 설명에만 더보기를 답니다
                    if content.count > 40 {
                        Button {
                            if isOpen { expandedDescriptions.remove(s.id) }
                            else      { expandedDescriptions.insert(s.id) }
                        } label: {
                            Text(isOpen ? "접기" : "더보기")
                                .font(AppFont.captionMedium)
                                .foregroundColor(AppColor.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 8)

            SpotImageView(imageUrl: nil, categoryName: s.transport, iconSize: 20)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.divider, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // 장소 정보가 있는 일정만 스팟 상세로 갑니다
            if s.placeName != nil || s.placeAddress != nil {
                selectedSchedule = SchedulePlace(
                    id: s.id,
                    name: s.placeName ?? s.mainContent ?? "일정",
                    address: s.placeAddress,
                    description: s.mainContent,
                    latitude: s.placeLatitude.flatMap(Double.init),
                    longitude: s.placeLongitude.flatMap(Double.init),
                    categoryName: s.transport
                )
            }
        }
    }

    // MARK: - 개인 일정 행

    /// 왼쪽으로 밀면 수정·삭제가 나옵니다.
    private func personalRow(_ p: TravelerPersonalScheduleDTO, dayNumber: Int) -> some View {
        let isSwiped = swipedId == p.id
        let actionWidth: CGFloat = 132

        return ZStack(alignment: .trailing) {
            HStack(spacing: AppSpacing.xs) {
                Button { beginEdit(p, dayNumber: dayNumber) } label: {
                    Text("수정")
                        .font(AppFont.labelBold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(AppColor.textSecondary)
                        .cornerRadius(AppRadius.lg)
                }
                .buttonStyle(.plain)

                Button { pendingDelete = p } label: {
                    Text("삭제")
                        .font(AppFont.labelBold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(AppColor.danger)
                        .cornerRadius(AppRadius.lg)
                }
                .buttonStyle(.plain)
            }
            .opacity(isSwiped ? 1 : 0)

            personalRowContent(p)
                .offset(x: isSwiped ? -actionWidth : 0)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onEnded { value in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if value.translation.width < -40      { swipedId = p.id }
                                else if value.translation.width > 40  { swipedId = nil }
                            }
                        }
                )
        }
    }

    private func personalRowContent(_ p: TravelerPersonalScheduleDTO) -> some View {
        HStack(spacing: 10) {
            Text("내 일정")
                .font(AppFont.caption2Bold)
                .foregroundColor(AppColor.accent)
                .frame(width: 52, height: 22)
                .background(AppColor.accentSubtle)
                .cornerRadius(AppRadius.xs)

            VStack(alignment: .leading, spacing: 2) {
                Text(p.title)
                    .font(AppFont.labelMedium)
                    .foregroundColor(AppColor.textPrimary)
                if let memo = p.memo, !memo.isEmpty {
                    Text(memo)
                        .font(AppFont.caption2)
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(TripScheduleViewModel.timeRange(p.startTime, p.endTime))
                    .font(AppFont.caption)
                    .foregroundColor(AppColor.textSecondary)
                if p.overlapWarning {
                    Text("겹침")
                        .font(AppFont.microBold)
                        .foregroundColor(AppColor.warning)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(AppColor.accent, style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
    }

    // MARK: - 개인 일정 추가 버튼

    private func addPersonalButton(dayNumber: Int) -> some View {
        Button {
            addDayNumber = dayNumber
            showAddSheet = true
        } label: {
            Text("+ 개인 일정 추가")
                .font(AppFont.bodyMedium)
                .foregroundColor(AppColor.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColor.surface)
                .cornerRadius(AppRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .strokeBorder(AppColor.textSecondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
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
                    .fill(AppColor.divider)
                    .frame(width: 52, height: 5)
                Spacer()
            }
            .padding(.top, 10)

            Text(editingId == nil ? "개인 일정 추가" : "개인 일정 수정")
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, 22)
                .padding(.bottom, AppSpacing.md)

            // 제목
            VStack(alignment: .leading, spacing: 6) {
                Text("제목")
                    .font(AppFont.captionMedium)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, AppSpacing.xl)

                // 입력 중에는 자르지 않습니다. 한국어·일본어·중국어는 여러 타를
                // 조합해 한 글자를 만들기 때문에, 조합 중 바인딩을 덮어쓰면 입력이 깨집니다.
                // 대신 초과분을 카운터에 빨간색으로 표시하고 저장을 막습니다.
                TextField("예: 기념품 쇼핑", text: $addTitle)
                    .font(AppFont.body)
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 48)
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(isTitleOverLimit ? AppColor.danger : Color.clear, lineWidth: 1)
                            .padding(.horizontal, AppSpacing.xl)
                    )
                    .padding(.horizontal, AppSpacing.xl)

                HStack {
                    Spacer()
                    Text("\(addTitle.count)/\(titleLimit)")
                        .font(isTitleOverLimit ? AppFont.caption2Bold : AppFont.caption2)
                        .foregroundColor(isTitleOverLimit ? AppColor.danger : AppColor.textTertiary)
                }
                .padding(.horizontal, AppSpacing.xl)
            }
            .padding(.bottom, AppSpacing.sm)

            // 시간
            VStack(alignment: .leading, spacing: 6) {
                Text("시간")
                    .font(AppFont.captionMedium)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, AppSpacing.xl)

                HStack(spacing: AppSpacing.sm) {
                    timeField(prefix: "시작", value: addStart, field: .start)
                    timeField(prefix: "종료", value: addEnd,   field: .end)
                }
                .padding(.horizontal, AppSpacing.xl)

                // 탭한 쪽만 휠 피커를 펼칩니다
                if let field = openPicker {
                    DatePicker(
                        "",
                        selection: field == .start ? $startDate : $endDate,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 140)
                    .padding(.horizontal, AppSpacing.xl)
                }

                if isEndBeforeStart {
                    Text("종료 시간이 시작 시간보다 빠릅니다")
                        .font(AppFont.caption2)
                        .foregroundColor(AppColor.danger)
                        .padding(.horizontal, AppSpacing.xl)
                } else if overlapsShared {
                    // 겹쳐도 저장은 허용합니다 (개인 책임)
                    Text("안내사 공용 일정과 시간이 겹칩니다")
                        .font(AppFont.caption2)
                        .foregroundColor(AppColor.warning)
                        .padding(.horizontal, AppSpacing.xl)
                }
            }
            .padding(.bottom, AppSpacing.sm)

            // 메모
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                TextField("메모 (선택 · \(memoLimit)자)", text: $addMemo)
                    .font(AppFont.label)
                    .foregroundColor(AppColor.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 56)
                    .background(AppColor.surface)
                    .cornerRadius(AppRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(isMemoOverLimit ? AppColor.danger : Color.clear, lineWidth: 1)
                    )

                if isMemoOverLimit {
                    HStack {
                        Spacer()
                        Text("\(addMemo.count)/\(memoLimit)")
                            .font(AppFont.caption2Bold)
                            .foregroundColor(AppColor.danger)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            // 저장
            Button { save() } label: {
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
                .background(canSave ? AppColor.accent : AppColor.borderMuted)
                .cornerRadius(AppRadius.lg)
            }
            .buttonStyle(.plain)
            .disabled(!canSave || viewModel.isSaving)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

    private func timeField(prefix: String, value: String, field: TimeField) -> some View {
        Button {
            openPicker = (openPicker == field) ? nil : field
        } label: {
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

    // MARK: - 동작

    /// "HH:mm"
    private var addStart: String { Self.hhmm(startDate) }
    private var addEnd:   String { Self.hhmm(endDate) }

    private var isEndBeforeStart: Bool { addEnd <= addStart }

    /// 입력 중 공용 일정과 겹치는지 — 경고만 하고 저장은 막지 않습니다
    private var overlapsShared: Bool {
        guard let day = addDayNumber, !isEndBeforeStart else { return false }
        return viewModel.overlapsSharedSchedule(dayNumber: day, start: addStart, end: addEnd)
    }

    private static func defaultTime(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private static func hhmm(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private static func date(fromHHmm text: String) -> Date {
        let parts = text.split(separator: ":")
        let h = parts.count == 2 ? Int(parts[0]) ?? 0 : 0
        let m = parts.count == 2 ? Int(parts[1]) ?? 0 : 0
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
    }

    private var isTitleOverLimit: Bool { addTitle.count > titleLimit }
    private var isMemoOverLimit: Bool { addMemo.count > memoLimit }

    private var canSave: Bool {
        !addTitle.trimmingCharacters(in: .whitespaces).isEmpty
            && !isTitleOverLimit
            && !isMemoOverLimit
            && !isEndBeforeStart
    }

    private func save() {
        guard let day = addDayNumber, canSave else { return }
        let title = addTitle.trimmingCharacters(in: .whitespaces)
        let memo = addMemo.isEmpty ? nil : addMemo

        // 성공했을 때만 시트를 닫습니다. 실패하면 입력값이 그대로 남습니다.
        if let editingId {
            viewModel.updatePersonalSchedule(
                id: editingId, dayNumber: day, title: title,
                start: addStart, end: addEnd, memo: memo
            ) { closeSheet() }
        } else {
            viewModel.addPersonalSchedule(
                dayNumber: day, title: title,
                start: addStart, end: addEnd, memo: memo
            ) { closeSheet() }
        }
    }

    /// 스와이프 > 수정 — 기존 값을 시트에 채워 엽니다
    private func beginEdit(_ p: TravelerPersonalScheduleDTO, dayNumber: Int) {
        editingId = p.id
        addDayNumber = dayNumber
        addTitle = p.title
        addMemo = p.memo ?? ""
        startDate = Self.date(fromHHmm: TripScheduleViewModel.hhmm(p.startTime))
        endDate   = Self.date(fromHHmm: TripScheduleViewModel.hhmm(p.endTime))
        swipedId = nil
        showAddSheet = true
    }

    /// 딤 탭·아래로 드래그 — 작성 중이면 한 번 물어봅니다
    private func requestCloseSheet() {
        if addTitle.isEmpty && addMemo.isEmpty {
            closeSheet()
        } else {
            showDiscardConfirm = true
        }
    }

    private func closeSheet() {
        showAddSheet = false
        editingId = nil
        openPicker = nil
        addTitle = ""
        addMemo = ""
        startDate = Self.defaultTime(hour: 20)
        endDate = Self.defaultTime(hour: 21)
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
