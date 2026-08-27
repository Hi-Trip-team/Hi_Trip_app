import Foundation
import RxSwift

final class MockAuthRepository: AuthRepositoryProtocol {

    private let mockToken = "mock-access-token"
    private var savedToken: String? = nil

    func login(request: LoginRequest) -> Single<LoginResponse> {
        let user = UserInfo(id: "1", name: request.id, userType: .guide, phone: nil, country: nil)
        let response = LoginResponse(accessToken: mockToken, refreshToken: "mock-refresh-token", user: user)
        savedToken = mockToken
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
