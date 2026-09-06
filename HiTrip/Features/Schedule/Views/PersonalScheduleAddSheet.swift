import SwiftUI

// MARK: - PersonalScheduleAddSheet
/// 여행일정 화면에서 개인 일정 추가 시트
///
/// 피그마 0827 수정본:
/// - 제목 입력 (placeholder: "예: 기념품 쇼핑")
/// - 시작/종료 시간 선택
/// - 메모 입력 (선택, 100자)
/// - 공용 일정 겹침 경고 (주황 텍스트)
/// - 저장 버튼 (파란색, 제목 입력 시 활성화)

struct PersonalScheduleAddSheet: View {

    @Environment(\.dismiss) private var dismiss

    // 공용 일정 — 겹침 감지용
    let officialSchedules: [TripOfficialSchedule]

    @State private var title    = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var memo     = ""

    private let maxMemo = 100

    private var overlapWarning: String? {
        let overlap = officialSchedules.first {
            $0.startTime < endTime && $0.endTime > startTime
        }
        guard let o = overlap else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "공용 일정과 겹칩니다 (\(f.string(from: o.startTime)) \(o.title))"
    }

    private var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && title.count <= 20
            && memo.count <= maxMemo
    }

    init(officialSchedules: [TripOfficialSchedule], defaultDate: Date = Date()) {
        self.officialSchedules = officialSchedules
        let base = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        _startTime = State(initialValue: base)
        _endTime   = State(initialValue: base.addingTimeInterval(3600))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HiTripSpacing.xl) {
                    // 제목
                    titleField

                    // 시간
                    timeSection

                    // 메모
                    memoField

                    // 겹침 경고
                    if let warning = overlapWarning {
                        overlapView(warning)
                    }
                }
                .padding(.horizontal, HiTripSpacing.pagePadding)
                .padding(.top, HiTripSpacing.xl)
                .padding(.bottom, HiTripSpacing.xxl)
            }
            .safeAreaInset(edge: .bottom) { saveButton }
            .background(Color.white)
            .navigationTitle("개인 일정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
            }
        }
    }

    // MARK: - Title Field

    private var titleField: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
            Text("제목")
                .font(HiTripFont.bodyBold)
                .foregroundColor(HiTripColor.textBlack)

            HStack {
                TextField("예: 기념품 쇼핑", text: $title)
                    .font(HiTripFont.body)
                Text("\(title.count)/20")
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.gray400)
            }
            .padding(.horizontal, HiTripSpacing.mdl)
            .padding(.vertical, HiTripSpacing.md)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
            // 입력 중 자르지 않습니다 — 조합형 문자(한국어·일본어·중국어)가 깨집니다.
            // 초과 여부는 카운터와 저장 버튼 활성화로 알립니다.
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
            Text("시간")
                .font(HiTripFont.bodyBold)
                .foregroundColor(HiTripColor.textBlack)

            HStack(spacing: HiTripSpacing.md) {
                timePicker(label: "시작", selection: $startTime)
                timePicker(label: "종료", selection: $endTime)
            }
        }
    }

    private func timePicker(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(HiTripFont.captionM)
                .foregroundColor(HiTripColor.gray500)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.horizontal, HiTripSpacing.mdl)
        .padding(.vertical, HiTripSpacing.sm)
        .background(HiTripColor.gray100)
        .cornerRadius(HiTripRadius.card)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Memo Field

    private var memoField: some View {
        VStack(alignment: .leading, spacing: HiTripSpacing.sm) {
            HStack {
                Text("메모")
                    .font(HiTripFont.bodyBold)
                    .foregroundColor(HiTripColor.textBlack)
                Text("(선택)")
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.gray400)
                Spacer()
                Text("\(memo.count)/\(maxMemo)")
                    .font(HiTripFont.caption)
                    .foregroundColor(HiTripColor.gray400)
            }

            ZStack(alignment: .topLeading) {
                if memo.isEmpty {
                    Text("메모를 입력하세요")
                        .font(HiTripFont.body)
                        .foregroundColor(HiTripColor.gray400)
                        .padding(.horizontal, HiTripSpacing.xs)
                        .padding(.top, HiTripSpacing.sm)
                }
                TextEditor(text: $memo)
                    .font(HiTripFont.body)
                    .frame(minHeight: 80)
                    // 위와 같은 이유로 입력 중 자르지 않습니다.
            }
            .padding(HiTripSpacing.sm)
            .background(HiTripColor.gray100)
            .cornerRadius(HiTripRadius.card)
        }
    }

    // MARK: - Overlap Warning

    private func overlapView(_ message: String) -> some View {
        HStack(spacing: HiTripSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.caution)
            Text(message)
                .font(HiTripFont.caption)
                .foregroundColor(HiTripColor.caution)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            dismiss()
        } label: {
            Text("저장")
                .font(HiTripFont.bodyLBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HiTripSpacing.lg)
                .background(isSaveEnabled ? HiTripColor.primary800 : HiTripColor.buttonDisabled)
                .cornerRadius(HiTripRadius.button)
        }
        .buttonStyle(.plain)
        .disabled(!isSaveEnabled)
        .padding(.horizontal, HiTripSpacing.pagePadding)
        .padding(.vertical, HiTripSpacing.md)
        .background(Color.white)
    }
}
