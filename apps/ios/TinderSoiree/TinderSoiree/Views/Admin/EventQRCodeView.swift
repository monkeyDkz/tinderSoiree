import SwiftUI

struct EventQRCodeView: View {
    let event: AdminEvent
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showNFCWrite = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.deepBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Event Info Header
                        VStack(spacing: 8) {
                            Text(event.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Label(formatDate(event.startAt), systemImage: "calendar")
                                Label(event.locationName, systemImage: "mappin")
                            }
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding()

                        // QR Code
                        VStack(spacing: 16) {
                            if viewModel.isLoadingQR {
                                ProgressView()
                                    .tint(AppTheme.primaryPink)
                                    .frame(width: 250, height: 250)
                            } else if let qrCode = viewModel.currentQRCode {
                                QRCodeImageView(base64String: qrCode.qrCodeUrl)
                                    .frame(width: 250, height: 250)
                                    .background(Color.white)
                                    .cornerRadius(AppTheme.cornerRadiusMedium)
                                    .shadow(color: AppTheme.primaryPurple.opacity(0.3), radius: 20)
                            } else {
                                Rectangle()
                                    .fill(AppTheme.cardBackground)
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(AppTheme.cornerRadiusMedium)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "qrcode")
                                                .font(.system(size: 50))
                                                .foregroundColor(AppTheme.textTertiary)
                                            Text("Chargement...")
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                    }
                            }

                            Text("Scannez pour rejoindre")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Les participants peuvent scanner ce QR code\npour rejoindre votre soirée")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadiusLarge)
                        .padding(.horizontal)

                        // Actions
                        VStack(spacing: 12) {
                            // Share Button
                            Button(action: { showShareSheet = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Partager le lien")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primaryGradient)
                                .cornerRadius(AppTheme.cornerRadiusLarge)
                            }
                            .disabled(viewModel.currentQRCode == nil)

                            // NFC Write Button
                            Button(action: { showNFCWrite = true }) {
                                HStack {
                                    Image(systemName: "wave.3.right")
                                    Text("Écrire sur tag NFC")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.cornerRadiusLarge)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                                        .stroke(AppTheme.primaryPurple, lineWidth: 1)
                                )
                            }
                            .disabled(viewModel.currentQRCode == nil)

                            // Regenerate Token
                            Button(action: regenerateToken) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Régénérer le token")
                                }
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)

                        // Event Status Actions
                        VStack(spacing: 12) {
                            Divider()
                                .background(AppTheme.cardBackground)

                            if event.status == .draft {
                                Button(action: publishEvent) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Publier la soirée")
                                    }
                                    .font(.headline)
                                    .foregroundColor(AppTheme.success)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.success.opacity(0.2))
                                    .cornerRadius(AppTheme.cornerRadiusLarge)
                                }
                            } else if event.status == .live {
                                Button(action: closeEvent) {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Terminer la soirée")
                                    }
                                    .font(.headline)
                                    .foregroundColor(AppTheme.error)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.error.opacity(0.2))
                                    .cornerRadius(AppTheme.cornerRadiusLarge)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.darkGray, for: .navigationBar)
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
            .sheet(isPresented: $showShareSheet) {
                if let qrCode = viewModel.currentQRCode {
                    ShareSheet(items: [qrCode.joinUrl])
                }
            }
            .sheet(isPresented: $showNFCWrite) {
                if let qrCode = viewModel.currentQRCode {
                    NFCWriteView(payload: qrCode.nfcPayload)
                }
            }
            .task {
                await viewModel.loadQRCode(eventId: event.id)
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy HH:mm"
            return formatter.string(from: date)
        }
        return dateString
    }

    private func regenerateToken() {
        Task {
            await viewModel.regenerateToken(eventId: event.id)
        }
    }

    private func publishEvent() {
        Task {
            await viewModel.publishEvent(event)
            dismiss()
        }
    }

    private func closeEvent() {
        Task {
            await viewModel.closeEvent(event)
            dismiss()
        }
    }
}

// MARK: - QR Code Image View

struct QRCodeImageView: View {
    let base64String: String

    var body: some View {
        if let image = decodeBase64Image() {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 100))
                .foregroundColor(.black)
        }
    }

    private func decodeBase64Image() -> UIImage? {
        // Handle data URL format: "data:image/png;base64,..."
        var base64Data = base64String

        if base64String.contains(",") {
            base64Data = String(base64String.split(separator: ",").last ?? "")
        }

        guard let data = Data(base64Encoded: base64Data) else {
            return nil
        }

        return UIImage(data: data)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    EventQRCodeView(
        event: AdminEvent(
            id: "1",
            name: "Soirée Test",
            description: nil,
            locationName: "Le Bar",
            locationAddress: nil,
            coverImageUrl: nil,
            startAt: "2024-01-01T20:00:00Z",
            endAt: "2024-01-02T02:00:00Z",
            status: .live,
            maxParticipants: nil,
            participantCount: 42,
            createdAt: "2024-01-01T10:00:00Z"
        ),
        viewModel: AdminViewModel()
    )
}
