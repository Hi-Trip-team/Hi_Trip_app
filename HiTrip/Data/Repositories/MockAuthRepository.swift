import Foundation
import RxSwift

final class MockAuthRepository: AuthRepositoryProtocol {

    private let mockToken = "mock-access-token"
    private var savedToken: String? = nil

    func login(request: LoginRequest) -> Single<LoginResponse> {
        // ID에 "tourist" 포함 시 여행객, 그 외 여행사
        let userType: UserType = request.id.lowercased().contains("tourist") ? .tourist : .guide
        let user = UserInfo(id: "1", name: request.id, userType: userType, phone: nil, country: nil)
        let response = LoginResponse(accessToken: mockToken, refreshToken: "mock-refresh-token", user: user)
        savedToken = mockToken
        KeychainManager.shared.saveUserType(userType.rawValue)
        return .just(response)
    }

    func refreshToken() -> Single<LoginResponse> {
        let user = UserInfo(id: "1", name: "admin", userType: .guide, phone: nil, country: nil)
        return .just(LoginResponse(accessToken: mockToken, refreshToken: "mock-refresh-token", user: user))
    }

    func getSavedToken() -> String? { savedToken }

    func logout() { savedToken = nil }

    func checkNickname(_ nickname: String) -> Single<NicknameCheckResponse> {
        .just(NicknameCheckResponse(isAvailable: true, message: nil))
    }

    func signUp(request: SignUpRequest) -> Single<SignUpResponse> {
        let user = UserInfo(id: "1", name: request.nickname, userType: .guide, phone: nil, country: nil)
        return .just(SignUpResponse(message: "ok", user: user))
    }
}
