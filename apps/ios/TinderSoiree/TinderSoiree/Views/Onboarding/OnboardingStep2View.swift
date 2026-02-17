import SwiftUI

struct OnboardingStep2View: View {
    @ObservedObject var viewModel: OnboardingViewModel

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

                    Image(systemName: "calendar")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }

                // Form fields
                VStack(spacing: 20) {
                    // Birth Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date de naissance")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        DatePicker(
                            "",
                            selection: $viewModel.birthDate,
                            in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(maxHeight: 150)
                        .clipped()

                        // Age validation
                        if !viewModel.isAtLeast18YearsOld {
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                Text("Tu dois avoir au moins 18 ans")
                            }
                            .font(.caption)
                            .foregroundColor(AppTheme.error)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadiusLarge)

                    // Gender
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Je suis")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        HStack(spacing: 12) {
                            GenderButton(
                                title: "Homme",
                                icon: "person.fill",
                                isSelected: viewModel.gender == .male
                            ) {
                                viewModel.gender = .male
                            }

                            GenderButton(
                                title: "Femme",
                                icon: "person.fill",
                                isSelected: viewModel.gender == .female
                            ) {
                                viewModel.gender = .female
                            }

                            GenderButton(
                                title: "Autre",
                                icon: "person.fill",
                                isSelected: viewModel.gender == .other
                            ) {
                                viewModel.gender = .other
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Continue button
                Button(action: { viewModel.nextStep() }) {
                    Text("Continuer")
                }
                .primaryButtonStyle(isDisabled: !viewModel.canProceedFromStep2)
                .disabled(!viewModel.canProceedFromStep2)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Gender Button
struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
        OnboardingStep2View(viewModel: OnboardingViewModel())
    }
}
