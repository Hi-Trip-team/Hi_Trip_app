import SwiftUI

// MARK: - SafetyTourist (Mock Model)

struct SafetyTourist: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let country: String
    let passportNumber: String
    var isDeparted: Bool       // 이탈 여부
    var departureDistance: Double? // km, nil이면 정상
    var heartRate: Int
    var spo2: Int

    var isHeartRateAlert: Bool { heartRate > 100 || heartRate < 50 }
    var isSpo2Alert: Bool { spo2 < 95 }
    var isDepartureAlert: Bool { isDeparted || (departureDistance ?? 0) > 0 }

    var statusText: String {
        var parts: [String] = []
        if let dist = departureDistance, dist > 0 {
            parts.append("경계 밖 \(String(format: "%.1f", dist))km")
        }
        parts.append("심박 \(heartRate)")
        parts.append("SpO₂ \(spo2)%")
        return parts.joined(separator: " · ")
    }
}

// MARK: - SafetyManagementView

struct SafetyManagementView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTourist: SafetyTourist?
    @State private var showDetail = false

    private let tourists: [SafetyTourist] = [
        SafetyTourist(name: "이연서", phone: "010-1234-5678", country: "대한민국",
                      passportNumber: "DND***000", isDeparted: false,
                      departureDistance: nil, heartRate: 90, spo2: 21),
        SafetyTourist(name: "김민준", phone: "010-2345-6789", country: "대한민국",
                      passportNumber: "KIM***123", isDeparted: true,
                      departureDistance: 5.0, heartRate: 110, spo2: 87),
        SafetyTourist(name: "박서연", phone: "010-3456-7890", country: "대한민국",
                      passportNumber: "PAK***456", isDeparted: false,
                      departureDistance: nil, heartRate: 135, spo2: 94),
        SafetyTourist(name: "정우진", phone: "010-4567-8901", country: "대한민국",
                      passportNumber: "JEO***789", isDeparted: false,
                      departureDistance: nil, heartRate: 90, spo2: 84),
        SafetyTourist(name: "최지훈", phone: "010-5678-9012", country: "대한민국",
                      passportNumber: "CHO***012", isDeparted: false,
                      departureDistance: nil, heartRate: 187, spo2: 95),
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    infoLabel
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    tableSection
                        .padding(.horizontal, 12)

                    Spacer().frame(height: 32)
                }
            }
            .background(Color.white)

            if showDetail, let tourist = selectedTourist {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showDetail = false }

                touristDetailPopup(tourist)
                    .padding(.horizontal, 24)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDetail)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                }
                Spacer()
            }
            Text("안전 관리")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(HiTripColor.textBlack)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Info Label

    private var infoLabel: some View {
        HStack {
            Text("10:24 기준 · 30초마다 갱신")
                .font(HiTripFont.caption)
                .foregroundColor(HiTripColor.gray400)
            Spacer()
        }
    }

    // MARK: - Table

    private var tableSection: some View {
        VStack(spacing: 0) {
            // Header row
            tableHeaderRow

            Divider()

            // Data rows
            ForEach(tourists) { tourist in
                tableDataRow(tourist)
                Divider()
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(HiTripColor.gray200, lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private var tableHeaderRow: some View {
        HStack(spacing: 0) {
            Text("이름")
                .frame(width: 56)

            Divider().frame(height: 44)

            Text("연락처")
                .frame(maxWidth: .infinity)

            Divider().frame(height: 44)

            // 위험 여부
            VStack(spacing: 0) {
                Text("위험 여부")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(HiTripColor.gray500)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .overlay(Divider(), alignment: .bottom)

                Text("이탈 여부")
                    .font(.system(size: 9))
                    .foregroundColor(HiTripColor.gray500)
                    .frame(width: 52)
                    .padding(.vertical, 4)
            }

            Divider().frame(height: 44)

            // 건강 상태 확인
            VStack(spacing: 0) {
                Text("건강 상태 확인")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(HiTripColor.gray500)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .overlay(Divider(), alignment: .bottom)

                HStack(spacing: 0) {
                    Text("심박수")
                        .font(.system(size: 9))
                        .foregroundColor(HiTripColor.gray500)
                        .frame(width: 40)
                    Divider().frame(height: 22)
                    Text("산소포화도")
                        .font(.system(size: 9))
                        .foregroundColor(HiTripColor.gray500)
                        .frame(width: 52)
                }
                .padding(.vertical, 4)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(HiTripColor.gray500)
        .frame(height: 44)
        .background(HiTripColor.gray100)
    }

    private func tableDataRow(_ tourist: SafetyTourist) -> some View {
        Button {
            selectedTourist = tourist
            showDetail = true
        } label: {
            HStack(spacing: 0) {
                Text(tourist.name)
                    .font(.system(size: 12))
                    .foregroundColor(HiTripColor.textBlack)
                    .frame(width: 56)

                Divider().frame(height: 44)

                Text(tourist.phone)
                    .font(.system(size: 11))
                    .foregroundColor(HiTripColor.gray500)
                    .frame(maxWidth: .infinity)

                Divider().frame(height: 44)

                // 이탈 여부
                Group {
                    if let dist = tourist.departureDistance, dist > 0 {
                        Text("\(String(format: "%.0f", dist))km")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 52)
                            .background(Color.red)
                    } else {
                        Text("X")
                            .font(.system(size: 12))
                            .foregroundColor(HiTripColor.gray500)
                            .frame(width: 52)
                    }
                }
                .frame(height: 44)

                Divider().frame(height: 44)

                // 심박수
                Group {
                    if tourist.isHeartRateAlert {
                        Text("\(tourist.heartRate)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40)
                            .background(Color.red)
                    } else {
                        Text("\(tourist.heartRate)")
                            .font(.system(size: 11))
                            .foregroundColor(HiTripColor.textBlack)
                            .frame(width: 40)
                    }
                }
                .frame(height: 44)

                Divider().frame(height: 44)

                // 산소포화도
                Group {
                    if tourist.isSpo2Alert {
                        Text("\(tourist.spo2)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 52)
                            .background(Color.red)
                    } else {
                        Text("\(tourist.spo2)")
                            .font(.system(size: 11))
                            .foregroundColor(HiTripColor.textBlack)
                            .frame(width: 52)
                    }
                }
                .frame(height: 44)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tourist Detail Popup

    private func touristDetailPopup(_ tourist: SafetyTourist) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: 이름 + 이탈 badge + X
            HStack {
                Text(tourist.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HiTripColor.textBlack)

                if tourist.isDepartureAlert {
                    Text("이탈")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .cornerRadius(4)
                }

                Spacer()

                Button { showDetail = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(HiTripColor.gray500)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Info rows
            infoRow(label: "국가", value: tourist.country)
            infoRow(label: "여권번호", value: tourist.passportNumber)
            infoRow(label: "전화번호", value: tourist.phone)

            // 상태
            HStack {
                Text("상태")
                    .font(.system(size: 13))
                    .foregroundColor(HiTripColor.gray500)
                    .frame(width: 60, alignment: .leading)
                Text(tourist.statusText)
                    .font(.system(size: 13))
                    .foregroundColor(Color.red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            // Action buttons
            HStack(spacing: 0) {
                Button {
                    // 전화걸기
                } label: {
                    Text("전화걸기")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(HiTripColor.textBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)

                Divider().frame(height: 52)

                NavigationLink(destination: TouristLocationView()) {
                    Text("위치보기")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(HiTripColor.primary800)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.gray500)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(HiTripColor.textBlack)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
