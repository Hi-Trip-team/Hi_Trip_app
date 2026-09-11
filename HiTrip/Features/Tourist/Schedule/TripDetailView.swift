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
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { requestCloseSheet() }

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
        .overlay(alignment: .bottom) { toastView }
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
                .transition(.opacity)
                .task(id: toast) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    viewModel.toast = nil
                }
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
                    if day.items.isEmpty {
                        Text("등록된 일정이 없어요")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6B7280"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color(hex: "#F9FAFB"))
                            .cornerRadius(12)
                    }

                    ForEach(day.items) { item in
                        switch item {
                        case .shared(let s):   sharedRow(s)
                        case .personal(let p): personalRow(p, dayNumber: day.dayNumber)
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
                    let isOpen = expandedDescriptions.contains(s.id)
                    Text(content)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#374151"))
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
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#2563EB"))
                        }
                        .buttonStyle(.plain)
                    }
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
            HStack(spacing: 8) {
                Button { beginEdit(p, dayNumber: dayNumber) } label: {
                    Text("수정")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#6B7280"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button { pendingDelete = p } label: {
                    Text("삭제")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#EF4444"))
                        .cornerRadius(12)
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

            Text(editingId == nil ? "개인 일정 추가" : "개인 일정 수정")
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
                    timeField(prefix: "시작", value: addStart, field: .start)
                    timeField(prefix: "종료", value: addEnd,   field: .end)
                }
                .padding(.horizontal, 24)

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
                    .padding(.horizontal, 24)
                }

                if isEndBeforeStart {
                    Text("종료 시간이 시작 시간보다 빠릅니다")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 24)
                } else if overlapsShared {
                    // 겹쳐도 저장은 허용합니다 (개인 책임)
                    Text("안내사 공용 일정과 시간이 겹칩니다")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#EB8C0D"))
                        .padding(.horizontal, 24)
                }
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

    private func timeField(prefix: String, value: String, field: TimeField) -> some View {
        Button {
            openPicker = (openPicker == field) ? nil : field
        } label: {
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
