import SwiftUI
import RxSwift

// MARK: - EmergencyCallDialog
/// 긴급 통역 연결 — 홈의 "긴급 즉시 연락" 버튼으로 뜨는 팝업
///
/// 별도 화면이 아니라 홈 위에 겹쳐 띄웁니다.
/// 긴급 버튼이라 한 번 탭에 바로 걸지 않고 이 확인 단계를 거칩니다 (오발신 방지).
///
/// 전화하기를 누르면
/// 1) POST /api/v1/tourist/emergency-requests/ 로 담당 안내사에게 요청을 남기고
/// 2) OS 다이얼러로 넘깁니다 (인앱 통화가 아닙니다)
///
/// 통역 센터 번호와 운영시간은 아직 확정 전이라, 번호는 홈 응답의
/// manager_contact를, 운영시간은 아래 기본값을 씁니다.

struct EmergencyCallDialog: View {

    @Binding var isPresented: Bool

    /// 연결할 전화번호. 없으면 "전화하기"를 누를 수 없습니다.
    var phoneNumber: String?
    /// 운영 시작·종료 시각 (현지 기준, 24시간)
    var openHour: Int = 9
    var closeHour: Int = 22
    /// "안내사에게 메시지" — 메시지 목록으로 보냅니다
    var onMessageGuide: (() -> Void)?

    @State private var isSending = false
    private let disposeBag = DisposeBag()

    private var repository: TravelerRepositoryProtocol {
        AppDIContainer.shared.travelerRepositoryForHome
    }

    /// 운영시간 안이면 전화 안내, 밖이면 대체 동선을 보여줍니다
    private var isWithinOperatingHours: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= openHour && hour < closeHour
    }

    private var operatingHoursText: String {
        String(format: "%02d:00 - %02d:00", openHour, closeHour)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            dialogCard
        }
    }

    private var dialogCard: some View {
        VStack(spacing: 0) {
            Text("☎")
                .font(.system(size: 26))
                .foregroundColor(Color(hex: "#EF4444"))
                .padding(.top, 24)

            Text(isWithinOperatingHours ? "긴급 통역 연결" : "지금은 연결이 어려워요")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#111827"))
                .padding(.top, 16)

            VStack(spacing: 2) {
                if !isWithinOperatingHours {
                    Text("통역 센터 운영시간이 아닙니다")
                } else if canCall {
                    Text("통역사에게 바로 전화를 연결할까요?")
                } else {
                    Text("연결할 수 있는 번호가 없습니다")
                }
                Text("운영시간 \(operatingHoursText) (현지 기준)")
            }
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "#333840"))
            .multilineTextAlignment(.center)
            .padding(.top, 14)

            HStack(spacing: 10) {
                Button { isPresented = false } label: {
                    Text("취소")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#333840"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                if isWithinOperatingHours {
                    Button { call() } label: {
                        Group {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Text("전화하기")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(canCall ? Color(hex: "#EF4444") : Color(hex: "#C3CDDA"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCall || isSending)
                } else {
                    // 운영시간 밖에는 담당 안내사에게 메시지를 보내도록 유도합니다
                    Button {
                        isPresented = false
                        onMessageGuide?()
                    } label: {
                        Text("안내사에게 메시지")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#2563EB"))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 22)
        }
        .frame(width: 310)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var canCall: Bool {
        guard let phoneNumber else { return false }
        return !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 안내사에게 요청을 남기고 전화 앱으로 넘깁니다.
    /// 요청 전송이 실패해도 전화는 겁니다 — 긴급 상황에서 발신이 막히면 안 됩니다.
    private func call() {
        guard let phoneNumber else { return }
        isSending = true

        repository.sendEmergencyRequest(
            message: "긴급 통역을 요청했습니다",
            latitude: nil,
            longitude: nil,
            accuracyM: nil
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { _ in dial(phoneNumber) },
            onFailure: { _ in dial(phoneNumber) }
        )
        .disposed(by: disposeBag)
    }

    private func dial(_ number: String) {
        isSending = false
        let digits = number.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        isPresented = false
    }
}
