import Foundation

// MARK: - Request Models

struct CreateEventRequest: Encodable {
    let name: String
    let description: String?
    let locationName: String
    let locationAddress: String?
    let startAt: String
    let endAt: String
    let maxParticipants: Int?
    let coverImageUrl: String?
}

struct PublishEventRequest: Encodable {
    let status: String
}

// MARK: - Response Models

struct AdminEvent: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let locationName: String
    let locationAddress: String?
    let coverImageUrl: String?
    let startAt: String
    let endAt: String
    let status: EventStatus
    let maxParticipants: Int?
    let participantCount: Int?
    let createdAt: String
}

struct QRCodeResponse: Codable {
    let qrCodeUrl: String      // Base64 data URL
    let joinUrl: String        // Web URL
    let deepLinkUrl: String    // App deep link
    let nfcPayload: String     // Payload for NFC
}

struct AdminEventsResponse: Codable {
    let events: [AdminEvent]
}

struct AdminEventResponse: Codable {
    let event: AdminEvent
}

// MARK: - Admin Service

class AdminService {
    static let shared = AdminService()

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Event Management

    /// Create a new event
    func createEvent(
        name: String,
        description: String?,
        locationName: String,
        locationAddress: String?,
        startAt: Date,
        endAt: Date,
        maxParticipants: Int?,
        coverImageUrl: String?
    ) async throws -> AdminEvent {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        let request = CreateEventRequest(
            name: name,
            description: description,
            locationName: locationName,
            locationAddress: locationAddress,
            startAt: dateFormatter.string(from: startAt),
            endAt: dateFormatter.string(from: endAt),
            maxParticipants: maxParticipants,
            coverImageUrl: coverImageUrl
        )

        let response: AdminEventResponse = try await apiClient.post("/admin/events", body: request)
        return response.event
    }

    /// Get all events created by the current user
    func getMyEvents() async throws -> [AdminEvent] {
        let response: AdminEventsResponse = try await apiClient.get("/admin/events")
        return response.events
    }

    /// Get a specific event
    func getEvent(id: String) async throws -> AdminEvent {
        return try await apiClient.get("/admin/events/\(id)")
    }

    /// Publish an event (change status to LIVE)
    func publishEvent(id: String) async throws -> AdminEvent {
        let response: AdminEventResponse = try await apiClient.post("/admin/events/\(id)/publish", body: EmptyBody())
        return response.event
    }

    /// Close an event
    func closeEvent(id: String) async throws -> AdminEvent {
        let response: AdminEventResponse = try await apiClient.post("/admin/events/\(id)/close", body: EmptyBody())
        return response.event
    }

    /// Delete an event (only draft events)
    func deleteEvent(id: String) async throws {
        let _: EmptyResponse = try await apiClient.delete("/admin/events/\(id)")
    }

    // MARK: - QR Code

    /// Get QR code and join URLs for an event
    func getQRCode(eventId: String) async throws -> QRCodeResponse {
        return try await apiClient.get("/admin/events/\(eventId)/qr")
    }

    /// Generate a new join token for an event
    func regenerateToken(eventId: String) async throws -> QRCodeResponse {
        return try await apiClient.post("/admin/events/\(eventId)/regenerate-token", body: EmptyBody())
    }
}

// Empty body for POST requests that don't need a body
struct EmptyBody: Encodable {}

// Empty response for DELETE requests
struct EmptyResponse: Decodable {}
