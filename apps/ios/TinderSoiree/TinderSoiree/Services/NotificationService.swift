import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Types

enum NotificationType: String, Codable {
    case newMatch = "NEW_MATCH"
    case newMessage = "NEW_MESSAGE"
    case eventUpdate = "EVENT_UPDATE"
    case eventReminder = "EVENT_REMINDER"
}

struct PushNotificationPayload: Codable {
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: String]?
}

// MARK: - Device Token Request

struct RegisterDeviceTokenRequest: Encodable {
    let token: String
    let platform: String = "ios"
}

struct UnregisterDeviceTokenRequest: Encodable {
    let token: String
}

// MARK: - Notification Service

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var deviceToken: String?

    private let apiClient = APIClient.shared
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    // MARK: - Permission Request

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted

            if granted {
                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Device Token Management

    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        print("Device token: \(token)")

        // Register with backend
        Task {
            await registerDeviceToken(token)
        }
    }

    func handleDeviceTokenError(_ error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    private func registerDeviceToken(_ token: String) async {
        do {
            let request = RegisterDeviceTokenRequest(token: token)
            let _: EmptyResponse = try await apiClient.post("/notifications/register", body: request)
            print("Device token registered with backend")
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    func unregisterDeviceToken() async {
        guard let token = deviceToken else { return }

        do {
            let request = UnregisterDeviceTokenRequest(token: token)
            let _: EmptyResponse = try await apiClient.post("/notifications/unregister", body: request)
            print("Device token unregistered")
        } catch {
            print("Failed to unregister device token: \(error)")
        }
    }

    // MARK: - Handle Incoming Notifications

    func handleNotification(_ userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        print("Received notification: \(userInfo)")

        // Parse notification type
        if let typeString = userInfo["type"] as? String,
           let type = NotificationType(rawValue: typeString) {

            switch type {
            case .newMatch:
                handleNewMatchNotification(userInfo)
            case .newMessage:
                handleNewMessageNotification(userInfo)
            case .eventUpdate:
                handleEventUpdateNotification(userInfo)
            case .eventReminder:
                handleEventReminderNotification(userInfo)
            }
        }

        completion()
    }

    private func handleNewMatchNotification(_ userInfo: [AnyHashable: Any]) {
        if let matchId = userInfo["matchId"] as? String {
            // Navigate to match
            NotificationCenter.default.post(
                name: .navigateToMatch,
                object: nil,
                userInfo: ["matchId": matchId]
            )
        }
    }

    private func handleNewMessageNotification(_ userInfo: [AnyHashable: Any]) {
        if let matchId = userInfo["matchId"] as? String {
            // Navigate to chat
            NotificationCenter.default.post(
                name: .navigateToChat,
                object: nil,
                userInfo: ["matchId": matchId]
            )
        }
    }

    private func handleEventUpdateNotification(_ userInfo: [AnyHashable: Any]) {
        // Refresh event data
        NotificationCenter.default.post(name: .refreshEventData, object: nil)
    }

    private func handleEventReminderNotification(_ userInfo: [AnyHashable: Any]) {
        // Show event reminder
        if let eventId = userInfo["eventId"] as? String {
            NotificationCenter.default.post(
                name: .showEventReminder,
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
    }

    // MARK: - Local Notifications

    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval = 1,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule local notification: \(error)")
            }
        }
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Badge Management

    func setBadgeCount(_ count: Int) {
        Task { @MainActor in
            if #available(iOS 16.0, *) {
                try? await center.setBadgeCount(count)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }

    func clearBadge() {
        setBadgeCount(0)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToMatch = Notification.Name("navigateToMatch")
    static let navigateToChat = Notification.Name("navigateToChat")
    static let refreshEventData = Notification.Name("refreshEventData")
    static let showEventReminder = Notification.Name("showEventReminder")
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    // Called when notification is received while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }

    // Called when user taps on notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        Task { @MainActor in
            self.handleNotification(userInfo, completion: completionHandler)
        }
    }
}
