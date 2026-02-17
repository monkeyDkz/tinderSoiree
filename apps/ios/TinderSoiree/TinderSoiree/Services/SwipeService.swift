import Foundation

struct CreateSwipeRequest: Encodable {
    let toUserId: String
    let eventId: String
    let action: SwipeAction
}

class SwipeService {
    static let shared = SwipeService()

    private let api = APIClient.shared

    private init() {}

    func getStack(eventId: String, limit: Int = 10, cursor: String? = nil) async throws -> StackResponse {
        var endpoint = "/events/\(eventId)/stack?limit=\(limit)"
        if let cursor = cursor {
            endpoint += "&cursor=\(cursor)"
        }
        return try await api.get(endpoint)
    }

    func swipe(toUserId: String, eventId: String, action: SwipeAction) async throws -> SwipeResponse {
        let request = CreateSwipeRequest(toUserId: toUserId, eventId: eventId, action: action)
        return try await api.post("/swipes", body: request)
    }
}
