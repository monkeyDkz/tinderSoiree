import SwiftUI
import UIKit

// MARK: - Remote Image Component (with ngrok header)

@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    func load(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        isLoading = true

        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let data = data {
                    self?.image = UIImage(data: data)
                }
            }
        }.resume()
    }
}

struct RemoteImage: View {
    let url: String?

    @StateObject private var loader = ImageLoader()

    var body: some View {
        Group {
            if let loadedImage = loader.image {
                Image(uiImage: loadedImage)
                    .resizable()
            } else if loader.isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
            }
        }
        .onAppear {
            if let url = url, loader.image == nil {
                loader.load(from: url)
            }
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLeaveConfirmation = false
    @State private var eventHistory: [EventHistoryItem] = []
    @State private var isLoadingHistory = false
    @State private var matchesByEvent: [String: [Match]] = [:]
    @State private var expandedEvents: Set<String> = []
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.deepBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        ProfileHeaderView(
                            user: appState.currentUser,
                            onEditTap: { showEditProfile = true }
                        )
                        .padding(.top)

                        // Admin Section (if admin)
                        if appState.currentUser?.isAdmin == true {
                            AdminSectionView()
                                .padding(.horizontal)
                        }

                        // Current Event
                        if let event = appState.currentEvent {
                            CurrentEventSection(
                                event: event,
                                checkin: appState.currentCheckin
                            )
                            .padding(.horizontal)
                        }

                        // Event History
                        if !eventHistory.isEmpty {
                            EventHistorySection(
                                eventHistory: eventHistory,
                                matchesByEvent: matchesByEvent,
                                expandedEvents: $expandedEvents
                            )
                            .padding(.horizontal)
                        }

                        // Actions
                        ActionButtonsSection(
                            hasCurrentEvent: appState.currentEvent != nil,
                            onLeaveEvent: { showLeaveConfirmation = true },
                            onLogout: logout
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .alert("Quitter la soirée ?", isPresented: $showLeaveConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Quitter", role: .destructive) {
                leaveEvent()
            }
        } message: {
            Text("Tu ne pourras plus matcher avec les participants.")
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(appState)
        }
        .task {
            await loadEventHistory()
        }
    }

    private func loadEventHistory() async {
        isLoadingHistory = true
        do {
            let response = try await EventService.shared.getEventHistory()
            eventHistory = response.events

            for item in response.events {
                do {
                    let matchesResponse = try await MatchService.shared.getMatches(eventId: item.event.id)
                    matchesByEvent[item.event.id] = matchesResponse.matches
                } catch {
                    print("Failed to load matches for event \(item.event.id): \(error)")
                }
            }
        } catch {
            print("Failed to load event history: \(error)")
        }
        isLoadingHistory = false
    }

    private func leaveEvent() {
        Task {
            if let eventId = appState.currentEvent?.id {
                try? await EventService.shared.leaveEvent(eventId: eventId)
                appState.onEventLeft()
            }
        }
    }

    private func logout() {
        appState.onLogout()
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    let user: User?
    let onEditTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Photo with edit button
            ZStack(alignment: .bottomTrailing) {
                RemoteImage(url: user?.photos.first?.url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppTheme.primaryGradient, lineWidth: 3)
                    )
                    .shadow(color: AppTheme.primaryPurple.opacity(0.3), radius: 10)

                // Edit button
                Button(action: onEditTap) {
                    Image(systemName: "pencil")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.primaryGradient)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.primaryPink.opacity(0.4), radius: 4)
                }
            }

            // Name and info
            if let user = user {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Text("\(user.firstName), \(user.age)")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        if user.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.primaryGradient)
                        }
                    }

                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // Photos count
                    HStack(spacing: 4) {
                        Image(systemName: "photo.stack")
                            .font(.caption)
                        Text("\(user.photos.count) photo\(user.photos.count > 1 ? "s" : "")")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
    }
}

// MARK: - Current Event Section

struct CurrentEventSection: View {
    let event: Event
    let checkin: Checkin?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Soirée actuelle", systemImage: "party.popper.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryGradient)

            VStack(alignment: .leading, spacing: 10) {
                Text(event.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Label(event.locationName, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                if let checkin = checkin {
                    Label(
                        "Check-in: \(formatDateString(checkin.joinedAt))",
                        systemImage: "clock.fill"
                    )
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func formatDateString(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date: Date?
        date = isoFormatter.date(from: dateString)

        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }

        guard let parsedDate = date else { return dateString }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: parsedDate)
    }
}

// MARK: - Event History Section

struct EventHistorySection: View {
    let eventHistory: [EventHistoryItem]
    let matchesByEvent: [String: [Match]]
    @Binding var expandedEvents: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Mes soirées", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryGradient)

            ForEach(eventHistory, id: \.checkin.id) { item in
                EventHistoryCard(
                    item: item,
                    matches: matchesByEvent[item.event.id] ?? [],
                    isExpanded: expandedEvents.contains(item.event.id),
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedEvents.contains(item.event.id) {
                                expandedEvents.remove(item.event.id)
                            } else {
                                expandedEvents.insert(item.event.id)
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Event History Card

struct EventHistoryCard: View {
    let item: EventHistoryItem
    let matches: [Match]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.event.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text(item.event.locationName)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(formatDateString(item.checkin.joinedAt))
                            .font(.caption2)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    Spacer()

                    HStack(spacing: 8) {
                        if !matches.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                Text("\(matches.count)")
                                    .font(.caption)
                            }
                            .foregroundColor(AppTheme.primaryPink)
                        }

                        if item.checkin.leftAt == nil {
                            Text("En cours")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.success.opacity(0.2))
                                .foregroundColor(AppTheme.success)
                                .cornerRadius(AppTheme.cornerRadiusSmall)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(AppTheme.inputBackground)
                        .padding(.horizontal)

                    if matches.isEmpty {
                        Text("Pas encore de match")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                    } else {
                        Text("Matches")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.primaryPink)
                            .padding(.horizontal)

                        ForEach(matches) { match in
                            MatchRow(match: match)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }

    private func formatDateString(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date: Date?
        date = isoFormatter.date(from: dateString)

        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }

        guard let parsedDate = date else { return dateString }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: parsedDate)
    }
}

// MARK: - Match Row

struct MatchRow: View {
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: match.user.photos.first?.url)
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppTheme.primaryPurple.opacity(0.5), lineWidth: 1)
                )

            Text(match.user.firstName)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "heart.fill")
                .font(.caption)
                .foregroundColor(AppTheme.primaryPink)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Action Buttons Section

struct ActionButtonsSection: View {
    let hasCurrentEvent: Bool
    let onLeaveEvent: () -> Void
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if hasCurrentEvent {
                Button(action: onLeaveEvent) {
                    Label("Quitter la soirée", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.warning.opacity(0.15))
                        .foregroundColor(AppTheme.warning)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(AppTheme.warning.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Button(action: onLogout) {
                Label("Se déconnecter", systemImage: "power")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.error.opacity(0.15))
                    .foregroundColor(AppTheme.error)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                            .stroke(AppTheme.error.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var bio: String = ""
    @State private var orientation: Orientation = .everyone
    @State private var existingPhotos: [Photo] = []
    @State private var newPhotos: [UIImage] = []
    @State private var photosToRemove: Set<String> = []
    @State private var isLoading = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showPhotoOptions = false
    @State private var error: String?
    @State private var showSuccess = false

    private let maxPhotos = 6

    var totalPhotosCount: Int {
        existingPhotos.filter { !photosToRemove.contains($0.url) }.count + newPhotos.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.deepBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Photos Section
                        photoSection

                        // Orientation Section
                        orientationSection

                        // Bio Section
                        bioSection

                        // Error message
                        if let error = error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(AppTheme.error)
                                .padding(.horizontal)
                        }

                        // Save Button
                        saveButton

                        Spacer(minLength: 32)
                    }
                    .padding()
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: Binding<UIImage?>(
                    get: { nil },
                    set: { (image: UIImage?) in
                        if let image = image {
                            newPhotos.append(image)
                        }
                    }
                ), sourceType: UIImagePickerController.SourceType.photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: Binding<UIImage?>(
                    get: { nil },
                    set: { (image: UIImage?) in
                        if let image = image {
                            newPhotos.append(image)
                        }
                    }
                ), sourceType: UIImagePickerController.SourceType.camera)
            }
            .confirmationDialog("Ajouter une photo", isPresented: $showPhotoOptions) {
                Button("Prendre une photo") {
                    showCamera = true
                }
                Button("Choisir dans la galerie") {
                    showImagePicker = true
                }
                Button("Annuler", role: .cancel) { }
            }
            .alert("Profil mis à jour !", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Mes photos", systemImage: "photo.stack")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryGradient)

                Spacer()

                Text("\(totalPhotosCount)/\(maxPhotos)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Existing photos
                ForEach(existingPhotos, id: \.url) { photo in
                    if !photosToRemove.contains(photo.url) {
                        existingPhotoCell(photo: photo)
                    }
                }

                // New photos
                ForEach(Array(newPhotos.enumerated()), id: \.offset) { index, image in
                    newPhotoCell(image: image, index: index)
                }

                // Add button
                if totalPhotosCount < maxPhotos {
                    addPhotoButton
                }
            }

            Text("Ajoute jusqu'à \(maxPhotos) photos. La première sera ta photo principale.")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
    }

    private func existingPhotoCell(photo: Photo) -> some View {
        ZStack(alignment: .topTrailing) {
            RemoteImage(url: photo.url)
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))

            // Remove button
            Button {
                photosToRemove.insert(photo.url)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(4)

            // Main photo badge
            if photo.isMain == true && photosToRemove.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text("Principale")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primaryGradient)
                            .cornerRadius(4)
                        Spacer()
                    }
                    .padding(4)
                }
            }
        }
    }

    private func newPhotoCell(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))

            // Remove button
            Button {
                newPhotos.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(4)

            // New badge
            VStack {
                Spacer()
                HStack {
                    Text("Nouvelle")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.success)
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(4)
            }
        }
    }

    private var addPhotoButton: some View {
        Button {
            showPhotoOptions = true
        } label: {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .fill(AppTheme.cardBackground)
                .frame(height: 120)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(AppTheme.primaryGradient)
                        Text("Ajouter")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundStyle(AppTheme.primaryGradient.opacity(0.5))
                )
        }
    }

    // MARK: - Orientation Section

    private var orientationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Je suis intéressé par", systemImage: "heart.circle")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryGradient)

            HStack(spacing: 12) {
                ForEach(Orientation.allCases, id: \.self) { option in
                    Button {
                        orientation = option
                    } label: {
                        Text(orientationLabel(option))
                            .font(.subheadline)
                            .fontWeight(orientation == option ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                orientation == option
                                    ? AnyShapeStyle(AppTheme.primaryGradient)
                                    : AnyShapeStyle(AppTheme.cardBackground)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadiusSmall)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                    .stroke(
                                        orientation == option
                                            ? Color.clear
                                            : AppTheme.inputBackground,
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
        }
    }

    private func orientationLabel(_ orientation: Orientation) -> String {
        switch orientation {
        case .men: return "Hommes"
        case .women: return "Femmes"
        case .everyone: return "Tout le monde"
        }
    }

    // MARK: - Bio Section

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ma bio", systemImage: "text.quote")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryGradient)

            TextEditor(text: $bio)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(12)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(AppTheme.inputBackground, lineWidth: 1)
                )
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)

            HStack {
                Spacer()
                Text("\(bio.count)/300")
                    .font(.caption)
                    .foregroundColor(bio.count > 300 ? AppTheme.error : AppTheme.textTertiary)
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                await saveProfile()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Enregistrer les modifications")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryGradient)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .shadow(color: AppTheme.primaryPink.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(isLoading || bio.count > 300)
        .opacity(isLoading || bio.count > 300 ? 0.6 : 1)
    }

    // MARK: - Functions

    private func loadCurrentProfile() {
        guard let user = appState.currentUser else { return }
        bio = user.bio ?? ""
        orientation = user.orientation
        existingPhotos = user.photos
    }

    private func saveProfile() async {
        isLoading = true
        error = nil

        do {
            // 1. Upload new photos
            var uploadedUrls: [String] = []
            for photo in newPhotos {
                let url = try await UploadService.shared.uploadImage(photo)
                uploadedUrls.append(url)
            }

            // 2. Build final photos array
            var finalPhotos: [PhotoUpdate] = []
            var position = 0

            // Keep existing photos that weren't removed
            for photo in existingPhotos {
                if !photosToRemove.contains(photo.url) {
                    finalPhotos.append(PhotoUpdate(
                        url: photo.url,
                        position: position,
                        isMain: position == 0
                    ))
                    position += 1
                }
            }

            // Add new photos
            for url in uploadedUrls {
                finalPhotos.append(PhotoUpdate(
                    url: url,
                    position: position,
                    isMain: position == 0
                ))
                position += 1
            }

            // 3. Update profile
            let updatedUser = try await ProfileService.shared.updateProfile(
                bio: bio.isEmpty ? nil : bio,
                orientation: orientation,
                photos: finalPhotos.isEmpty ? nil : finalPhotos
            )

            // 4. Update app state
            appState.currentUser = updatedUser

            isLoading = false
            showSuccess = true

        } catch let apiError as APIError {
            isLoading = false
            error = apiError.errorDescription
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Profile Service

private struct ProfileUpdateRequest: Encodable {
    let bio: String?
    let orientation: Orientation?
    let photos: [PhotoUpdate]?
}

class ProfileService {
    static let shared = ProfileService()

    private let api = APIClient.shared

    private init() {}

    func updateProfile(bio: String?, orientation: Orientation?, photos: [PhotoUpdate]?) async throws -> User {
        let request = ProfileUpdateRequest(bio: bio, orientation: orientation, photos: photos)
        return try await api.patch("/me", body: request)
    }

    func getProfile() async throws -> User {
        try await api.get("/me")
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
