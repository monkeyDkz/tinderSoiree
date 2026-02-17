import SwiftUI

struct MatchesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MatchesViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppTheme.deepBlack
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.matches.isEmpty {
                        ProgressView()
                            .tint(AppTheme.primaryPink)
                    } else if viewModel.matches.isEmpty {
                        EmptyMatchesView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(viewModel.matches) { match in
                                    NavigationLink(value: match) {
                                        MatchRowView(match: match)
                                    }
                                }
                            }
                        }
                        .refreshable {
                            await viewModel.refreshMatches(eventId: appState.currentEvent?.id)
                        }
                    }
                }
            }
            .navigationTitle("Matches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: Match.self) { match in
                ChatView(match: match)
            }
        }
        .task {
            await viewModel.loadMatches(eventId: appState.currentEvent?.id)
        }
        .onChange(of: appState.selectedChatMatchId) { _, matchId in
            if let matchId = matchId {
                // Find the match and navigate to chat
                if let match = viewModel.matches.first(where: { $0.id == matchId }) {
                    navigationPath.append(match)
                } else {
                    // Match not loaded yet, refresh and try again
                    Task {
                        await viewModel.refreshMatches(eventId: appState.currentEvent?.id)
                        if let match = viewModel.matches.first(where: { $0.id == matchId }) {
                            navigationPath.append(match)
                        }
                    }
                }
                // Clear the selectedChatMatchId
                appState.selectedChatMatchId = nil
            }
        }
    }
}

// MARK: - Empty State

struct EmptyMatchesView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.primaryGradient)
            }

            VStack(spacing: 8) {
                Text("Pas encore de match")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Continue à swiper pour\ntrouver des matches !")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Match Row

struct MatchRowView: View {
    let match: Match

    var body: some View {
        HStack(spacing: 14) {
            // Profile photo
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let photoUrl = match.user.photos.first?.url,
                       let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Circle()
                                    .fill(AppTheme.cardBackground)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                            }
                        }
                    } else {
                        Circle()
                            .fill(AppTheme.cardBackground)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            (match.unreadCount ?? 0) > 0
                                ? AppTheme.primaryGradient
                                : LinearGradient(colors: [AppTheme.cardBackground], startPoint: .top, endPoint: .bottom),
                            lineWidth: 2
                        )
                )

                // Unread indicator
                if (match.unreadCount ?? 0) > 0 {
                    Circle()
                        .fill(AppTheme.primaryPink)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Text("\(match.unreadCount ?? 0)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(match.user.firstName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    if let lastMessage = match.lastMessage {
                        Text(timeAgo(from: lastMessage.sentAt))
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }

                HStack(spacing: 4) {
                    if let lastMessage = match.lastMessage {
                        // Show indicator if sent by current user
                        if lastMessage.isFromMe {
                            Image(systemName: "checkmark.circle")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textTertiary)
                        }

                        Text(lastMessage.content)
                            .font(.subheadline)
                            .foregroundColor((match.unreadCount ?? 0) > 0 ? .white : AppTheme.textSecondary)
                            .fontWeight((match.unreadCount ?? 0) > 0 ? .medium : .regular)
                            .lineLimit(1)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("Nouveau match ! Dis bonjour")
                                .font(.subheadline)
                        }
                        .foregroundStyle(AppTheme.primaryGradient)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            (match.unreadCount ?? 0) > 0
                ? AppTheme.primaryPurple.opacity(0.1)
                : Color.clear
        )
    }

    private func timeAgo(from dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date: Date?
        date = isoFormatter.date(from: dateString)

        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }

        guard let parsedDate = date else { return "" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: parsedDate, relativeTo: Date())
    }
}

#Preview {
    MatchesView()
        .environmentObject(AppState())
}
