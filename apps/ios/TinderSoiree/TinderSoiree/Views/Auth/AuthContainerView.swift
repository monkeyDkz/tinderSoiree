import SwiftUI

struct AuthContainerView: View {
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            if showRegister {
                OnboardingContainerView(showRegister: $showRegister)
            } else {
                LoginView(showRegister: $showRegister)
            }
        }
    }
}

#Preview {
    AuthContainerView()
        .environmentObject(AppState())
}
