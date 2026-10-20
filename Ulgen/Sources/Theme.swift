import SwiftUI
import UIKit

// MARK: - Color Tokens matching com.ulgen.takip.ui.theme.Color.kt 1:1

public struct AppTheme {
    // 1. Core Brand Colors (Teal / Cyan scale)
    public static let primary = Color(hex: "#0D9488")          // PrimarySolid / Theme500
    public static let primaryHover = Color(hex: "#0F766E")     // Theme600
    public static let primaryStart = Color(hex: "#0D9488")
    public static let primaryEnd = Color(hex: "#0891B2")
    public static let primaryLightTint = Color(hex: "#CCFBF1")    // Theme100
    public static let primarySoftBg = Color(hex: "#F0FDFA")      // Theme50

    // Header Brand Colors (Android DashboardHeader ulgenTitleColor: Bronze #8A4B1A in light, Amber #D97706 in dark)
    public static let headerTitleLight = Color(hex: "#8A4B1A")
    public static let headerTitleDark = Color(hex: "#D97706")
    public static func primaryHeader(isDark: Bool) -> Color {
        isDark ? headerTitleDark : headerTitleLight
    }

    // 2. Light Mode Tokens (Default Cream #FAF8F5)
    public static let bgLight = Color(hex: "#FAF8F5")
    public static let cardLight = Color(hex: "#FFFFFF")
    public static let cardHoverLight = Color(hex: "#FBF9F6")
    public static let borderLight = Color(hex: "#E2DDD5")
    public static let borderSubtleLight = Color(hex: "#E4E4DE")
    public static let textHeadingLight = Color(hex: "#2C1810")
    public static let textTurquoise = Color(hex: "#134E4A")
    public static let textBodyLight = Color(hex: "#374151")
    public static let textMutedLight = Color(hex: "#78716C")
    public static let textSubtitleLight = Color(hex: "#94A3B8")
    public static let glassBgLight = Color(hex: "#F5EFE6").opacity(0.85)

    // 3. Dark Mode Tokens (#1E1B18 & Obsidian #15181B)
    public static let bgDark = Color(hex: "#1E1B18")
    public static let cardDark = Color(hex: "#15181B")
    public static let cardSurfaceDark = Color(hex: "#292524")
    public static let cardHoverDark = Color(hex: "#44403C")
    public static let borderDark = Color(hex: "#44403C")
    public static let borderSubtleDark = Color(hex: "#2C3038")
    public static let textHeadingDark = Color(hex: "#F5F5F4")
    public static let textBodyDark = Color(hex: "#D6D3D1")
    public static let textMutedDark = Color(hex: "#A8A29E")
    public static let glassBgDark = Color(hex: "#292524").opacity(0.85)

    // Priority Colors
    public static let priorityLowLight = Color(hex: "#059669")
    public static let priorityLowDark = Color(hex: "#34D399")
    public static let priorityNormalLight = Color(hex: "#CA8A04")
    public static let priorityNormalDark = Color(hex: "#FACC15")
    public static let priorityHighLight = Color(hex: "#EA580C")
    public static let priorityHighDark = Color(hex: "#FB923C")
    public static let priorityUrgentLight = Color(hex: "#DC2626")
    public static let priorityUrgentDark = Color(hex: "#F87171")

    // Dynamic Helpers
    public static func bg(isDark: Bool) -> Color { isDark ? bgDark : bgLight }
    public static func card(isDark: Bool) -> Color { isDark ? cardDark : cardLight }
    public static func cardSurface(isDark: Bool) -> Color { isDark ? cardSurfaceDark : cardLight }
    public static func border(isDark: Bool) -> Color { isDark ? borderDark : borderLight }
    public static func borderSubtle(isDark: Bool) -> Color { isDark ? borderSubtleDark : borderSubtleLight }
    public static func textHeading(isDark: Bool) -> Color { isDark ? textHeadingDark : textHeadingLight }
    public static func textBody(isDark: Bool) -> Color { isDark ? textBodyDark : textBodyLight }
    public static func textMuted(isDark: Bool) -> Color { isDark ? textMutedDark : textMutedLight }

    // Priority bar color resolver
    public static func priorityColor(level: Int, isDark: Bool) -> Color {
        switch level {
        case 1: return isDark ? priorityLowDark : priorityLowLight
        case 2: return isDark ? priorityNormalDark : priorityNormalLight
        case 3: return isDark ? priorityHighDark : priorityHighLight
        case 4: return isDark ? priorityUrgentDark : priorityUrgentLight
        default: return isDark ? priorityNormalDark : priorityNormalLight
        }
    }
}

// MARK: - Category Specification (1:1 with CategoryBadge.kt)
public struct CategorySpec {
    public let id: String
    public let label: String
    public let systemImage: String
    public let accentColor: Color
    public let bgColor: Color
    public let textColor: Color
    public let borderColor: Color

    public static func resolve(categoryId: String?, isDarkMode: Bool) -> CategorySpec {
        let norm = (categoryId ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if norm.contains("ders") || norm.contains("egitim") || norm.contains("okul") || norm.contains("course") || norm == "blue" {
            return CategorySpec(
                id: "ders",
                label: "Ders",
                systemImage: "book.closed.fill",
                accentColor: Color(hex: "#2563EB"),
                bgColor: isDarkMode ? Color(hex: "#1E3A8A").opacity(0.28) : Color(hex: "#DBEAFE"),
                textColor: isDarkMode ? Color(hex: "#93C5FD") : Color(hex: "#1D4ED8"),
                borderColor: isDarkMode ? Color(hex: "#3B82F6").opacity(0.45) : Color(hex: "#93BBFD")
            )
        } else if norm.contains("proje") || norm.contains("yazilim") || norm.contains("kod") || norm.contains("dev") || norm == "green" {
            return CategorySpec(
                id: "proje",
                label: "Proje",
                systemImage: "chevron.left.forwardslash.chevron.right",
                accentColor: Color(hex: "#059669"),
                bgColor: isDarkMode ? Color(hex: "#064E3B").opacity(0.28) : Color(hex: "#D1FAE5"),
                textColor: isDarkMode ? Color(hex: "#6EE7B7") : Color(hex: "#047857"),
                borderColor: isDarkMode ? Color(hex: "#10B981").opacity(0.45) : Color(hex: "#6EE7B7")
            )
        } else if norm.contains("meslek") || norm.contains("kariyer") || norm.contains("is") || norm.contains("work") || norm == "purple" {
            return CategorySpec(
                id: "mesleki",
                label: "Mesleki",
                systemImage: "briefcase.fill",
                accentColor: Color(hex: "#7C3AED"),
                bgColor: isDarkMode ? Color(hex: "#581C87").opacity(0.28) : Color(hex: "#EDE9FE"),
                textColor: isDarkMode ? Color(hex: "#C4B5FD") : Color(hex: "#6D28D9"),
                borderColor: isDarkMode ? Color(hex: "#8B5CF6").opacity(0.45) : Color(hex: "#C4B5FD")
            )
        } else if norm.contains("hobi") || norm.contains("sanat") || norm.contains("muzik") || norm.contains("spor") || norm == "orange" {
            return CategorySpec(
                id: "hobi",
                label: "Hobi",
                systemImage: "paintpalette.fill",
                accentColor: Color(hex: "#EA580C"),
                bgColor: isDarkMode ? Color(hex: "#7C2D12").opacity(0.28) : Color(hex: "#FFEDD5"),
                textColor: isDarkMode ? Color(hex: "#FDBA74") : Color(hex: "#C2410C"),
                borderColor: isDarkMode ? Color(hex: "#F97316").opacity(0.45) : Color(hex: "#FDBA74")
            )
        } else if norm.contains("kisi") || norm.contains("personal") {
            return CategorySpec(
                id: "kisisel",
                label: "Kişisel",
                systemImage: "person.fill",
                accentColor: Color(hex: "#9333EA"),
                bgColor: isDarkMode ? Color(hex: "#581C87").opacity(0.28) : Color(hex: "#F3E8FF"),
                textColor: isDarkMode ? Color(hex: "#D8B4FE") : Color(hex: "#7E22CE"),
                borderColor: isDarkMode ? Color(hex: "#A855F7").opacity(0.45) : Color(hex: "#D8B4FE")
            )
        } else {
            return CategorySpec(
                id: "diger",
                label: (categoryId?.isEmpty == false) ? categoryId!.capitalized : "Diğer",
                systemImage: "folder",
                accentColor: Color(hex: "#6B7280"),
                bgColor: isDarkMode ? Color(hex: "#374151").opacity(0.28) : Color(hex: "#F3F4F6"),
                textColor: isDarkMode ? Color(hex: "#D1D5DB") : Color(hex: "#4B5563"),
                borderColor: isDarkMode ? Color(hex: "#6B7280").opacity(0.45) : Color(hex: "#D1D5DB")
            )
        }
    }
}

// MARK: - Color Hex Extension
public extension Color {
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexClean.count {
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

// MARK: - Priority Cellular Signal Bars Component (1:1 with PrioritySignalBars in ProjectCard.kt)
public struct PrioritySignalBarsView: View {
    public var priority: String?
    public var isDarkMode: Bool
    public var isSmall: Bool = false

    public init(priority: String?, isDarkMode: Bool, isSmall: Bool = false) {
        self.priority = priority
        self.isDarkMode = isDarkMode
        self.isSmall = isSmall
    }

    private var activeBars: Int {
        let norm = (priority ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch norm {
        case "low", "dusuk", "düşük", "green": return 1
        case "normal", "orta", "medium", "yellow": return 2
        case "high", "yuksek", "yüksek", "orange": return 3
        case "urgent", "acil", "red", "very_high": return 4
        default: return 2
        }
    }

    private var activeColor: Color {
        AppTheme.priorityColor(level: activeBars, isDark: isDarkMode)
    }

    private var inactiveColor: Color {
        isDarkMode ? Color(hex: "#374151").opacity(0.6) : Color(hex: "#CBD5E1").opacity(0.7)
    }

    public var body: some View {
        let barW: CGFloat = isSmall ? 2.5 : 3.0
        let spacing: CGFloat = isSmall ? 2.0 : 2.5
        let h1: CGFloat = isSmall ? 3.5 : 4.0
        let h2: CGFloat = isSmall ? 6.0 : 7.0
        let h3: CGFloat = isSmall ? 8.5 : 10.0
        let h4: CGFloat = isSmall ? 11.0 : 13.0

        HStack(alignment: .bottom, spacing: spacing) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(activeBars >= 1 ? activeColor : inactiveColor)
                .frame(width: barW, height: h1)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(activeBars >= 2 ? activeColor : inactiveColor)
                .frame(width: barW, height: h2)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(activeBars >= 3 ? activeColor : inactiveColor)
                .frame(width: barW, height: h3)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(activeBars >= 4 ? activeColor : inactiveColor)
                .frame(width: barW, height: h4)
        }
    }
}

// MARK: - Category Vector Icon (1:1 with CategoryVectorIcon in ProjectCard.kt)
public struct CategoryVectorIconView: View {
    public var categoryId: String?
    public var isDarkMode: Bool

    public init(categoryId: String?, isDarkMode: Bool) {
        self.categoryId = categoryId
        self.isDarkMode = isDarkMode
    }

    public var body: some View {
        let spec = CategorySpec.resolve(categoryId: categoryId, isDarkMode: isDarkMode)
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(spec.bgColor)
                .frame(width: 34, height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(spec.borderColor, lineWidth: 1)
                )

            Image(systemName: spec.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(spec.accentColor)
        }
    }
}

// MARK: - Six Dot Drag Handle View (1:1 with SixDotDragHandle in ProjectCard.kt)
public struct SixDotDragHandleView: View {
    public var tint: Color

    public init(tint: Color = Color.gray.opacity(0.45)) {
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 2.5) {
            VStack(spacing: 3) {
                Circle().fill(tint).frame(width: 2.5, height: 2.5)
                Circle().fill(tint).frame(width: 2.5, height: 2.5)
                Circle().fill(tint).frame(width: 2.5, height: 2.5)
            }
            VStack(spacing: 3) {
                Circle().fill(tint).frame(width: 2.5, height: 2.5)
                Circle().fill(tint).frame(width: 2.5, height: 2.5)
                Circle().fill(tint).frame(width: 2.5, height: 2.5)
            }
        }
        .frame(width: 14, height: 20)
    }
}

// MARK: - Hex Color Parser Helper
public func parseHexColor(_ hex: String?) -> Color? {
    guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else { return nil }
    var clean = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    if clean.count == 3 {
        clean = clean.map { "\($0)\($0)" }.joined()
    }
    guard clean.count == 6 || clean.count == 8 else { return nil }
    var int: UInt64 = 0
    guard Scanner(string: clean).scanHexInt64(&int) else { return nil }
    if clean.count == 6 {
        return Color(
            .sRGB,
            red: Double((int >> 16) & 0xFF) / 255.0,
            green: Double((int >> 8) & 0xFF) / 255.0,
            blue: Double(int & 0xFF) / 255.0,
            opacity: 1.0
        )
    } else {
        return Color(
            .sRGB,
            red: Double((int >> 16) & 0xFF) / 255.0,
            green: Double((int >> 8) & 0xFF) / 255.0,
            blue: Double(int & 0xFF) / 255.0,
            opacity: Double((int >> 24) & 0xFF) / 255.0
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

// MARK: - Neumorphic & Liquid Glass Card Modifiers
public struct NeumorphicCardModifier: ViewModifier {
    public var isDark: Bool
    public var cornerRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .background(AppTheme.card(isDark: isDark))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.borderSubtle(isDark: isDark), lineWidth: 1)
            )
            .cornerRadius(cornerRadius)
            .shadow(
                color: isDark ? Color.black.opacity(0.45) : Color.black.opacity(0.05),
                radius: 6,
                x: 0,
                y: 2
            )
    }
}

public extension View {
    func neumorphicCard(isDark: Bool, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(NeumorphicCardModifier(isDark: isDark, cornerRadius: cornerRadius))
    }
}
