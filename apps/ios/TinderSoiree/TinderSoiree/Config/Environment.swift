import Foundation

struct AppEnvironment {
    let apiURL: String
    let wsURL: String

    static let current: AppEnvironment = {
        #if DEBUG
        return AppEnvironment(
            apiURL: "https://bryant-tinniest-shaunta.ngrok-free.dev/api/v1",
            wsURL: "wss://bryant-tinniest-shaunta.ngrok-free.dev"
        )
        #else
        return AppEnvironment(
            apiURL: "https://api.tindersoiree.com/api/v1",
            wsURL: "wss://api.tindersoiree.com"
        )
        #endif
    }()

    static let appScheme = "tindersoiree"
    static let appHost = "app.tindersoiree.com"
}
