import Foundation
import RxSwift

final class MockAuthRepository: AuthRepositoryProtocol {

    private let mockToken = "mock-access-token"
    private var savedToken: String? = nil

    func login(request: LoginRequest) -> Single<LoginResponse> {
        // ID에 "tourist" 포함 시 여행객, 그 외 여행사
        let userType: UserType = request.id.lowercased().contains("tourist") ? .tourist : .guide
        let user = UserInfo(id: "1", name: request.id, userType: userType, phone: nil, country: nil)
        savedToken = mockToken
        KeychainManager.shared.saveUserType(userType.rawValue)
        return .just(LoginResponse(
            accessToken: mockToken,
            refreshToken: mockToken,
            user: user,
            requiresAgreement: !AgreementRecordStore.hasAgreedOnDevice
        ))
    }

    func validateSession() -> Single<SessionState> {
        let type = UserType(rawValue: KeychainManager.shared.getUserType() ?? "") ?? .guide
        return .just(SessionState(userType: type, requiresAgreement: false))
    }

    func getSavedToken() -> String? { savedToken }

    func changeInitialPassword(username: String, currentPassword: String, newPassword: String) -> Single<Void> {
        .just(())
    }

    func logout() { savedToken = nil }
}
