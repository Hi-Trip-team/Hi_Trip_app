import SwiftUI

struct TripDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var showAddSheet = false
    @State private var addTitle = ""
    @State private var addMemo = ""

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    VStack(spacing: 0) {
                        // 여행 정보 카드
                        tripInfoCard
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        // 여행 진행 상태
                        progressCard
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)

                        // 1일차 헤더
                        dayHeader
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)

                        // 스케줄 아이템들
                        scheduleItems
                            .padding(.horizontal, 24)

                        // 개인 일정 추가 버튼
                        addPersonalButton
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                    }
                }
            }
            .background(Color.white)

            // 바텀 시트
            if showAddSheet {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { showAddSheet = false }

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
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            Text("여행 일정")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
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

    // MARK: - 여행 정보

    private var tripInfoCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("뉴진스 바다여행")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
            Text("2025.04.24 - 04.26")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .frame(height: 84)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
    }

    // MARK: - 진행상태

    private var progressCard: some View {
        HStack {
            Text("현재 진행 중")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
    }

    // MARK: - 일차 헤더

    private var dayHeader: some View {
        HStack {
            Text("1일차")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 24)
                .background(Color(hex: "#2563EB"))
                .cornerRadius(6)
            Text("2025.04.24 12:00 출발")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#111827"))
            Spacer()
            Text("∧")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6B7280"))
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color(hex: "#E8F0FF"))
        .cornerRadius(12)
    }

    // MARK: - 스케줄 아이템

    private var scheduleItems: some View {
        VStack(spacing: 8) {
            touristScheduleRow(title: "숙소로 이동", time: "09:00 - 10:00")
            touristScheduleRow(title: "부산시민공원", time: "10:00 - 11:30")
            touristScheduleRow(title: "포폴로피자 (중식)", time: "12:00 - 13:30")
        }
    }

    private func touristScheduleRow(title: String, time: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#111827"))
                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E5E7EB"), lineWidth: 1))
    }

    // MARK: - 개인 일정 추가 버튼

    private var addPersonalButton: some View {
        Button { showAddSheet = true } label: {
            Text("+ 개인 일정 추가")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#2563EB"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#6B7280").opacity(0.5),
                                style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 개인 일정 추가 시트

    private var addScheduleSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 핸들
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

            // 제목 필드
            VStack(alignment: .leading, spacing: 6) {
                Text("제목")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.horizontal, 24)

                TextField("예: 기념품 쇼핑", text: $addTitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#111827"))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color(hex: "#F3F4F6"))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            // 시간 선택
            VStack(alignment: .leading, spacing: 6) {
                Text("시간")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    timeField(label: "시작  20:00")
                    timeField(label: "종료  21:00")
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            // 메모 필드
            TextField("메모 (선택 · 100자)", text: $addMemo)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7280"))
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(12)
                .padding(.horizontal, 24)

            // 경고
            Text("⚠ 공용 일정과 겹칩니다 (18:00 호텔 로비 집합)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#EB8C0D"))
                .padding(.horizontal, 24)
                .padding(.top, 10)

            // 저장 버튼
            Button { showAddSheet = false } label: {
                Text("저장")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 34)
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

private func timeField(label: String) -> some View {
    Text(label)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(Color(hex: "#111827"))
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color(hex: "#F3F4F6"))
        .cornerRadius(12)
}
