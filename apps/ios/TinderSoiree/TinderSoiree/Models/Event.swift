import Foundation

enum EventStatus: String, Codable {
    case draft
    case live
    case closed
    case cancelled
}

enum CheckinSource: String, Codable {
    case nfc
    case qr
    case manual
    case deepLink = "deep_link"
}

struct Event: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let locationName: String
    let locationAddress: String?
    let coverImageUrl: String?
    let startAt: String
    let endAt: String
    let status: EventStatus
    let participantCount: Int?
}

struct Checkin: Codable, Identifiable {
    let id: String
    let joinedAt: String
    let leftAt: String?
    let source: CheckinSource?
}

struct JoinEventResponse: Codable {
    let checkin: Checkin
    let event: Event
}

struct CurrentEventResponse: Codable {
    let event: Event?
    let checkin: Checkin?
}

struct EventHistoryItem: Codable {
    let event: Event
    let checkin: Checkin
}

struct EventHistoryResponse: Codable {
    let events: [EventHistoryItem]
}
