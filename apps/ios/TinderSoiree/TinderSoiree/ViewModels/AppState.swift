import Foundation
import SwiftUI

enum AppScreen: Equatable {
    case launch
    case auth
    case noEvent
    case joinEvent(eventId: String, token: String)
    case main
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .launch
    @Published var currentUser: User?
    @Published var currentEvent: Event?
    @Published var currentCheckin: Checkin?
    @Published var pendingDeepLink: (eventId: String, token: String)?
    @Published var showMatchPopup: Bool = false
    @Published var matchedUser: MatchUser?
    @Published var currentMatchId: String?  // Match ID from recent match popup
    @Published var selectedMatchId: String?
    @Published var selectedChatMatchId: String?

    init() {
        checkAuthState()
    }

    func checkAuthState() {
        if AuthService.shared.restoreSession() {
            Task {
                await loadUserAndEvent()
            }
        } else {
            currentScreen = .auth
        }
    }

    func loadUserAndEvent() async {
        do {
            let user = try await AuthService.shared.getMe()
            currentUser = user

            if let eventResponse = try await EventService.shared.getCurrentEvent(),
               let event = eventResponse.event {
                currentEvent = event
                currentCheckin = eventResponse.checkin
                currentScreen = .main
            } else if user.isAdmin {
                // Admins can access main screen without being in an event
                currentScreen = .main
            } else {
                currentScreen = .noEvent
            }

            // Handle pending deep link
            if let pending = pendingDeepLink {
                handleDeepLink(eventId: pending.eventId, token: pending.token)
                pendingDeepLink = nil
            }
        } catch {
            print("Failed to load user: \(error)")
            currentScreen = .auth
        }
    }

    func handleDeepLink(eventId: String, token: String) {
        if currentUser != nil {
            currentScreen = .joinEvent(eventId: eventId, token: token)
        } else {
            pendingDeepLink = (eventId, token)
        }
    }

    func onLoginSuccess(user: User) {
        currentUser = user
        Task {
            await loadUserAndEvent()
        }
    }

    func onEventJoined(event: Event, checkin: Checkin) {
        currentEvent = event
        currentCheckin = checkin
        currentScreen = .main
    }

    func onEventLeft() {
        currentEvent = nil
        currentCheckin = nil
        // Admins stay on main screen, regular users go to noEvent
        if currentUser?.isAdmin == true {
            currentScreen = .main
        } else {
            currentScreen = .noEvent
        }
    }

    func onLogout() {
        AuthService.shared.logout()
        currentUser = nil
        currentEvent = nil
        currentCheckin = nil
        currentScreen = .auth
    }

    func showMatch(user: MatchUser, matchId: String) {
        matchedUser = user
        currentMatchId = matchId
        showMatchPopup = true
    }

    func dismissMatchPopup() {
        showMatchPopup = false
        matchedUser = nil
        currentMatchId = nil
    }

    func navigateToChatFromMatch() {
        guard let matchId = currentMatchId else { return }
        dismissMatchPopup()
        selectedChatMatchId = matchId
    }

    func navigateToMatch(matchId: String) {
        selectedMatchId = matchId
    }

    func navigateToChat(matchId: String) {
        selectedChatMatchId = matchId
    }

    func joinEvent(eventId: String, token: String) async {
        do {
            let response = try await EventService.shared.joinEvent(
                eventId: eventId,
                token: token,
                source: .deepLink
            )
            currentEvent = response.event
            currentCheckin = response.checkin
            currentScreen = .main
        } catch {
            print("Failed to join event: \(error)")
        }
    }
}
