import SwiftUI

struct OnboardingStep5View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Success icon
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: AppTheme.glowShadow, radius: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Ton profil est pret !")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                // Profile Summary Card
                VStack(spacing: 16) {
                    // Photo preview
                    if let firstPhoto = viewModel.selectedPhotos.first {
                        Image(uiImage: firstPhoto)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.primaryGradient, lineWidth: 3)
                            )
                    }

                    // Name and age
                    VStack(spacing: 4) {
                        Text(viewModel.firstName)
                            .font(.title3.bold())
                            .foregroundColor(.white)

                        Text(ageText)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Divider()
                        .background(AppTheme.primaryPurple.opacity(0.3))

                    // Details
                    VStack(spacing: 12) {
                        SummaryRow(label: "Genre", value: genderText)
                        SummaryRow(label: "Recherche", value: orientationText)
                        SummaryRow(label: "Photos", value: "\(viewModel.selectedPhotos.count)")

                        if !viewModel.bio.isEmpty {
                            SummaryRow(label: "Bio", value: String(viewModel.bio.prefix(50)) + (viewModel.bio.count > 50 ? "..." : ""))
                        }
                    }
                }
                .padding(20)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .padding(.horizontal)

                // Error message
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(error)
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.error)
                    .padding(.horizontal)
                }

                Spacer()

                // Complete button
                Button(action: onComplete) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Commencer a matcher")
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .primaryButtonStyle(isDisabled: viewModel.isLoading)
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Computed Properties

    private var ageText: String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: viewModel.birthDate, to: Date())
        return "\(ageComponents.year ?? 0) ans"
    }

    private var genderText: String {
        switch viewModel.gender {
        case .male: return "Homme"
        case .female: return "Femme"
        case .other: return "Autre"
        case .nonBinary: return "Non-binaire"
        }
    }

    private var orientationText: String {
        switch viewModel.orientation {
        case .men: return "Hommes"
        case .women: return "Femmes"
        case .everyone: return "Tout le monde"
        }
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textTertiary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.deepBlack.ignoresSafeArea()
        OnboardingStep5View(viewModel: OnboardingViewModel()) {}
    }
}
