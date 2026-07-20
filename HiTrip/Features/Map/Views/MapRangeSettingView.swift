import SwiftUI

// MARK: - MapRangeSettingView
/// 허용 반경 설정 화면
///
/// 구성:
/// - 날짜 탭 (여행 일차 선택)
/// - 반경 슬라이더 (500m ~ 5km)
/// - 미리보기 지도 (KakaoMap)
/// - 저장 버튼

struct MapRangeSettingView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedDay: Int = 1
    @State private var radiusKm: Double = 1.0    // km 단위

    private let totalDays = 5                    // Mock: 5일 일정
    private let minKm: Double = 0.5
    private let maxKm: Double = 5.0

    var radiusMeters: Double { radiusKm * 1000 }

    // MARK: - Mock Center (서울 시청)

    private let centerLatitude  = 37.5665
    private let centerLongitude = 126.9780

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: 날짜 탭
                dayTabBar
                    .padding(.top, 16)

                Divider()
                    .padding(.top, 12)

                // MARK: 반경 슬라이더
                radiusSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                // MARK: 미리보기 지도
                mapPreview
                    .padding(.top, 20)

                Spacer()

                // MARK: 저장 버튼
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
            .navigationTitle("허용 반경 설정")
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
                            .foregroundColor(selectedDay == day ? .white : HiTripColor.gray400)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedDay == day ? HiTripColor.primary800 : Color.clear)
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

    // MARK: - Radius Section

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("허용 반경")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(HiTripColor.textBlack)
                Spacer()
                Text(radiusLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(HiTripColor.primary800)
            }

            Slider(value: $radiusKm, in: minKm...maxKm, step: 0.5)
                .tint(HiTripColor.primary800)

            HStack {
                Text("500m")
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)
                Spacer()
                Text("5km")
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.gray400)
            }
        }
    }

    private var radiusLabel: String {
        if radiusKm < 1.0 {
            return "\(Int(radiusKm * 1000))m"
        } else if radiusKm == radiusKm.rounded() {
            return "\(Int(radiusKm))km"
        } else {
            return String(format: "%.1fkm", radiusKm)
        }
    }

    // MARK: - Map Preview

    @State private var drawPreviewMap = false

    private var mapPreview: some View {
        ZStack {
            KakaoMapView(
                latitude: centerLatitude,
                longitude: centerLongitude,
                draw: $drawPreviewMap,
                radiusMeters: radiusMeters
            )
            .cornerRadius(16)
            .padding(.horizontal, 20)

            // 반경 레이블 오버레이
            VStack {
                HStack {
                    Spacer()
                    Text("반경 \(radiusLabel)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.top, 12)
                        .padding(.trailing, 32)
                }
                Spacer()
            }
        }
        .frame(height: 220)
        .onAppear  { drawPreviewMap = true  }
        .onDisappear { drawPreviewMap = false }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            // TODO: ViewModel에 반경 저장
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
    }
}
