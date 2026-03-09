import Foundation

// MARK: - String 유틸리티 Extension

extension String {

    /// 앞뒤 공백 제거 — 입력값 검증에 공통으로 사용
    ///
    /// 사용 예시:
    /// ```
    /// "  홍길동  ".trimmed  // "홍길동"
    /// "".trimmed.isEmpty    // true
    /// ```
    ///
    /// 설계 의도:
    /// - LoginUseCase, SignUpUseCase 등에서 반복되는 공백 제거 로직을 공유
    /// - computed property로 만들어 체이닝 가능: id.trimmed.isEmpty
    var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }
}
