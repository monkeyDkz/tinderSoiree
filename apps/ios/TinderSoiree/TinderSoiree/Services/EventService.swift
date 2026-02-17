import Foundation

struct JoinEventRequest: Encodable {
    let eventId: String
    let token: String
    let source: CheckinSource
}

struct LeaveEventRequest: Encodable {
    let eventId: String
}

class EventService {
    static let shared = EventService()

    private let api = APIClient.shared

    private init() {}

    func joinEvent(eventId: String, token: String, source: CheckinSource = .deepLink) async throws -> JoinEventResponse {
        let request = JoinEventRequest(eventId: eventId, token: token, source: source)
        return try await api.post("/events/join", body: request)
    }

    func leaveEvent(eventId: String) async throws {
        let request = LeaveEventRequest(eventId: eventId)
        let _: [String: String] = try await api.post("/events/leave", body: request)
    }

    func getCurrentEvent() async throws -> CurrentEventResponse? {
        try await api.getOptional("/events/current")
    }

    func getEventHistory() async throws -> EventHistoryResponse {
        try await api.get("/events/history")
    }

    func getEvent(id: String) async throws -> Event {
        try await api.get("/events/\(id)")
    }

    func getPublicEvent(id: String) async throws -> Event {
        try await api.get("/events/\(id)/public")
    }
}
