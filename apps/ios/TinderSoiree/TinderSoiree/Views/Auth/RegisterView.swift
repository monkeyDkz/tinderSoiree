import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @Binding var showRegister: Bool

    var body: some View {
        ZStack {
            // Background
            AppTheme.deepBlack
                .ignoresSafeArea()

            // Gradient overlay
            VStack {
                Circle()
                    .fill(AppTheme.primaryPurple.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: 100, y: -100)

                Spacer()

                Circle()
                    .fill(AppTheme.primaryPink.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: -100, y: 50)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 40)

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGradient)
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.glowShadow, radius: 15)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }

                        Text("Creer un compte")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }

                    Spacer().frame(height: 20)

                    // Form
                    VStack(spacing: 14) {
                        TextField("Prenom", text: $viewModel.firstName)
                            .textContentType(.givenName)
                            .appTextFieldStyle()

                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .appTextFieldStyle()

                        SecureField("Mot de passe", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .appTextFieldStyle()

                        // Birth date
                        HStack {
                            Text("Date de naissance")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            DatePicker(
                                "",
                                selection: $viewModel.birthDate,
                                in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .colorScheme(.dark)
                        }
                        .padding()
                        .background(AppTheme.inputBackground)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
                        )

                        // Gender
                        HStack {
                            Text("Genre")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Picker("", selection: $viewModel.gender) {
                                Text("Homme").tag(Gender.male)
                                Text("Femme").tag(Gender.female)
                                Text("Autre").tag(Gender.other)
                            }
                            .pickerStyle(.menu)
                            .tint(AppTheme.primaryPink)
                        }
                        .padding()
                        .background(AppTheme.inputBackground)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
                        )

                        // Orientation
                        HStack {
                            Text("Interesse par")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Picker("", selection: $viewModel.orientation) {
                                Text("Hommes").tag(Orientation.men)
                                Text("Femmes").tag(Orientation.women)
                                Text("Tous").tag(Orientation.everyone)
                            }
                            .pickerStyle(.menu)
                            .tint(AppTheme.primaryPink)
                        }
                        .padding()
                        .background(AppTheme.inputBackground)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
                        )

                        if let error = viewModel.error {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.caption)
                            .foregroundColor(AppTheme.error)
                            .padding(.horizontal)
                        }

                        Button(action: register) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("S'inscrire")
                                }
                            }
                        }
                        .primaryButtonStyle(isDisabled: viewModel.isLoading)
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 30)

                    // Login link
                    Button(action: { showRegister = false }) {
                        HStack(spacing: 4) {
                            Text("Deja un compte ?")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Connecte-toi")
                                .foregroundStyle(AppTheme.primaryGradient)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 10)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func register() {
        Task {
            if let user = await viewModel.register() {
                appState.onLoginSuccess(user: user)
            }
        }
    }
}

#Preview {
    RegisterView(showRegister: .constant(true))
        .environmentObject(AppState())
}
