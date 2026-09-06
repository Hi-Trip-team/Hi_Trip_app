import SwiftUI

struct SafetyTourist: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let country: String
    let passportNumber: String
    var isDeparted: Bool
    var departureDistance: Double?
    var heartRate: Int
    var spo2: Int

    var isDepartureAlert: Bool { isDeparted || (departureDistance ?? 0) > 0 }

    // 심박: >=150 위험, >100 경고
    var heartRateLevel: AlertLevel {
        if heartRate >= 150 || heartRate < 50 { return .danger }
        if heartRate > 100 { return .warning }
        return .normal
    }

    // SpO₂: <90 위험, <95 경고
    var spo2Level: AlertLevel {
        if spo2 < 90 { return .danger }
        if spo2 < 95 { return .warning }
        return .normal
    }

    var overallLevel: AlertLevel {
        if isDepartureAlert || heartRateLevel == .danger || spo2Level == .danger { return .danger }
        if heartRateLevel == .warning || spo2Level == .warning { return .warning }
        return .normal
    }

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

enum AlertLevel { case normal, warning, danger }

struct SafetyManagementView: View {

    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)? = nil
    @State private var selectedTourist: SafetyTourist?
    @State private var showDetail = false
    @State private var navigateToLocation = false
    @State private var showPassport = false

    private let tourists: [SafetyTourist] = [
        SafetyTourist(name: "이연세", phone: "010-1234-5678", country: "대한민국",
                      passportNumber: "DND***000", isDeparted: false,
                      departureDistance: nil, heartRate: 72, spo2: 97),
        SafetyTourist(name: "둘리", phone: "010-2345-6789", country: "대한민국",
                      passportNumber: "KIM***123", isDeparted: true,
                      departureDistance: 1.2, heartRate: 110, spo2: 95),
        SafetyTourist(name: "펭수", phone: "010-3456-7890", country: "대한민국",
                      passportNumber: "PAK***456", isDeparted: false,
                      departureDistance: nil, heartRate: 135, spo2: 94),
        SafetyTourist(name: "뽀로로", phone: "010-4567-8901", country: "대한민국",
                      passportNumber: "JEO***789", isDeparted: false,
                      departureDistance: nil, heartRate: 88, spo2: 98),
        SafetyTourist(name: "에디", phone: "010-5678-9012", country: "대한민국",
                      passportNumber: "CHO***012", isDeparted: false,
                      departureDistance: nil, heartRate: 187, spo2: 91),
    ]

    private var sorted: [SafetyTourist] {
        tourists.sorted { a, b in levelPriority(a) > levelPriority(b) }
    }

    private func levelPriority(_ t: SafetyTourist) -> Int {
        switch t.overallLevel {
        case .danger: return 2
        case .warning: return 1
        case .normal: return 0
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                pillsRow
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                timestampRow
                    .padding(.horizontal, 24)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                tableSection
                    .padding(.horizontal, 24)
                legendSection
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                Spacer()
            }
            .background(Color.white)
            .navigationBarHidden(true)

            if showDetail, let tourist = selectedTourist {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { showDetail = false }
                touristDetailPopup(tourist)
                    .padding(.horizontal, 24)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDetail)
        .navigationDestination(isPresented: $navigateToLocation) {
            TouristLocationView(touristName: selectedTourist?.name ?? "")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("안전 관리")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            HStack {
                Button {
                    if let onDismiss { onDismiss() }
                    else { dismiss() }
                } label: {
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

    // MARK: - Pills

    private var pillsRow: some View {
        HStack(spacing: 8) {
            pill(label: "전체 \(tourists.count)", bg: Color(hex: "#F3F4F6"), fg: Color(hex: "#333840"))
            pill(label: "경고 \(tourists.filter { $0.overallLevel == .warning }.count)",
                 bg: Color(hex: "#FFF2D9"), fg: Color(hex: "#EB8C0D"))
            pill(label: "위험 \(tourists.filter { $0.overallLevel == .danger && !$0.isDepartureAlert }.count)",
                 bg: Color(hex: "#FCE5E5"), fg: Color(hex: "#EF4444"))
            pill(label: "이탈 \(tourists.filter { $0.isDepartureAlert }.count)",
                 bg: Color(hex: "#FCE5E5"), fg: Color(hex: "#EF4444"))
            Spacer()
        }
    }

    private func pill(label: String, bg: Color, fg: Color) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(fg)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(bg)
            .cornerRadius(16)
    }

    // MARK: - Timestamp

    private var timestampRow: some View {
        HStack {
            Spacer()
            Text("\(Date().formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())) 기준 · 30초마다 갱신")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#6B7280"))
        }
    }

    // MARK: - 테이블

    private var tableSection: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider()
            ForEach(sorted) { t in
                tableRow(t)
                Divider()
            }
        }
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("이름").frame(width: 52)
            Divider().frame(height: 36)
            Text("연락처").frame(maxWidth: .infinity)
            Divider().frame(height: 36)
            Text("이탈여부").frame(width: 52)
            Divider().frame(height: 36)
            Text("심박수").frame(width: 44)
            Divider().frame(height: 36)
            Text("SpO₂").frame(width: 44)
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(Color(hex: "#6B7280"))
        .frame(height: 36)
        .background(Color(hex: "#F9FAFB"))
    }

    private func tableRow(_ t: SafetyTourist) -> some View {
        Button {
            selectedTourist = t
            showPassport = false
            showDetail = true
        } label: {
            HStack(spacing: 0) {
                // 이름 (파랑)
                Text(t.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#2563EB"))
                    .frame(width: 52)

                Divider().frame(height: 44)

                // 연락처
                Text(t.phone)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(maxWidth: .infinity)

                Divider().frame(height: 44)

                // 이탈여부
                if let dist = t.departureDistance, dist > 0 {
                    Text("\(String(format: "%.1f", dist))km")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 4)
                        .frame(height: 20)
                        .background(Color(hex: "#FCE5E5"))
                        .cornerRadius(6)
                        .frame(width: 52)
                } else {
                    Text("정상")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#333840"))
                        .frame(width: 52)
                }

                Divider().frame(height: 44)

                // 심박수
                alertCell(value: "\(t.heartRate)", level: t.heartRateLevel, width: 44)

                Divider().frame(height: 44)

                // SpO₂
                alertCell(value: "\(t.spo2)", level: t.spo2Level, width: 44)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    private func alertCell(value: String, level: AlertLevel, width: CGFloat) -> some View {
        Group {
            switch level {
            case .danger:
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .padding(.horizontal, 4)
                    .frame(height: 20)
                    .background(Color(hex: "#FCE5E5"))
                    .cornerRadius(6)
            case .warning:
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#EB8C0D"))
                    .padding(.horizontal, 4)
                    .frame(height: 20)
                    .background(Color(hex: "#FFF2D9"))
                    .cornerRadius(6)
            case .normal:
                Text(value)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#333840"))
            }
        }
        .frame(width: width)
    }

    // MARK: - 범례

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("경고(주황) · 위험(빨강) · — 데이터 수신 안 됨(워치 미연동·통신 두절)")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#6B7280"))
            Text("정렬: 위험 → 경고 → 정상 · 행 탭 시 관광객 정보 팝업")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 상세 팝업

    private func touristDetailPopup(_ t: SafetyTourist) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(t.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "#111827"))
                if t.isDepartureAlert {
                    Text("이탈")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444"))
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(Color(hex: "#FCE5E5"))
                        .cornerRadius(6)
                }
                Spacer()
                Button { showDetail = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            detailRow("국가", t.country)
            passportRow(t.passportNumber)
            detailRow("전화번호", t.phone)

            HStack {
                Text("상태")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(width: 60, alignment: .leading)
                Text(t.statusText)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#EF4444"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            HStack(spacing: 0) {
                Button { } label: {
                    Text("전화걸기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#111827"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#F3F4F6"))
                }
                .buttonStyle(.plain)

                Button {
                    showDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigateToLocation = true
                    }
                } label: {
                    Text("위치보기")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
            }
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
    }

    /// 여권번호 — 기본 마스킹, 👁 탭 시 전체 표시
    private func passportRow(_ masked: String) -> some View {
        HStack {
            Text("여권번호")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 60, alignment: .leading)
            Text(showPassport ? masked.replacingOccurrences(of: "***", with: "123") : masked)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#111827"))
            Button { showPassport.toggle() } label: {
                Image(systemName: showPassport ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#111827"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
