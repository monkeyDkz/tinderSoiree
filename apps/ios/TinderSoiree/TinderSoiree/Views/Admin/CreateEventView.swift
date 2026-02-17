import SwiftUI

struct CreateEventView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.deepBlack
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header illustration
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGradient.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.primaryGradient)
                        }
                        .padding(.top)

                        // Form
                        VStack(spacing: 20) {
                            // Event Name
                            FormField(
                                title: "Nom de la soirée",
                                placeholder: "Ex: Soirée d'été 2024",
                                text: $viewModel.eventName,
                                icon: "textformat"
                            )

                            // Description
                            FormField(
                                title: "Description",
                                placeholder: "Décrivez votre événement...",
                                text: $viewModel.eventDescription,
                                icon: "text.alignleft",
                                isMultiline: true
                            )

                            // Location
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Lieu")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)

                                FormField(
                                    title: "",
                                    placeholder: "Nom du lieu",
                                    text: $viewModel.locationName,
                                    icon: "mappin.circle"
                                )

                                FormField(
                                    title: "",
                                    placeholder: "Adresse (optionnel)",
                                    text: $viewModel.locationAddress,
                                    icon: "map"
                                )
                            }

                            // Dates
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Date et heure")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)

                                DatePickerField(
                                    title: "Début",
                                    date: $viewModel.startDate
                                )

                                DatePickerField(
                                    title: "Fin",
                                    date: $viewModel.endDate
                                )
                            }

                            // Max Participants
                            FormField(
                                title: "Participants max",
                                placeholder: "Illimité si vide",
                                text: $viewModel.maxParticipants,
                                icon: "person.2",
                                keyboardType: .numberPad
                            )
                        }
                        .padding(.horizontal)

                        // Create Button
                        Button(action: createEvent) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Créer la soirée")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                viewModel.canCreateEvent
                                    ? AppTheme.primaryGradient
                                    : LinearGradient(colors: [AppTheme.inputBackground], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(AppTheme.cornerRadiusLarge)
                        }
                        .disabled(!viewModel.canCreateEvent || viewModel.isLoading)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Nouvelle soirée")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.darkGray, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryPink)
                }
            }
        }
    }

    private func createEvent() {
        Task {
            print("DEBUG: Creating event...")
            if let event = await viewModel.createEvent() {
                print("DEBUG: Event created: \(event.name), dismissing...")
                dismiss()
            } else {
                print("DEBUG: Failed to create event, error: \(viewModel.error ?? "unknown")")
            }
        }
    }
}

// MARK: - Form Field

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isMultiline: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.primaryPurple)
                        .frame(width: 24)
                }

                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...6)
                        .keyboardType(keyboardType)
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(AppTheme.inputBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Date Picker Field

struct DatePickerField: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(AppTheme.primaryPurple)
                .frame(width: 24)

            Text(title)
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .tint(AppTheme.primaryPink)
                .colorScheme(.dark)
        }
        .padding()
        .background(AppTheme.inputBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    CreateEventView(viewModel: AdminViewModel())
}
