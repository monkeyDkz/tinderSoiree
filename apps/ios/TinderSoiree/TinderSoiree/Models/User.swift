import Foundation

enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case nonBinary = "non_binary"
    case other
}

enum Orientation: String, Codable, CaseIterable {
    case men
    case women
    case everyone
}

enum UserRole: String, Codable {
    case user
    case admin = "ADMIN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()
        switch value {
        case "user": self = .user
        case "admin": self = .admin
        default: self = .user
        }
    }
}

struct Photo: Codable, Identifiable {
    var id: String { url }
    let url: String
    let position: Int?
    let isMain: Bool?
}

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let firstName: String
    let birthDate: String
    let gender: Gender
    let orientation: Orientation
    let bio: String?
    let photos: [Photo]
    let isVerified: Bool?
    let createdAt: String?
    let role: UserRole?

    var isAdmin: Bool {
        role == .admin
    }

    var age: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: birthDate) else { return 0 }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }

    var mainPhoto: Photo? {
        photos.first { $0.isMain == true } ?? photos.first
    }
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct AuthResponse: Codable {
    let user: User
    let tokens: AuthTokens
}
