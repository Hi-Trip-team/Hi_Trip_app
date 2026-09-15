import SwiftUI

// MARK: - 전체 일정 공통 부품
/// 여행객 "여행 일정"과 안내사 "전체 일정"이 같이 씁니다 (기준: 여행객 화면).
/// 일정 행의 내용·메뉴처럼 역할마다 다른 부분은 각 화면에 남깁니다.

/// 여행 요약 카드 — 여행명 + 기간 등 한 줄
struct TripInfoCard: View {
    let title: String
    let subtitle: String

    var body: some View {
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
                Text(title)
                    .font(AppFont.bodyMBold)
                    .foregroundColor(AppColor.textPrimary)
                Text(subtitle)
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
}

/// 일차 아코디언 머리 — 펼친 일차만 파란 칩
struct DayAccordionHeader: View {
    let dayNumber: Int
    /// "yyyy.MM.dd"
    let date: String
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("\(dayNumber)일차")
                    .font(AppFont.captionBold)
                    .foregroundColor(isExpanded ? .white : AppColor.textSecondary)
                    .frame(width: 48, height: 24)
                    .background(isExpanded ? AppColor.accent : AppColor.divider)
                    .cornerRadius(AppRadius.xs)

                Text(date)
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
    }
}

/// 펼친 일차에 일정이 없을 때
struct EmptyDayRow: View {
    var body: some View {
        Text("등록된 일정이 없어요")
            .font(AppFont.label)
            .foregroundColor(AppColor.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(AppColor.surfaceSubtle)
            .cornerRadius(AppRadius.lg)
    }
}

/// 점선 "+ 일정 추가" 버튼
struct DashedAddButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
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
}

// MARK: - 아래에서 올라오는 시트

/// 딤 + 아래 시트 — 딤 탭·아래로 끌기로 닫기 요청, 키보드가 올라오면 시트도 함께 올라갑니다
///
/// `content`에 키보드 표시 여부를 넘겨 저장 버튼 아래 여백(홈 인디케이터용)을 줄이게 합니다.
struct BottomSheetOverlay<Content: View>: View {
    let onDismissRequest: () -> Void
    @ViewBuilder let content: (_ isKeyboardVisible: Bool) -> Content

    @State private var isKeyboardVisible = false

    var body: some View {
        ZStack {
            DimmedBackground { onDismissRequest() }

            VStack(spacing: 0) {
                Spacer()
                content(isKeyboardVisible)
                    .transition(.move(edge: .bottom))
                    .gesture(
                        DragGesture().onEnded { value in
                            if value.translation.height > 80 { onDismissRequest() }
                        }
                    )
            }
            // 홈 인디케이터 영역만 무시합니다. edges만 주면 키보드 영역까지 무시해서
            // 키보드가 올라와도 시트가 그대로 있어 입력칸이 가려집니다.
            .ignoresSafeArea(.container, edges: .bottom)
            .zIndex(1)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }
}

/// 시트 카드 — 손잡이 + 제목 + 내용 (내용은 좌우 여백을 스스로 줍니다)
struct BottomSheetCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColor.divider)
                    .frame(width: 52, height: 5)
                Spacer()
            }
            .padding(.top, 10)

            Text(title)
                .font(AppFont.bodyLBold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, 22)
                .padding(.bottom, AppSpacing.md)

            content()
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
}

/// 시트 입력칸 이름 ("제목", "시간" …)
struct SheetFieldLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(AppFont.captionMedium)
            .foregroundColor(AppColor.textSecondary)
    }
}

/// 시작·종료 시간 칸 — 누르면 휠 피커를 펼칩니다
struct SheetTimeField: View {
    let prefix: String
    let value: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                    .stroke(isActive ? AppColor.accent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 시트 맨 아래 [저장] — 34는 홈 인디케이터 자리, 키보드가 떠 있으면 줄입니다
struct SheetPrimaryButton: View {
    var title: String = "저장"
    let isEnabled: Bool
    let isLoading: Bool
    let isKeyboardVisible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(AppFont.bodyLBold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? AppColor.accent : AppColor.borderMuted)
            .cornerRadius(AppRadius.lg)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, 18)
        .padding(.bottom, isKeyboardVisible ? AppSpacing.md : 34)
    }
}
