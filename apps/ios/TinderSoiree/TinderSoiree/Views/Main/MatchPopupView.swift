import SwiftUI

struct MatchPopupView: View {
    @EnvironmentObject var appState: AppState

    let matchedUser: MatchUser

    @State private var showAnimation = false

    var body: some View {
        ZStack {
            // Background
            AppTheme.deepBlack.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Animated gradient circles
            Circle()
                .fill(AppTheme.primaryPurple.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: showAnimation ? -50 : -100, y: -200)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showAnimation)

            Circle()
                .fill(AppTheme.primaryPink.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: showAnimation ? 50 : 100, y: 200)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showAnimation)

            VStack(spacing: 30) {
                Spacer()

                // Title with gradient
                Text("C'est un Match !")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(AppTheme.primaryGradient)
                    .scaleEffect(showAnimation ? 1 : 0.5)
                    .opacity(showAnimation ? 1 : 0)

                Text("Toi et \(matchedUser.firstName) vous vous etes likes")
                    .font(.title3)
                    .foregroundColor(AppTheme.textSecondary)
                    .opacity(showAnimation ? 1 : 0)

                // Photo
                Group {
                    if let photoUrl = matchedUser.photos.first?.url,
                       let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Circle()
                                    .fill(AppTheme.cardBackground)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                            }
                        }
                    } else {
                        Circle()
                            .fill(AppTheme.cardBackground)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                    }
                }
                .frame(width: 160, height: 160)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppTheme.primaryGradient, lineWidth: 4)
                )
                .shadow(color: AppTheme.primaryPurple.opacity(0.5), radius: 25)
                .scaleEffect(showAnimation ? 1 : 0.3)

                Text("\(matchedUser.firstName)\(matchedUser.age != nil ? ", \(matchedUser.age!)" : "")")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .opacity(showAnimation ? 1 : 0)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    Button(action: sendMessage) {
                        Text("Envoyer un message")
                            .font(.headline)
                    }
                    .primaryButtonStyle()

                    Button(action: dismiss) {
                        Text("Continuer a swiper")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(showAnimation ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showAnimation = true
            }
        }
    }

    private func sendMessage() {
        // Navigate to chat with this match
        withAnimation {
            appState.navigateToChatFromMatch()
        }
    }

    private func dismiss() {
        withAnimation {
            appState.dismissMatchPopup()
        }
    }
}

#Preview {
    MatchPopupView(
        matchedUser: MatchUser(
            id: "1",
            firstName: "Marie",
            photos: [],
            bio: nil,
            age: 25
        )
    )
    .environmentObject(AppState())
}
