import Foundation

@MainActor
class MatchesViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var error: String?

    private let matchService = MatchService.shared

    func loadMatches(eventId: String? = nil) async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await matchService.getMatches(eventId: eventId)
            matches = response.matches
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func refreshMatches(eventId: String? = nil) async {
        do {
            let response = try await matchService.getMatches(eventId: eventId)
            matches = response.matches
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addMatch(_ match: Match) {
        if !matches.contains(where: { $0.id == match.id }) {
            matches.insert(match, at: 0)
        }
    }

    func updateLastMessage(matchId: String, message: LastMessage) {
        if let index = matches.firstIndex(where: { $0.id == matchId }) {
            var updatedMatch = matches[index]
            updatedMatch.lastMessage = message
            matches[index] = updatedMatch
            // Re-sort by last message time
            matches.sort { ($0.lastMessage?.sentAt ?? $0.createdAt) > ($1.lastMessage?.sentAt ?? $1.createdAt) }
        }
    }
}
