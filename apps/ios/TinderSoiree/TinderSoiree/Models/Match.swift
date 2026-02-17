import Foundation

struct MatchUser: Codable, Identifiable {
    let id: String
    let firstName: String
    let photos: [Photo]
    let bio: String?
    let age: Int?
}

struct LastMessage: Codable {
    let content: String
    let sentAt: String
    let isFromMe: Bool
}

struct Match: Codable, Identifiable, Hashable {
    let id: String
    let user: MatchUser
    let eventId: String?
    let event: MatchEvent?
    var lastMessage: LastMessage?
    let unreadCount: Int?
    let createdAt: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id
    }
}

struct MatchEvent: Codable {
    let id: String
    let name: String
}

struct MatchesResponse: Codable {
    let matches: [Match]
}

struct Message: Codable, Identifiable {
    let id: String
    let content: String
    let senderId: String
    let isFromMe: Bool
    let readAt: String?
    let createdAt: String
}

struct MessagesResponse: Codable {
    let messages: [Message]
    let pagination: MessagePagination
}

struct MessagePagination: Codable {
    let hasMore: Bool
    let oldestCursor: String?
}
