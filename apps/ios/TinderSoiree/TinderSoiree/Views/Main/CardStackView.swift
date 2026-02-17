import SwiftUI

struct CardStackView: View {
    let profiles: [StackProfile]
    let onSwipe: (StackProfile, SwipeAction) -> Void
    let onTap: (StackProfile) -> Void

    var body: some View {
        ZStack {
            ForEach(Array(profiles.prefix(3).enumerated().reversed()), id: \.element.id) { index, profile in
                ProfileCardView(
                    profile: profile,
                    isTopCard: index == 0,
                    onSwipe: { action in
                        onSwipe(profile, action)
                    },
                    onTap: {
                        onTap(profile)
                    }
                )
                .offset(y: CGFloat(index) * 8)
                .scaleEffect(1 - CGFloat(index) * 0.05)
            }
        }
        .padding()
    }
}

struct ProfileCardView: View {
    let profile: StackProfile
    let isTopCard: Bool
    let onSwipe: (SwipeAction) -> Void
    let onTap: () -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var currentPhotoIndex = 0

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Photo with tap zones for navigation
                ZStack {
                    if let photoUrl = profile.photos.indices.contains(currentPhotoIndex) ? profile.photos[currentPhotoIndex].url : profile.photos.first?.url,
                       let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(AppTheme.cardBackground)
                                    .overlay {
                                        ProgressView()
                                            .tint(AppTheme.primaryPink)
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(AppTheme.cardBackground)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                            @unknown default:
                                Rectangle()
                                    .fill(AppTheme.cardBackground)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(AppTheme.cardBackground)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                    }

                    // Tap zones for photo navigation
                    if isTopCard && profile.photos.count > 1 {
                        HStack(spacing: 0) {
                            // Left tap zone - previous photo
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentPhotoIndex = max(0, currentPhotoIndex - 1)
                                    }
                                }

                            // Right tap zone - next photo
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentPhotoIndex = min(profile.photos.count - 1, currentPhotoIndex + 1)
                                    }
                                }
                        }
                    }
                }

                // Photo indicators
                if profile.photos.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(profile.photos.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index == currentPhotoIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
                }

                // Info overlay
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom) {
                        Text("\(profile.firstName), \(profile.age)")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }

                    // Tap hint
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                        Text("Appuie pour voir plus")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.clear, AppTheme.deepBlack.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onTapGesture {
                    onTap()
                }

                // Swipe indicators
                if isTopCard {
                    HStack {
                        // Like indicator
                        Text("LIKE")
                            .font(.title.bold())
                            .foregroundColor(AppTheme.success)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.success, lineWidth: 4)
                            )
                            .rotationEffect(.degrees(-15))
                            .opacity(Double(offset.width / swipeThreshold).clamped(to: 0...1))

                        Spacer()

                        // Nope indicator
                        Text("NOPE")
                            .font(.title.bold())
                            .foregroundColor(AppTheme.error)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.error, lineWidth: 4)
                            )
                            .rotationEffect(.degrees(15))
                            .opacity(Double(-offset.width / swipeThreshold).clamped(to: 0...1))
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 50)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXL))
            .shadow(color: AppTheme.primaryShadow, radius: 10, y: 5)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .gesture(
                isTopCard ? DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        rotation = Double(gesture.translation.width / 20)
                    }
                    .onEnded { gesture in
                        handleSwipeEnd(gesture: gesture)
                    }
                : nil
            )
        }
        .aspectRatio(0.7, contentMode: .fit)
    }

    private func handleSwipeEnd(gesture: DragGesture.Value) {
        if offset.width > swipeThreshold {
            swipeAway(to: .right, action: .like)
        } else if offset.width < -swipeThreshold {
            swipeAway(to: .left, action: .dislike)
        } else {
            withAnimation(.spring()) {
                offset = .zero
                rotation = 0
            }
        }
    }

    private func swipeAway(to direction: SwipeDirection, action: SwipeAction) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(
                width: direction == .right ? 500 : -500,
                height: 0
            )
            rotation = direction == .right ? 20 : -20
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(action)
        }
    }

    enum SwipeDirection {
        case left, right
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    CardStackView(
        profiles: [
            StackProfile(
                id: "1",
                firstName: "Marie",
                age: 25,
                bio: "J'adore les soirees !",
                photos: [],
                gender: .female
            )
        ],
        onSwipe: { _, _ in },
        onTap: { _ in }
    )
    .background(AppTheme.deepBlack)
}
