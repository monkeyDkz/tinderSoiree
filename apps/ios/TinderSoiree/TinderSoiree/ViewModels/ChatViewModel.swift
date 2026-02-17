import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?
    @Published var messageText = ""

    private var nextCursor: String?
    private var hasMore = true
    private let chatService = ChatService.shared

    let matchId: String
    let otherUser: MatchUser

    init(matchId: String, otherUser: MatchUser) {
        self.matchId = matchId
        self.otherUser = otherUser
    }

    func loadMessages() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await chatService.getMessages(matchId: matchId)
            // Messages are already sorted oldest to newest from backend
            messages = response.messages
            nextCursor = response.pagination.oldestCursor
            hasMore = response.pagination.hasMore
            isLoading = false

            // Mark last message as read
            if let lastMessage = messages.last {
                _ = try? await chatService.markAsRead(matchId: matchId, upToMessageId: lastMessage.id)
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoading, hasMore, let cursor = nextCursor else { return }

        isLoading = true

        do {
            let response = try await chatService.getMessages(matchId: matchId, before: cursor)
            // Older messages go at the beginning, they're already sorted oldest to newest
            messages.insert(contentsOf: response.messages, at: 0)
            nextCursor = response.pagination.oldestCursor
            hasMore = response.pagination.hasMore
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        isSending = true
        messageText = ""

        do {
            let response = try await chatService.sendMessage(matchId: matchId, content: text)
            messages.append(response.message)
            isSending = false
        } catch {
            messageText = text
            isSending = false
            self.error = error.localizedDescription
        }
    }

    func addReceivedMessage(_ message: Message) {
        if !messages.contains(where: { $0.id == message.id }) {
            messages.append(message)
        }
    }
}
