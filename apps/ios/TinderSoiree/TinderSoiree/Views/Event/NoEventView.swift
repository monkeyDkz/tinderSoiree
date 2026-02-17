import SwiftUI

struct NoEventView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)

                VStack(spacing: 12) {
                    Text("Aucune soiree en cours")
                        .font(.title2.bold())

                    Text("Scanne le QR code ou touche le tag NFC de la soiree pour rejoindre")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Logout button
                Button(action: { appState.onLogout() }) {
                    Text("Se deconnecter")
                        .foregroundColor(.red)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    NoEventView()
        .environmentObject(AppState())
}
