import SwiftUI

struct OnboardingStep3View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var bioFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: AppTheme.glowShadow, radius: 15)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }

                // Form fields
                VStack(spacing: 20) {
                    // Orientation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Je recherche")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        HStack(spacing: 12) {
                            OrientationButton(
                                title: "Hommes",
                                isSelected: viewModel.orientation == .men
                            ) {
                                viewModel.orientation = .men
                            }

                            OrientationButton(
                                title: "Femmes",
                                isSelected: viewModel.orientation == .women
                            ) {
                                viewModel.orientation = .women
                            }

                            OrientationButton(
                                title: "Tous",
                                isSelected: viewModel.orientation == .everyone
                            ) {
                                viewModel.orientation = .everyone
                            }
                        }
                    }

                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Bio")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)

                            Spacer()

                            Text("\(viewModel.bio.count)/300")
                                .font(.caption)
                                .foregroundColor(AppTheme.textTertiary)
                        }

                        TextEditor(text: $viewModel.bio)
                            .focused($bioFocused)
                            .frame(minHeight: 100, maxHeight: 150)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .background(AppTheme.inputBackground)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                    .stroke(
                                        bioFocused ? AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                            .foregroundColor(.white)

                        Text("Decris-toi en quelques mots (optionnel)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .onChange(of: viewModel.bio) { _, newValue in
                        if newValue.count > 300 {
                            viewModel.bio = String(newValue.prefix(300))
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Continue button
                Button(action: { viewModel.nextStep() }) {
                    Text("Continuer")
                }
                .primaryButtonStyle(isDisabled: !viewModel.canProceedFromStep3)
                .disabled(!viewModel.canProceedFromStep3)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Orientation Button
struct OrientationButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if isSelected {
                            AppTheme.primaryGradient
                        } else {
                            AppTheme.inputBackground
                        }
                    }
                )
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(
                            isSelected ? Color.clear : AppTheme.primaryPurple.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
    }
}

#Preview {
    ZStack {
        AppTheme.deepBlack.ignoresSafeArea()
        OnboardingStep3View(viewModel: OnboardingViewModel())
    }
}
