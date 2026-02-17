import Foundation

@MainActor
class EventViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading = false
    @Published var isJoining = false
    @Published var error: String?

    private let eventService = EventService.shared

    func loadCurrentEvent() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await eventService.getCurrentEvent()
            event = response?.event
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func loadPublicEvent(id: String) async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            event = try await eventService.getPublicEvent(id: id)
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func joinEvent(eventId: String, token: String, source: CheckinSource = .deepLink) async -> Bool {
        guard !isJoining else { return false }

        isJoining = true
        error = nil

        do {
            let response = try await eventService.joinEvent(eventId: eventId, token: token, source: source)
            event = response.event
            isJoining = false
            return true
        } catch {
            isJoining = false
            self.error = error.localizedDescription
            return false
        }
    }

    func leaveEvent() async -> Bool {
        guard let eventId = event?.id else { return false }

        do {
            try await eventService.leaveEvent(eventId: eventId)
            event = nil
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
