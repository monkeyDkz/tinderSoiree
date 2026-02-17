import SwiftUI

// MARK: - Local Theme (fallback if Theme.swift not in target)
private struct LocalTheme {
    static let primaryPurple = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let primaryPink = Color(red: 0.925, green: 0.286, blue: 0.6)
    static let deepBlack = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let darkGray = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let cardBackground = Color(red: 0.122, green: 0.122, blue: 0.137)
    static let inputBackground = Color(red: 0.173, green: 0.173, blue: 0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    static let success = Color(red: 0.063, green: 0.725, blue: 0.506)
    static let error = Color(red: 0.937, green: 0.267, blue: 0.267)
    static let warning = Color(red: 0.961, green: 0.62, blue: 0.043)
    static let primaryGradient = LinearGradient(
        colors: [primaryPurple, primaryPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
}

struct SwipeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SwipeViewModel()
    @State private var eventHistory: [EventHistoryItem] = []
    @State private var selectedEventId: String?
    @State private var isLoadingEvents = true
    @State private var selectedProfile: StackProfile?
    @State private var showProfileDetail = false

    var selectedEvent: Event? {
        eventHistory.first { $0.event.id == selectedEventId }?.event
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LocalTheme.deepBlack
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Event selector
                    if !eventHistory.isEmpty {
                        EventSelectorView(
                            events: eventHistory.map { $0.event },
                            selectedEventId: $selectedEventId
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    // Main content
                    ZStack {
                        if isLoadingEvents {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(LocalTheme.primaryPink)
                                    .scaleEffect(1.2)
                                Text("Chargement des soirees...")
                                    .foregroundColor(LocalTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if eventHistory.isEmpty {
                            if appState.currentUser?.isAdmin == true {
                                AdminNoEventsView()
                            } else {
                                NoEventsView()
                            }
                        } else if selectedEventId == nil {
                            SelectEventPromptView()
                        } else if viewModel.isLoading && viewModel.profiles.isEmpty {
                            ProgressView()
                                .tint(LocalTheme.primaryPink)
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.profiles.isEmpty {
                            EmptyStackView()
                        } else {
                            CardStackView(
                                profiles: viewModel.profiles,
                                onSwipe: handleSwipe,
                                onTap: { profile in
                                    selectedProfile = profile
                                    showProfileDetail = true
                                }
                            )
                        }

                        if let error = viewModel.error {
                            VStack {
                                Spacer()
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(error)
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding()
                                .background(LocalTheme.error.cornerRadius(8))
                                .padding()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(selectedEvent?.name ?? "Swipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(LocalTheme.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showProfileDetail) {
            if let profile = selectedProfile {
                ProfileDetailView(
                    profile: profile,
                    onLike: {
                        handleSwipe(profile: profile, action: .like)
                    },
                    onDislike: {
                        handleSwipe(profile: profile, action: .dislike)
                    }
                )
            }
        }
        .task {
            await loadEventHistory()
        }
        .onChange(of: selectedEventId) { _, newEventId in
            if let eventId = newEventId {
                Task {
                    await viewModel.loadStack(eventId: eventId)
                }
            }
        }
    }

    private func loadEventHistory() async {
        isLoadingEvents = true
        do {
            let response = try await EventService.shared.getEventHistory()
            eventHistory = response.events

            // Auto-select current event or first event
            if let currentEventId = appState.currentEvent?.id,
               eventHistory.contains(where: { $0.event.id == currentEventId }) {
                selectedEventId = currentEventId
            } else if let firstEvent = eventHistory.first {
                selectedEventId = firstEvent.event.id
            }
        } catch {
            print("Failed to load event history: \(error)")
        }
        isLoadingEvents = false
    }

    private func handleSwipe(profile: StackProfile, action: SwipeAction) {
        guard let eventId = selectedEventId else { return }

        Task {
            let result = await viewModel.swipe(
                toUserId: profile.id,
                eventId: eventId,
                action: action
            )

            if result.matched, let matchedUser = result.matchedUser, let matchId = result.matchId {
                appState.showMatch(user: matchedUser, matchId: matchId)
            }
        }
    }
}

// MARK: - Event Selector

struct EventSelectorView: View {
    let events: [Event]
    @Binding var selectedEventId: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(events) { event in
                    EventChip(
                        event: event,
                        isSelected: selectedEventId == event.id,
                        onTap: { selectedEventId = event.id }
                    )
                }
            }
        }
    }
}

struct EventChip: View {
    let event: Event
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Event icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : LocalTheme.inputBackground)
                        .frame(width: 28, height: 28)

                    Image(systemName: "party.popper.fill")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : LocalTheme.primaryPink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if let count = event.participantCount {
                        Text("\(count) participants")
                            .font(.caption2)
                            .opacity(0.8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LocalTheme.primaryGradient
                    } else {
                        LocalTheme.cardBackground
                    }
                }
            )
            .foregroundColor(isSelected ? .white : LocalTheme.textPrimary)
            .cornerRadius(LocalTheme.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: LocalTheme.cornerRadiusLarge)
                    .stroke(
                        isSelected ? Color.clear : LocalTheme.primaryPurple.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? LocalTheme.primaryPurple.opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Empty States

struct NoEventsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LocalTheme.cardBackground)
                    .frame(width: 120, height: 120)

                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundStyle(LocalTheme.primaryGradient)
            }

            VStack(spacing: 12) {
                Text("Aucune soiree")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Tu n'as pas encore participe a une soiree.\nScanne un QR code pour rejoindre !")
                    .font(.body)
                    .foregroundColor(LocalTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SelectEventPromptView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LocalTheme.cardBackground)
                    .frame(width: 120, height: 120)

                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LocalTheme.primaryGradient)
            }

            VStack(spacing: 12) {
                Text("Choisis une soiree")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Selectionne une soiree ci-dessus\npour voir les profils")
                    .font(.body)
                    .foregroundColor(LocalTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyStackView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LocalTheme.cardBackground)
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LocalTheme.primaryGradient)
            }

            VStack(spacing: 12) {
                Text("Plus de profils")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Tu as vu tous les participants.\nReviens plus tard !")
                    .font(.body)
                    .foregroundColor(LocalTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct AdminNoEventsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LocalTheme.cardBackground)
                    .frame(width: 120, height: 120)

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LocalTheme.primaryGradient)
            }

            VStack(spacing: 12) {
                Text("Mode Organisateur")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Créez votre première soirée\ndans l'onglet Profil pour commencer\nà accueillir des participants.")
                    .font(.body)
                    .foregroundColor(LocalTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Visual hint
            HStack(spacing: 8) {
                Image(systemName: "arrow.down")
                Text("Onglet Profil")
                Image(systemName: "person.fill")
            }
            .font(.subheadline.bold())
            .foregroundStyle(LocalTheme.primaryGradient)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    SwipeView()
        .environmentObject(AppState())
}
