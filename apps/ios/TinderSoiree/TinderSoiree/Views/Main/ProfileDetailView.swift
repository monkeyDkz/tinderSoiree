import SwiftUI

struct ProfileDetailView: View {
    let profile: StackProfile
    let onLike: () -> Void
    let onDislike: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentPhotoIndex = 0

    var body: some View {
        ZStack {
            // Background
            AppTheme.deepBlack
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Photo Carousel
                    PhotoCarouselView(
                        photos: profile.photos,
                        currentIndex: $currentPhotoIndex
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.55)

                    // Profile Info
                    VStack(alignment: .leading, spacing: 16) {
                        // Name and Age
                        HStack(alignment: .bottom) {
                            Text(profile.firstName)
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)

                            Text("\(profile.age)")
                                .font(.title2)
                                .foregroundColor(AppTheme.textSecondary)

                            Spacer()
                        }

                        // Bio
                        if let bio = profile.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineSpacing(4)
                        }

                        // Info cards
                        VStack(spacing: 12) {
                            if let gender = genderText {
                                InfoRow(icon: "person.fill", text: gender)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }

            // Top bar with close button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.cardBackground.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding()

                    Spacer()
                }

                Spacer()
            }

            // Bottom action buttons
            VStack {
                Spacer()

                HStack(spacing: 20) {
                    // Dislike
                    ActionButton(
                        icon: "xmark",
                        color: AppTheme.error,
                        size: 60
                    ) {
                        dismiss()
                        onDislike()
                    }

                    // Like
                    ActionButton(
                        icon: "heart.fill",
                        gradient: AppTheme.primaryGradient,
                        size: 70
                    ) {
                        dismiss()
                        onLike()
                    }

                    // Super Like (future feature)
                    ActionButton(
                        icon: "star.fill",
                        color: AppTheme.warning,
                        size: 60
                    ) {
                        // Super like action
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    private var genderText: String? {
        switch profile.gender {
        case .male: return "Homme"
        case .female: return "Femme"
        case .other: return "Autre"
        case .nonBinary: return "Non-binaire"
        default: return nil
        }
    }
}

// MARK: - Photo Carousel
struct PhotoCarouselView: View {
    let photos: [Photo]
    @Binding var currentIndex: Int

    var body: some View {
        ZStack(alignment: .top) {
            // Photos
            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    RemoteImage(url: photos[index].url)
                        .aspectRatio(contentMode: .fill)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Gradient overlay at bottom
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, AppTheme.deepBlack],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }

            // Photo indicators
            if photos.count > 1 {
                HStack(spacing: 4) {
                    ForEach(photos.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
        }
        .clipped()
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    var color: Color? = nil
    var gradient: LinearGradient? = nil
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(gradient ?? LinearGradient(colors: [color ?? .white], startPoint: .top, endPoint: .bottom))
                    .frame(width: size, height: size)
                    .shadow(color: (color ?? AppTheme.primaryPink).opacity(0.4), radius: 10, y: 5)

                Image(systemName: icon)
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primaryGradient)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)

            Spacer()
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

// MARK: - Preview
#Preview {
    ProfileDetailView(
        profile: StackProfile(
            id: "1",
            firstName: "Marie",
            age: 25,
            bio: "J'aime voyager et decouvrir de nouvelles cultures. Passionnee de photographie et de cuisine.",
            photos: [],
            gender: .female
        ),
        onLike: {},
        onDislike: {}
    )
}
