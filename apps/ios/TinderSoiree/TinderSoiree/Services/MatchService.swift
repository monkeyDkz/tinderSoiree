import Foundation

class MatchService {
    static let shared = MatchService()

    private let api = APIClient.shared

    private init() {}

    func getMatches(eventId: String? = nil) async throws -> MatchesResponse {
        var endpoint = "/matches"
        if let eventId = eventId {
            endpoint += "?eventId=\(eventId)"
        }
        return try await api.get(endpoint)
    }

    func getMatch(id: String) async throws -> Match {
        try await api.get("/matches/\(id)")
    }
}
