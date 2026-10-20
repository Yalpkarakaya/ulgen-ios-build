import SwiftUI
import UIKit

// MARK: - Color Tokens matching com.ulgen.takip.ui.theme.Color.kt

public struct AppTheme {
    // 1. Core Brand Colors (Teal / Cyan scale)
    public static let primary = Color(hex: "#0D9488")       // PrimarySolid / Theme500
    public static let primaryHover = Color(hex: "#0F766E")  // Theme600
    public static let primaryStart = Color(hex: "#0D9488")
    public static let primaryEnd = Color(hex: "#0891B2")
    public static let primaryLightTint = Color(hex: "#CCFBF1") // Theme100
    public static let primarySoftBg = Color(hex: "#F0FDFA")   // Theme50

    // 2. Light Mode Tokens (Default Cream #FAF8F5)
    public static let bgLight = Color(hex: "#FAF8F5")
    public static let cardLight = Color(hex: "#FFFFFF")
    public static let cardHoverLight = Color(hex: "#FBF9F6")
    public static let borderLight = Color(hex: "#E2DDD5")
    public static let textHeadingLight = Color(hex: "#2C1810")
    public static let textTurquoise = Color(hex: "#134E4A")
    public static let textBodyLight = Color(hex: "#374151")
    public static let textMutedLight = Color(hex: "#6B7280")
    public static let glassBgLight = Color(hex: "#F5EFE6").opacity(0.85)

    // 3. Dark Mode Tokens (#1E1B18)
    public static let bgDark = Color(hex: "#1E1B18")
    public static let cardDark = Color(hex: "#292524")
    public static let cardHoverDark = Color(hex: "#44403C")
    public static let borderDark = Color(hex: "#44403C")
    public static let textHeadingDark = Color(hex: "#F5F5F4")
    public static let textBodyDark = Color(hex: "#D6D3D1")
    public static let textMutedDark = Color(hex: "#A8A29E")
    public static let glassBgDark = Color(hex: "#292524").opacity(0.85)

    // Priority Colors
    public static let priorityHigh = Color(hex: "#EF4444")
    public static let priorityMedium = Color(hex: "#F59E0B")
    public static let priorityLow = Color(hex: "#10B981")

    // Dynamic Helpers
    public static func bg(isDark: Bool) -> Color { isDark ? bgDark : bgLight }
    public static func card(isDark: Bool) -> Color { isDark ? cardDark : cardLight }
    public static func border(isDark: Bool) -> Color { isDark ? borderDark : borderLight }
    public static func textHeading(isDark: Bool) -> Color { isDark ? textHeadingDark : textHeadingLight }
    public static func textBody(isDark: Bool) -> Color { isDark ? textBodyDark : textBodyLight }
    public static func textMuted(isDark: Bool) -> Color { isDark ? textMutedDark : textMutedLight }
}

// MARK: - Color Hex Extension
public extension Color {
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
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Taptic Feedback
public struct Haptics {
    public static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    public static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    public static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Custom Card Modifiers
public struct NeumorphicCardModifier: ViewModifier {
    public var isDark: Bool
    public var cornerRadius: CGFloat = 16

    public func body(content: Content) -> some View {
        content
            .background(AppTheme.card(isDark: isDark))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.border(isDark: isDark), lineWidth: 1)
            )
            .cornerRadius(cornerRadius)
            .shadow(
                color: isDark ? Color.black.opacity(0.4) : Color.black.opacity(0.04),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

public extension View {
    func neumorphicCard(isDark: Bool, cornerRadius: CGFloat = 16) -> some View {
        self.modifier(NeumorphicCardModifier(isDark: isDark, cornerRadius: cornerRadius))
    }
}

// MARK: - Stepper Button Style
public struct QuantityStepButtonStyle: ButtonStyle {
    public var isDark: Bool
    public init(isDark: Bool) {
        self.isDark = isDark
    }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(AppTheme.textHeading(isDark: isDark))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            .cornerRadius(4)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
