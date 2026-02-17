import Foundation

struct ProfileUpdateRequest: Encodable {
    let bio: String?
    let photos: [PhotoUpdate]?
}

class ProfileService {
    static let shared = ProfileService()

    private let api = APIClient.shared

    private init() {}

    func updateProfile(bio: String?, photos: [PhotoUpdate]?) async throws -> User {
        let request = ProfileUpdateRequest(bio: bio, photos: photos)
        return try await api.patch("/me", body: request)
    }

    func getProfile() async throws -> User {
        try await api.get("/me")
    }
}
