import SwiftUI
import UIKit
import AVFoundation

// MARK: - CameraPicker
/// 시스템 카메라로 사진 한 장을 찍어 돌려줍니다 — 채팅 첨부용
///
/// 권한은 띄우기 전에 `CameraPicker.requestAccess()`로 확인합니다.
/// 거부 상태에서 띄우면 검은 화면만 보이기 때문입니다.

struct CameraPicker: UIViewControllerRepresentable {

    /// 찍은 사진 — 취소하면 nil
    let onFinish: (UIImage?) -> Void

    /// 카메라를 쓸 수 있는 기기인지 (시뮬레이터는 false)
    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    /// 권한 확인 — 처음이면 시스템 팝업을 띄우고 결과를 돌려줍니다
    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:    return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default:             return false
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (UIImage?) -> Void

        init(onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            onFinish(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}
