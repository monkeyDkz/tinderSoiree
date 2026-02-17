import SwiftUI

struct LoginView: View {
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
                    .offset(x: -100, y: -150)

                Spacer()

                Circle()
                    .fill(AppTheme.primaryPink.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: 100, y: 100)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer().frame(height: 60)

                    // Logo
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: AppTheme.glowShadow, radius: 20)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }

                        Text("Tinder Soiree")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Trouve ton match de soiree")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer().frame(height: 40)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .appTextFieldStyle()

                        SecureField("Mot de passe", text: $viewModel.password)
                            .textContentType(.password)
                            .appTextFieldStyle()

                        if let error = viewModel.error {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.caption)
                            .foregroundColor(AppTheme.error)
                            .padding(.horizontal)
                        }

                        Button(action: login) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Se connecter")
                                }
                            }
                        }
                        .primaryButtonStyle(isDisabled: viewModel.isLoading)
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    // Register link
                    Button(action: { showRegister = true }) {
                        HStack(spacing: 4) {
                            Text("Pas encore de compte ?")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Inscris-toi")
                                .foregroundStyle(AppTheme.primaryGradient)
                                .fontWeight(.semibold)
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func login() {
        Task {
            if let user = await viewModel.login() {
                appState.onLoginSuccess(user: user)
            }
        }
    }
}

#Preview {
    LoginView(showRegister: .constant(false))
        .environmentObject(AppState())
}
