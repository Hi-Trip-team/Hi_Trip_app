import Foundation

extension Encodable {
    /// Encodable 구조체를 [String: Any] 딕셔너리로 변환.
    /// APIEndpoint body 파라미터 주입에 사용.
    func asDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard
            let data = try? encoder.encode(self),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return dict
    }
}
