import SwiftUI

// MARK: - MapRangeSettingView
/// 지도 범위 설정 화면 — 피그마 디자인 반영
///
/// 구성:
/// - 날짜 탭 (여행 일차 선택, 파란 pill)
/// - 선택 일차 주소 표시
/// - 슬라이더 (좁게 1 ~ 넓게 5, 5단계)
/// - 미리보기 지도 (반경 원 표시)
/// - 하단 버튼: 내 위치로 이동 / 현재 일정 위치로 이동
/// - 저장하기 버튼

struct MapRangeSettingView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay: Int = 1
    @State private var radiusStep: Int = 2        // 1~5 단계
    @State private var drawPreviewMap = false

    private let totalDays = 5                     // Mock: 5일 일정
    private let mockAddress = "제주도 서귀포시 중문동 123-45"

    // 단계별 실제 반경 (m)
    private let radiusOptions: [Double] = [300, 600, 1000, 1500, 2500]
    private var radiusMeters: Double { radiusOptions[radiusStep - 1] }

    private let centerLatitude  = 33.2508
    private let centerLongitude = 126.4125

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: 날짜 탭
                dayTabBar
                    .padding(.top, 20)

                // MARK: 주소
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(HiTripColor.primary800)
                    Text(mockAddress)
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray500)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // MARK: 슬라이더 (좁게 ↔ 넓게, 5단계)
                radiusSliderSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // MARK: 미리보기 지도
                mapPreview
                    .padding(.top, 16)

                Spacer()

                // MARK: 하단 이동 버튼 2개
                HStack(spacing: 12) {
                    moveButton(title: "내 위치로 이동") {
                        // TODO: 내 위치로 이동
                    }
                    moveButton(title: "현재 일정 위치로 이동") {
                        // TODO: 현재 일정 위치로 이동
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // MARK: 저장하기
                Button {
                    dismiss()
                } label: {
                    Text("저장하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(HiTripColor.primary800)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.white)
            .navigationTitle("지도 범위 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(HiTripColor.textBlack)
                    }
                }
            }
        }
        .onAppear  { drawPreviewMap = true  }
        .onDisappear { drawPreviewMap = false }
    }

    // MARK: - Day Tab Bar

    private var dayTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...totalDays, id: \.self) { day in
                    Button {
                        selectedDay = day
                    } label: {
                        Text("\(day)일차")
                            .font(.system(size: 14, weight: selectedDay == day ? .semibold : .regular))
                            .foregroundColor(selectedDay == day ? .white : HiTripColor.gray500)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(selectedDay == day ? HiTripColor.primary800 : Color.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedDay == day ? Color.clear : HiTripColor.gray200, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Radius Slider Section

    private var radiusSliderSection: some View {
        VStack(spacing: 8) {
            // 단계 인디케이터
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { step in
                    Circle()
                        .fill(step <= radiusStep ? HiTripColor.primary800 : HiTripColor.gray200)
                        .frame(width: 10, height: 10)
                    if step < 5 {
                        Rectangle()
                            .fill(step < radiusStep ? HiTripColor.primary800 : HiTripColor.gray200)
                            .frame(height: 3)
                    }
                }
            }
            .frame(height: 10)

            // 드래그 슬라이더 (내부 사용 용도로 Slider 그대로, 스텝 스냅)
            Slider(value: Binding(
                get: { Double(radiusStep) },
                set: { radiusStep = Int($0.rounded()) }
            ), in: 1...5, step: 1)
            .tint(HiTripColor.primary800)

            // 레이블
            HStack {
                Text("좁게")
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)
                Spacer()
                Text("넓게")
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)
            }
        }
    }

    // MARK: - Map Preview

    private var mapPreview: some View {
        KakaoMapView(
            latitude: centerLatitude,
            longitude: centerLongitude,
            draw: $drawPreviewMap,
            radiusMeters: radiusMeters
        )
        .frame(height: 240)
        .cornerRadius(0)
        .padding(.horizontal, 20)
        .cornerRadius(16)
    }

    // MARK: - Move Button

    private func moveButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(HiTripColor.gray500)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(HiTripColor.gray100)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
