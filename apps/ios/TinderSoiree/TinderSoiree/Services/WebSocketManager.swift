import Foundation

enum WebSocketEvent {
    case newMatch(Match)
    case newMessage(Message)
    case connected
    case disconnected
}

@MainActor
class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false

    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var eventHandlers: [(WebSocketEvent) -> Void] = []

    private init() {}

    func connect(token: String) {
        guard webSocket == nil else { return }

        let baseURL = AppEnvironment.current.wsURL
        guard var urlComponents = URLComponents(string: baseURL) else { return }
        urlComponents.queryItems = [URLQueryItem(name: "token", value: token)]

        guard let url = urlComponents.url else { return }

        urlSession = URLSession(configuration: .default)
        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()

        isConnected = true
        receiveMessage()

        notify(.connected)
    }

    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        urlSession = nil
        isConnected = false

        notify(.disconnected)
    }

    func addEventHandler(_ handler: @escaping (WebSocketEvent) -> Void) {
        eventHandlers.append(handler)
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task { @MainActor in
                    self?.handleMessage(message)
                    self?.receiveMessage()
                }
            case .failure(let error):
                print("WebSocket error: \(error)")
                Task { @MainActor in
                    self?.isConnected = false
                    self?.notify(.disconnected)
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseEvent(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseEvent(text)
            }
        @unknown default:
            break
        }
    }

    private func parseEvent(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let eventType = json?["event"] as? String,
                  let payload = json?["data"] else { return }

            let payloadData = try JSONSerialization.data(withJSONObject: payload)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            switch eventType {
            case "match:new":
                let match = try decoder.decode(Match.self, from: payloadData)
                notify(.newMatch(match))

            case "message:new":
                let message = try decoder.decode(Message.self, from: payloadData)
                notify(.newMessage(message))

            default:
                print("Unknown WebSocket event: \(eventType)")
            }
        } catch {
            print("Failed to parse WebSocket message: \(error)")
        }
    }

    private func notify(_ event: WebSocketEvent) {
        for handler in eventHandlers {
            handler(event)
        }
    }

    func send(event: String, data: Encodable) {
        guard let webSocket = webSocket else { return }

        do {
            let encoder = JSONEncoder()
            let payloadData = try encoder.encode(data)
            let payload = try JSONSerialization.jsonObject(with: payloadData)

            let message: [String: Any] = [
                "event": event,
                "data": payload
            ]

            let messageData = try JSONSerialization.data(withJSONObject: message)
            if let messageString = String(data: messageData, encoding: .utf8) {
                webSocket.send(.string(messageString)) { error in
                    if let error = error {
                        print("WebSocket send error: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to send WebSocket message: \(error)")
        }
    }
}
