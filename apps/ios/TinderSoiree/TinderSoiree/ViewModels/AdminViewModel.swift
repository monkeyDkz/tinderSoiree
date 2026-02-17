import Foundation
import SwiftUI

@MainActor
class AdminViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var myEvents: [AdminEvent] = []
    @Published var isLoading = false
    @Published var error: String?

    // Create Event Form
    @Published var eventName = ""
    @Published var eventDescription = ""
    @Published var locationName = ""
    @Published var locationAddress = ""
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(3600 * 4) // +4 hours
    @Published var maxParticipants: String = ""
    @Published var coverImageUrl: String = ""

    // QR Code
    @Published var currentQRCode: QRCodeResponse?
    @Published var isLoadingQR = false

    // MARK: - Private

    private let adminService = AdminService.shared

    // MARK: - Computed Properties

    var canCreateEvent: Bool {
        !eventName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !locationName.trimmingCharacters(in: .whitespaces).isEmpty &&
        startDate < endDate
    }

    var maxParticipantsInt: Int? {
        Int(maxParticipants)
    }

    // MARK: - Event Management

    func loadMyEvents() async {
        isLoading = true
        error = nil

        do {
            myEvents = try await adminService.getMyEvents()
        } catch {
            self.error = "Impossible de charger vos événements"
            print("Error loading events: \(error)")
        }

        isLoading = false
    }

    func createEvent() async -> AdminEvent? {
        guard canCreateEvent else { return nil }

        isLoading = true
        error = nil

        do {
            let event = try await adminService.createEvent(
                name: eventName.trimmingCharacters(in: .whitespaces),
                description: eventDescription.isEmpty ? nil : eventDescription,
                locationName: locationName.trimmingCharacters(in: .whitespaces),
                locationAddress: locationAddress.isEmpty ? nil : locationAddress,
                startAt: startDate,
                endAt: endDate,
                maxParticipants: maxParticipantsInt,
                coverImageUrl: coverImageUrl.isEmpty ? nil : coverImageUrl
            )

            // Add to list
            myEvents.insert(event, at: 0)

            // Reset form
            resetForm()

            isLoading = false
            return event
        } catch {
            self.error = "Impossible de créer l'événement"
            print("Error creating event: \(error)")
            isLoading = false
            return nil
        }
    }

    func publishEvent(_ event: AdminEvent) async {
        do {
            let updated = try await adminService.publishEvent(id: event.id)
            if let index = myEvents.firstIndex(where: { $0.id == event.id }) {
                myEvents[index] = updated
            }
        } catch {
            self.error = "Impossible de publier l'événement"
            print("Error publishing event: \(error)")
        }
    }

    func closeEvent(_ event: AdminEvent) async {
        do {
            let updated = try await adminService.closeEvent(id: event.id)
            if let index = myEvents.firstIndex(where: { $0.id == event.id }) {
                myEvents[index] = updated
            }
        } catch {
            self.error = "Impossible de fermer l'événement"
            print("Error closing event: \(error)")
        }
    }

    func deleteEvent(_ event: AdminEvent) async -> Bool {
        do {
            try await adminService.deleteEvent(id: event.id)
            myEvents.removeAll { $0.id == event.id }
            return true
        } catch {
            self.error = "Impossible de supprimer l'événement"
            print("Error deleting event: \(error)")
            return false
        }
    }

    // MARK: - QR Code

    func loadQRCode(eventId: String) async {
        isLoadingQR = true

        do {
            currentQRCode = try await adminService.getQRCode(eventId: eventId)
        } catch {
            self.error = "Impossible de charger le QR code"
            print("Error loading QR code: \(error)")
        }

        isLoadingQR = false
    }

    func regenerateToken(eventId: String) async {
        isLoadingQR = true

        do {
            currentQRCode = try await adminService.regenerateToken(eventId: eventId)
        } catch {
            self.error = "Impossible de régénérer le token"
            print("Error regenerating token: \(error)")
        }

        isLoadingQR = false
    }

    // MARK: - Helper

    func resetForm() {
        eventName = ""
        eventDescription = ""
        locationName = ""
        locationAddress = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(3600 * 4)
        maxParticipants = ""
        coverImageUrl = ""
    }

    func getEvent(id: String) -> AdminEvent? {
        myEvents.first { $0.id == id }
    }
}
