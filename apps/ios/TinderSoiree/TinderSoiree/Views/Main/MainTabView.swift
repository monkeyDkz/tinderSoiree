import SwiftUI

enum Tab {
    case swipe
    case matches
    case profile
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .swipe

    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Swipe")
                }
                .tag(Tab.swipe)

            MatchesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Matches")
                }
                .tag(Tab.matches)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(Tab.profile)
        }
        .tint(AppTheme.primaryPink)
        .onChange(of: appState.selectedMatchId) { _, matchId in
            if matchId != nil {
                selectedTab = .matches
            }
        }
        .onChange(of: appState.selectedChatMatchId) { _, matchId in
            if matchId != nil {
                selectedTab = .matches
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
