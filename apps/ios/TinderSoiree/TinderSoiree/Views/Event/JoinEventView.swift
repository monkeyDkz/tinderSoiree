import SwiftUI

struct JoinEventView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = EventViewModel()

    let eventId: String
    let token: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                if viewModel.isLoading || viewModel.isJoining {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text(viewModel.isJoining ? "Connexion a la soiree..." : "Chargement...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                } else if let event = viewModel.event {
                    // Event info
                    VStack(spacing: 20) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text(event.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        if let description = event.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }

                        Text(event.locationName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Join button
                    Button(action: joinEvent) {
                        Text("Rejoindre la soiree")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.pink)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)

                    // Cancel button
                    Button(action: cancel) {
                        Text("Annuler")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 30)

                } else if let error = viewModel.error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Erreur")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text(error)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)

                        Button(action: cancel) {
                            Text("Retour")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.pink)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    }
                }

                Spacer()
            }
        }
        .task {
            await viewModel.loadPublicEvent(id: eventId)
        }
    }

    private func joinEvent() {
        Task {
            if await viewModel.joinEvent(eventId: eventId, token: token) {
                if let event = viewModel.event {
                    let formatter = ISO8601DateFormatter()
                    appState.onEventJoined(event: event, checkin: Checkin(
                        id: UUID().uuidString,
                        joinedAt: formatter.string(from: Date()),
                        leftAt: nil,
                        source: .deepLink
                    ))
                }
            }
        }
    }

    private func cancel() {
        if appState.currentEvent != nil {
            appState.currentScreen = .main
        } else {
            appState.currentScreen = .noEvent
        }
    }
}

#Preview {
    JoinEventView(eventId: "123", token: "abc")
        .environmentObject(AppState())
}
