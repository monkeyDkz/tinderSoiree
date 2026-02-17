import Foundation

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let firstName: String
    let birthDate: String
    let gender: Gender
    let orientation: Orientation
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

class AuthService {
    static let shared = AuthService()

    private let api = APIClient.shared
    private let keychain = KeychainManager.shared

    private init() {}

    func register(
        email: String,
        password: String,
        firstName: String,
        birthDate: Date,
        gender: Gender,
        orientation: Orientation
    ) async throws -> AuthResponse {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            birthDate: formatter.string(from: birthDate),
            gender: gender,
            orientation: orientation
        )

        let response: AuthResponse = try await api.post("/auth/register", body: request)

        saveTokens(response.tokens)
        api.setToken(response.tokens.accessToken)

        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)

        let response: AuthResponse = try await api.post("/auth/login", body: request)

        saveTokens(response.tokens)
        api.setToken(response.tokens.accessToken)

        return response
    }

    func logout() {
        _ = keychain.delete(KeychainManager.accessTokenKey)
        _ = keychain.delete(KeychainManager.refreshTokenKey)
        api.setToken(nil)
    }

    func restoreSession() -> Bool {
        guard let token = keychain.get(KeychainManager.accessTokenKey) else {
            return false
        }

        api.setToken(token)
        return true
    }

    func getMe() async throws -> User {
        try await api.get("/me")
    }

    private func saveTokens(_ tokens: AuthTokens) {
        _ = keychain.save(tokens.accessToken, for: KeychainManager.accessTokenKey)
        _ = keychain.save(tokens.refreshToken, for: KeychainManager.refreshTokenKey)
    }
}
