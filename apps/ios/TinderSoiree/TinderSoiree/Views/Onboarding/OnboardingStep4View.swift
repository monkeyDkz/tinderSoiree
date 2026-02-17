import SwiftUI
import PhotosUI

struct OnboardingStep4View: View {
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

                    Image(systemName: "camera.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }

                // Info text
                VStack(spacing: 8) {
                    Text("Ajoute au moins 1 photo")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("La premiere photo sera ton image principale")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Photo picker
                PhotoPickerView(
                    selectedImages: $viewModel.selectedPhotos,
                    maxPhotos: 6
                )
                .padding(.horizontal)

                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(icon: "checkmark.circle.fill", text: "Montre ton visage clairement")
                    TipRow(icon: "checkmark.circle.fill", text: "Utilise des photos recentes")
                    TipRow(icon: "xmark.circle.fill", text: "Evite les filtres excessifs", isNegative: true)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .padding(.horizontal)

                Spacer()

                // Continue button
                Button(action: { viewModel.nextStep() }) {
                    Text("Continuer")
                }
                .primaryButtonStyle(isDisabled: !viewModel.canProceedFromStep4)
                .disabled(!viewModel.canProceedFromStep4)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let text: String
    var isNegative: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(isNegative ? AppTheme.error : AppTheme.success)

            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.deepBlack.ignoresSafeArea()
        OnboardingStep4View(viewModel: OnboardingViewModel())
    }
}
