import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?

    // Shared fields for Login/Register
    @Published var email = ""
    @Published var password = ""
    @Published var firstName = ""
    @Published var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var gender: Gender = .male
    @Published var orientation: Orientation = .everyone

    private let authService = AuthService.shared

    func login() async -> User? {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Veuillez remplir tous les champs"
            return nil
        }

        isLoading = true
        error = nil

        do {
            let response = try await authService.login(
                email: email,
                password: password
            )
            isLoading = false
            return response.user
        } catch let apiError as APIError {
            isLoading = false
            error = apiError.localizedDescription
            return nil
        } catch {
            isLoading = false
            self.error = "Erreur de connexion"
            return nil
        }
    }

    func register() async -> User? {
        guard !email.isEmpty,
              !password.isEmpty,
              !firstName.isEmpty else {
            error = "Veuillez remplir tous les champs"
            return nil
        }

        guard password.count >= 8 else {
            error = "Le mot de passe doit contenir au moins 8 caractères"
            return nil
        }

        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        guard age >= 18 else {
            error = "Vous devez avoir au moins 18 ans"
            return nil
        }

        isLoading = true
        error = nil

        do {
            let response = try await authService.register(
                email: email,
                password: password,
                firstName: firstName,
                birthDate: birthDate,
                gender: gender,
                orientation: orientation
            )
            isLoading = false
            return response.user
        } catch let apiError as APIError {
            isLoading = false
            error = apiError.localizedDescription
            return nil
        } catch {
            isLoading = false
            self.error = "Erreur lors de l'inscription"
            return nil
        }
    }

    func clearError() {
        error = nil
    }
}
