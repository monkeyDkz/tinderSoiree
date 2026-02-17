import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var showRegister: Bool

    var body: some View {
        ZStack {
            // Background
            AppTheme.deepBlack
                .ignoresSafeArea()

            // Gradient blobs
            GeometryReader { geometry in
                Circle()
                    .fill(AppTheme.primaryPurple.opacity(0.25))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(
                        x: -50,
                        y: CGFloat(viewModel.currentStep.rawValue) * -50
                    )
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentStep)

                Circle()
                    .fill(AppTheme.primaryPink.opacity(0.25))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(
                        x: geometry.size.width - 100,
                        y: geometry.size.height - 200 + CGFloat(viewModel.currentStep.rawValue) * 30
                    )
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentStep)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                OnboardingHeaderView(
                    step: viewModel.currentStep,
                    onBack: {
                        if viewModel.currentStep == .basicInfo {
                            showRegister = false
                        } else {
                            viewModel.previousStep()
                        }
                    }
                )

                // Content
                TabView(selection: $viewModel.currentStep) {
                    OnboardingStep1View(viewModel: viewModel)
                        .tag(OnboardingStep.basicInfo)

                    OnboardingStep2View(viewModel: viewModel)
                        .tag(OnboardingStep.birthAndGender)

                    OnboardingStep3View(viewModel: viewModel)
                        .tag(OnboardingStep.preferences)

                    OnboardingStep4View(viewModel: viewModel)
                        .tag(OnboardingStep.photos)

                    OnboardingStep5View(viewModel: viewModel) {
                        Task {
                            if let user = await viewModel.completeRegistration() {
                                appState.onLoginSuccess(user: user)
                            }
                        }
                    }
                    .tag(OnboardingStep.confirmation)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Header with Progress
struct OnboardingHeaderView: View {
    let step: OnboardingStep
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Back button and progress
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Step indicator
                Text("\(step.rawValue)/5")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal)

            // Progress bar
            ProgressBarView(progress: step.progress)
                .padding(.horizontal)

            // Title
            VStack(spacing: 4) {
                Text(step.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(step.subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.top, 8)
        }
        .padding(.top, 8)
    }
}

// MARK: - Progress Bar
struct ProgressBarView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.inputBackground)
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.primaryGradient)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView(showRegister: .constant(true))
        .environmentObject(AppState())
}
