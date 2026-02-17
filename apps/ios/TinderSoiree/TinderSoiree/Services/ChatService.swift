import Foundation

struct SendMessageRequest: Encodable {
    let content: String
}

struct MarkReadRequest: Encodable {
    let upToMessageId: String
}

struct SendMessageResponse: Decodable {
    let message: Message
}

struct MarkReadResponse: Decodable {
    let readCount: Int
}

class ChatService {
    static let shared = ChatService()

    private let api = APIClient.shared

    private init() {}

    func getMessages(matchId: String, limit: Int = 50, before: String? = nil) async throws -> MessagesResponse {
        var endpoint = "/matches/\(matchId)/messages?limit=\(limit)"
        if let before = before {
            endpoint += "&before=\(before)"
        }
        return try await api.get(endpoint)
    }

    func sendMessage(matchId: String, content: String) async throws -> SendMessageResponse {
        let request = SendMessageRequest(content: content)
        return try await api.post("/matches/\(matchId)/messages", body: request)
    }

    func markAsRead(matchId: String, upToMessageId: String) async throws -> MarkReadResponse {
        let request = MarkReadRequest(upToMessageId: upToMessageId)
        return try await api.patch("/matches/\(matchId)/messages/read", body: request)
    }
}
