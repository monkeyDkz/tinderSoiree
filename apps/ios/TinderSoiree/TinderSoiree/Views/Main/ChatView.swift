import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    let match: Match

    init(match: Match) {
        self.match = match
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            matchId: match.id,
            otherUser: match.user
        ))
    }

    var body: some View {
        ZStack {
            // Background
            AppTheme.deepBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.isLoading && viewModel.messages.isEmpty {
                                ProgressView()
                                    .tint(AppTheme.primaryPink)
                                    .padding()
                            }

                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isFromCurrentUser: message.senderId != match.user.id
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                ChatInputView(
                    text: $viewModel.messageText,
                    isSending: viewModel.isSending,
                    isFocused: $isInputFocused,
                    onSend: sendMessage
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
                    if let photoUrl = match.user.photos.first?.url,
                       let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Circle()
                                    .fill(AppTheme.cardBackground)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppTheme.primaryGradient, lineWidth: 2)
                        )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.user.firstName)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("En ligne")
                            .font(.caption2)
                            .foregroundColor(AppTheme.success)
                    }
                }
            }
        }
        .toolbarBackground(AppTheme.darkGray, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await viewModel.loadMessages()
        }
    }

    private func sendMessage() {
        Task {
            await viewModel.sendMessage()
        }
    }
}

// MARK: - Chat Input View
struct ChatInputView: View {
    @Binding var text: String
    let isSending: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        HStack(spacing: 12) {
            // Text field
            HStack(spacing: 8) {
                TextField("Message...", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .focused(isFocused)
                    .foregroundColor(.white)

                // Emoji button (placeholder)
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.inputBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isFocused.wrappedValue ? AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.2),
                        lineWidth: 1
                    )
            )

            // Send button
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(canSend ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.inputBackground], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)

                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(canSend ? .white : AppTheme.textTertiary)
                            .offset(x: -1, y: 1)
                    }
                }
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.2), value: canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(AppTheme.darkGray)
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(
                        Group {
                            if isFromCurrentUser {
                                AppTheme.primaryGradient
                            } else {
                                AppTheme.cardBackground
                            }
                        }
                    )
                    .clipShape(BubbleShape(
                        corners: isFromCurrentUser
                            ? [.topLeft, .topRight, .bottomLeft]
                            : [.topLeft, .topRight, .bottomRight],
                        radius: 18
                    ))
                    .shadow(color: AppTheme.primaryShadow.opacity(0.3), radius: 3, y: 2)

                // Time and read status
                HStack(spacing: 4) {
                    Text(formatTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)

                    if isFromCurrentUser {
                        Image(systemName: message.readAt != nil ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(message.readAt != nil ? AppTheme.success : AppTheme.textTertiary)
                    }
                }
            }

            if !isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

        return ""
    }
}

#Preview {
    NavigationStack {
        ChatView(match: Match(
            id: "1",
            user: MatchUser(
                id: "2",
                firstName: "Marie",
                photos: [],
                bio: nil,
                age: 25
            ),
            eventId: "event1",
            event: nil,
            lastMessage: nil,
            unreadCount: 0,
            createdAt: "2024-01-01T12:00:00Z"
        ))
    }
}
