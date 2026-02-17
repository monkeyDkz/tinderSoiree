import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case basicInfo = 1
    case birthAndGender = 2
    case preferences = 3
    case photos = 4
    case confirmation = 5

    var title: String {
        switch self {
        case .basicInfo: return "Qui es-tu ?"
        case .birthAndGender: return "Parle-nous de toi"
        case .preferences: return "Tes preferences"
        case .photos: return "Ajoute des photos"
        case .confirmation: return "Pret a matcher !"
        }
    }

    var subtitle: String {
        switch self {
        case .basicInfo: return "Commence par les bases"
        case .birthAndGender: return "Pour personnaliser ton experience"
        case .preferences: return "Qui cherches-tu ?"
        case .photos: return "Montre ton meilleur profil"
        case .confirmation: return "Verifie que tout est bon"
        }
    }

    var progress: Double {
        return Double(self.rawValue) / Double(OnboardingStep.allCases.count)
    }
}

@MainActor
class OnboardingViewModel: ObservableObject {
    // Current step
    @Published var currentStep: OnboardingStep = .basicInfo

    // Step 1: Basic Info
    @Published var firstName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""

    // Step 2: Birth and Gender
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @Published var gender: Gender = .male

    // Step 3: Preferences
    @Published var orientation: Orientation = .everyone
    @Published var bio: String = ""

    // Step 4: Photos
    @Published var selectedPhotos: [UIImage] = []

    // State
    @Published var isLoading = false
    @Published var error: String?

    private let authService = AuthService.shared
    private let uploadService = UploadService.shared

    // MARK: - Validation

    var canProceedFromStep1: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 8 &&
        isValidEmail(email)
    }

    var canProceedFromStep2: Bool {
        isAtLeast18YearsOld
    }

    var canProceedFromStep3: Bool {
        true // Orientation is always valid, bio is optional
    }

    var canProceedFromStep4: Bool {
        !selectedPhotos.isEmpty
    }

    var isAtLeast18YearsOld: Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return (ageComponents.year ?? 0) >= 18
    }

    // MARK: - Navigation

    func nextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextStep
        }
    }

    func previousStep() {
        guard let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevStep
        }
    }

    func goToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    // MARK: - Registration

    func completeRegistration() async -> User? {
        guard canProceedFromStep4 else {
            error = "Ajoute au moins une photo"
            return nil
        }

        isLoading = true
        error = nil

        do {
            // 1. Register the user
            let authResponse = try await authService.register(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                birthDate: birthDate,
                gender: gender,
                orientation: orientation
            )

            // 2. Upload photos
            var uploadedUrls: [String] = []
            for photo in selectedPhotos {
                let url = try await uploadService.uploadImage(photo)
                uploadedUrls.append(url)
            }

            // 3. Update profile with photos and bio
            if !uploadedUrls.isEmpty || !bio.isEmpty {
                try await updateProfile(photoUrls: uploadedUrls, bio: bio)
            }

            isLoading = false
            return authResponse.user

        } catch let apiError as APIError {
            isLoading = false
            error = apiError.errorDescription
            return nil
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            return nil
        }
    }

    private func updateProfile(photoUrls: [String], bio: String) async throws {
        struct ProfileUpdate: Encodable {
            let photos: [PhotoUpdate]?
            let bio: String?
        }

        let photos = photoUrls.isEmpty ? nil : photoUrls.enumerated().map { index, url in
            PhotoUpdate(url: url, position: index, isMain: index == 0)
        }

        let update = ProfileUpdate(
            photos: photos,
            bio: bio.isEmpty ? nil : bio
        )

        let _: User = try await APIClient.shared.patch("/me", body: update)
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
