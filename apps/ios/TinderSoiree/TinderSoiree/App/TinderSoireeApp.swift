import SwiftUI

@main
struct TinderSoireeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var deepLinkHandler = DeepLinkHandler()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url, appState: appState)
                }
                .task {
                    // Request notification permission on app launch
                    await NotificationService.shared.requestPermission()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToChat)) { notification in
                    if let matchId = notification.userInfo?["matchId"] as? String {
                        appState.navigateToChat(matchId: matchId)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToMatch)) { notification in
                    if let matchId = notification.userInfo?["matchId"] as? String {
                        appState.navigateToMatch(matchId: matchId)
                    }
                }
        }
    }
}
