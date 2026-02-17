import SwiftUI

struct OnboardingStep1View: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case firstName, email, password
    }

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

                    Image(systemName: "person.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }

                // Form fields
                VStack(spacing: 16) {
                    // First Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prenom")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("Ton prenom", text: $viewModel.firstName)
                            .textContentType(.givenName)
                            .focused($focusedField, equals: .firstName)
                            .appTextFieldStyle()
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }
                    }

                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("ton@email.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .appTextFieldStyle()
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mot de passe")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        SecureField("8 caracteres minimum", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .appTextFieldStyle()
                            .submitLabel(.done)
                    }

                    // Password hint
                    if !viewModel.password.isEmpty && viewModel.password.count < 8 {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("Le mot de passe doit contenir au moins 8 caracteres")
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.warning)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Continue button
                Button(action: { viewModel.nextStep() }) {
                    Text("Continuer")
                }
                .primaryButtonStyle(isDisabled: !viewModel.canProceedFromStep1)
                .disabled(!viewModel.canProceedFromStep1)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            focusedField = .firstName
        }
    }
}

#Preview {
    ZStack {
        AppTheme.deepBlack.ignoresSafeArea()
        OnboardingStep1View(viewModel: OnboardingViewModel())
    }
}
