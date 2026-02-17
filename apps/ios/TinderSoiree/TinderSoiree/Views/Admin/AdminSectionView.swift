import SwiftUI

struct AdminSectionView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var showCreateEvent = false
    @State private var selectedEvent: AdminEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mode Organisateur")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Créez et gérez vos soirées")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Button(action: { showCreateEvent = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Créer")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.primaryGradient)
                    .cornerRadius(AppTheme.cornerRadiusLarge)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)

            // My Events
            if viewModel.isLoading && viewModel.myEvents.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.primaryPink)
                    Spacer()
                }
                .padding()
            } else if viewModel.myEvents.isEmpty {
                EmptyAdminEventsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.myEvents) { event in
                        AdminEventRow(
                            event: event,
                            onTap: { selectedEvent = event },
                            onDelete: event.status == .draft ? {
                                Task { await viewModel.deleteEvent(event) }
                            } : nil
                        )
                    }
                }
            }

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
                    .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showCreateEvent, onDismiss: {
            Task { await viewModel.loadMyEvents() }
        }) {
            CreateEventView(viewModel: viewModel)
        }
        .sheet(item: $selectedEvent, onDismiss: {
            Task { await viewModel.loadMyEvents() }
        }) { event in
            EventQRCodeView(event: event, viewModel: viewModel)
        }
        .task {
            await viewModel.loadMyEvents()
        }
    }
}

// MARK: - Admin Event Row

struct AdminEventRow: View {
    let event: AdminEvent
    let onTap: () -> Void
    let onDelete: (() -> Void)?

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Event icon
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: statusIcon)
                            .font(.title3)
                            .foregroundColor(statusColor)
                    }

                    // Event info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Label(formatDate(event.startAt), systemImage: "calendar")
                            if let count = event.participantCount {
                                Label("\(count)", systemImage: "person.2")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    // Status badge
                    Text(statusText)
                        .font(.caption.bold())
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .cornerRadius(AppTheme.cornerRadiusSmall)

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            // Delete button (only for draft events)
            if let onDelete = onDelete {
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(AppTheme.error)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .confirmationDialog("Supprimer cet événement ?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) {
                onDelete?()
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var statusColor: Color {
        switch event.status {
        case .draft: return AppTheme.textSecondary
        case .live: return AppTheme.success
        case .closed: return AppTheme.error
        case .cancelled: return AppTheme.warning
        }
    }

    private var statusIcon: String {
        switch event.status {
        case .draft: return "doc.text"
        case .live: return "party.popper.fill"
        case .closed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    private var statusText: String {
        switch event.status {
        case .draft: return "Brouillon"
        case .live: return "En cours"
        case .closed: return "Terminée"
        case .cancelled: return "Annulée"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM à HH:mm"
            return formatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Empty State

struct EmptyAdminEventsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 30))
                    .foregroundStyle(AppTheme.primaryGradient)
            }

            VStack(spacing: 4) {
                Text("Aucune soirée")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Créez votre première soirée\npour commencer")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

#Preview {
    ScrollView {
        AdminSectionView()
            .padding()
    }
    .background(AppTheme.deepBlack)
}
