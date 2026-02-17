import Foundation

enum DeepLink {
    case joinEvent(eventId: String, token: String)
    case match(matchId: String)
    case chat(matchId: String)

    static func parse(url: URL) -> DeepLink? {
        // Expected formats:
        // https://app.tindersoiree.com/e/{eventId}?token={token}
        // https://app.tindersoiree.com/matches/{matchId}
        // https://app.tindersoiree.com/chat/{matchId}
        // tindersoiree://join?eventId={eventId}&token={token}

        if url.scheme == "tindersoiree" {
            return parseCustomScheme(url: url)
        } else {
            return parseUniversalLink(url: url)
        }
    }

    private static func parseCustomScheme(url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        switch url.host {
        case "join":
            if let eventId = params["eventId"], let token = params["token"] {
                return .joinEvent(eventId: eventId, token: token)
            }
        case "match":
            if let matchId = params["matchId"] {
                return .match(matchId: matchId)
            }
        case "chat":
            if let matchId = params["matchId"] {
                return .chat(matchId: matchId)
            }
        default:
            break
        }

        return nil
    }

    private static func parseUniversalLink(url: URL) -> DeepLink? {
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        // /e/{eventId}?token={token}
        if pathComponents.count >= 2, pathComponents[0] == "e" {
            let eventId = pathComponents[1]
            if let token = params["token"] {
                return .joinEvent(eventId: eventId, token: token)
            }
        }

        // /matches/{matchId}
        if pathComponents.count >= 2, pathComponents[0] == "matches" {
            return .match(matchId: pathComponents[1])
        }

        // /chat/{matchId}
        if pathComponents.count >= 2, pathComponents[0] == "chat" {
            return .chat(matchId: pathComponents[1])
        }

        return nil
    }
}

@MainActor
class DeepLinkHandler: ObservableObject {
    @Published var pendingDeepLink: DeepLink?

    func handle(url: URL, appState: AppState) {
        guard let deepLink = DeepLink.parse(url: url) else {
            print("Could not parse deep link: \(url)")
            return
        }

        switch deepLink {
        case .joinEvent(let eventId, let token):
            if appState.currentUser != nil {
                Task {
                    await appState.joinEvent(eventId: eventId, token: token)
                }
            } else {
                pendingDeepLink = deepLink
            }

        case .match(let matchId):
            if appState.currentUser != nil {
                appState.navigateToMatch(matchId: matchId)
            } else {
                pendingDeepLink = deepLink
            }

        case .chat(let matchId):
            if appState.currentUser != nil {
                appState.navigateToChat(matchId: matchId)
            } else {
                pendingDeepLink = deepLink
            }
        }
    }

    func processPendingDeepLink(appState: AppState) {
        guard let deepLink = pendingDeepLink else { return }
        pendingDeepLink = nil

        switch deepLink {
        case .joinEvent(let eventId, let token):
            Task {
                await appState.joinEvent(eventId: eventId, token: token)
            }
        case .match(let matchId):
            appState.navigateToMatch(matchId: matchId)
        case .chat(let matchId):
            appState.navigateToChat(matchId: matchId)
        }
    }
}
