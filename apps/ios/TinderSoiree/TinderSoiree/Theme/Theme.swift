import SwiftUI
import UIKit

// MARK: - App Theme
struct AppTheme {

    // MARK: - Primary Colors
    static let primaryPurple = Color(hex: "8B5CF6")
    static let primaryPink = Color(hex: "EC4899")
    static let primaryViolet = Color(hex: "7C3AED")

    // MARK: - Background Colors
    static let deepBlack = Color(hex: "0A0A0A")
    static let darkGray = Color(hex: "1C1C1E")
    static let cardBackground = Color(hex: "1F1F23")
    static let inputBackground = Color(hex: "2C2C2E")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)

    // MARK: - Accent Colors
    static let success = Color(hex: "10B981")
    static let error = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primaryPurple, primaryPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleGradient = LinearGradient(
        colors: [primaryPurple.opacity(0.8), primaryPink.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkGradient = LinearGradient(
        colors: [deepBlack, darkGray],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [Color.black.opacity(0), Color.black.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadows
    static let primaryShadow = Color.black.opacity(0.3)
    static let glowShadow = primaryPurple.opacity(0.4)

    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct PrimaryButtonStyle: ViewModifier {
    var isDisabled: Bool = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if isDisabled {
            content
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.inputBackground)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.cornerRadiusMedium)
        } else {
            content
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .shadow(color: AppTheme.glowShadow, radius: 8, y: 4)
        }
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardBackground)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(AppTheme.primaryPurple.opacity(0.5), lineWidth: 1)
            )
    }
}

struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.inputBackground)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
            )
    }
}

struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground.opacity(0.8))
            .cornerRadius(AppTheme.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple.opacity(0.3), AppTheme.primaryPink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: AppTheme.primaryShadow, radius: 10, y: 5)
    }
}

// MARK: - View Extensions
extension View {
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isDisabled: isDisabled))
    }

    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonStyle())
    }

    func appTextFieldStyle() -> some View {
        modifier(AppTextFieldStyle())
    }

    func glassCard() -> some View {
        modifier(GlassCardStyle())
    }
}

// MARK: - Message Bubble Styles
struct MessageBubbleStyle {
    static func bubbleColor(isFromCurrentUser: Bool) -> some ShapeStyle {
        if isFromCurrentUser {
            return AnyShapeStyle(AppTheme.primaryGradient)
        } else {
            return AnyShapeStyle(AppTheme.cardBackground)
        }
    }

    static let sentBubbleCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft]
    static let receivedBubbleCorners: UIRectCorner = [.topLeft, .topRight, .bottomRight]
}

// MARK: - Custom Shapes
struct BubbleShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview("Theme Colors") {
    ScrollView {
        VStack(spacing: 20) {
            // Gradient Demo
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.primaryGradient)
                .frame(height: 100)
                .overlay(
                    Text("Primary Gradient")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )

            // Colors Demo
            HStack(spacing: 10) {
                colorSwatch(AppTheme.primaryPurple, "Purple")
                colorSwatch(AppTheme.primaryPink, "Pink")
                colorSwatch(AppTheme.deepBlack, "Black")
                colorSwatch(AppTheme.darkGray, "Gray")
            }

            // Button Styles
            Button("Primary Button") {}
                .primaryButtonStyle()

            Button("Secondary Button") {}
                .secondaryButtonStyle()

            // Text Field
            TextField("Input Field", text: .constant(""))
                .appTextFieldStyle()

            // Card
            VStack {
                Text("Glass Card")
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .glassCard()
        }
        .padding()
    }
    .background(AppTheme.deepBlack)
}

private func colorSwatch(_ color: Color, _ name: String) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 60)
        Text(name)
            .font(.caption)
            .foregroundColor(.white)
    }
}
