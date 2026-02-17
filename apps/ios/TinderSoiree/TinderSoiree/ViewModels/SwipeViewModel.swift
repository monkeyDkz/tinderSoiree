import Foundation

@MainActor
class SwipeViewModel: ObservableObject {
    @Published var profiles: [StackProfile] = []
    @Published var isLoading = false
    @Published var error: String?

    private var nextCursor: String?
    private var hasMore = true
    private let swipeService = SwipeService.shared

    func loadStack(eventId: String) async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await swipeService.getStack(eventId: eventId)
            profiles = response.profiles
            nextCursor = response.pagination.nextCursor
            hasMore = response.pagination.hasMore
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func loadMore(eventId: String) async {
        guard !isLoading, hasMore, let cursor = nextCursor else { return }

        isLoading = true

        do {
            let response = try await swipeService.getStack(eventId: eventId, cursor: cursor)
            profiles.append(contentsOf: response.profiles)
            nextCursor = response.pagination.nextCursor
            hasMore = response.pagination.hasMore
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    func swipe(toUserId: String, eventId: String, action: SwipeAction) async -> (matched: Bool, matchedUser: MatchUser?, matchId: String?) {
        do {
            let response = try await swipeService.swipe(
                toUserId: toUserId,
                eventId: eventId,
                action: action
            )

            // Remove swiped profile
            profiles.removeAll { $0.id == toUserId }

            // Load more if needed
            if profiles.count < 3 && hasMore {
                await loadMore(eventId: eventId)
            }

            return (response.matched, response.match?.user, response.match?.id)
        } catch {
            self.error = error.localizedDescription
            return (false, nil, nil)
        }
    }

    func removeTopProfile() {
        guard !profiles.isEmpty else { return }
        profiles.removeFirst()
    }
}
