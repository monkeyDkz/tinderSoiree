import SwiftUI

struct NFCWriteView: View {
    let payload: String

    @Environment(\.dismiss) private var dismiss

    // Inline colors (in case Theme.swift is not in target)
    private let deepBlack = Color(red: 0.04, green: 0.04, blue: 0.04)
    private let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    private let primaryPurple = Color(red: 0.545, green: 0.361, blue: 0.965)
    private let primaryPink = Color(red: 0.925, green: 0.286, blue: 0.6)
    private let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.65)
    private let darkGray = Color(red: 0.11, green: 0.11, blue: 0.12)

    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primaryPurple, primaryPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                deepBlack
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // NFC Icon
                    ZStack {
                        Circle()
                            .fill(cardBackground)
                            .frame(width: 120, height: 120)

                        Image(systemName: "wave.3.right")
                            .font(.system(size: 50))
                            .foregroundStyle(primaryGradient)
                    }

                    // Status Text
                    VStack(spacing: 12) {
                        Text("NFC Non Disponible")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Text("L'écriture NFC nécessite un compte\nApple Developer payant (99€/an).\n\nUtilisez le QR code ou le lien\npour partager l'événement.")
                            .font(.body)
                            .foregroundColor(textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Close Button
                    Button(action: { dismiss() }) {
                        Text("Fermer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryGradient)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Écriture NFC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    NFCWriteView(payload: "tindersoiree://join?eventId=123&token=abc")
}
