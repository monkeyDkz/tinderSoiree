import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .launch:
                LaunchView()

            case .auth:
                AuthContainerView()

            case .noEvent:
                NoEventView()

            case .joinEvent(let eventId, let token):
                JoinEventView(eventId: eventId, token: token)

            case .main:
                MainTabView()
            }

            // Match popup overlay
            if appState.showMatchPopup, let matchedUser = appState.matchedUser {
                MatchPopupView(matchedUser: matchedUser)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut, value: appState.currentScreen)
    }
}

struct LaunchView: View {
    @State private var flameScale: CGFloat = 0.8
    @State private var flameOpacity: Double = 0.5
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.deepBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated flame
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.primaryPink.opacity(0.4),
                                    AppTheme.primaryPurple.opacity(0.2),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                        .scaleEffect(flameScale)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(AppTheme.primaryGradient)
                        .shadow(color: AppTheme.primaryPink.opacity(0.6), radius: 20)
                        .scaleEffect(flameScale)
                }
                .opacity(flameOpacity)

                VStack(spacing: 8) {
                    Text("Tinder Soirée")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Trouve ton match ce soir")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .opacity(textOpacity)

                ProgressView()
                    .tint(AppTheme.primaryPink)
                    .scaleEffect(1.2)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                flameScale = 1.0
                flameOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
