import Foundation

enum SwipeAction: String, Codable {
    case like
    case dislike
}

struct StackProfile: Codable, Identifiable {
    let id: String
    let firstName: String
    let age: Int
    let bio: String?
    let photos: [Photo]
    let gender: Gender
}

struct StackResponse: Codable {
    let profiles: [StackProfile]
    let pagination: StackPagination
}

struct StackPagination: Codable {
    let nextCursor: String?
    let hasMore: Bool
    let remainingCount: Int
}

struct SwipeResponse: Codable {
    let swipe: SwipeInfo
    let matched: Bool
    let match: MatchInfo?
}

struct SwipeInfo: Codable {
    let id: String
    let action: SwipeAction
    let createdAt: String
}

struct MatchInfo: Codable {
    let id: String
    let user: MatchUser?
    let createdAt: String
}
