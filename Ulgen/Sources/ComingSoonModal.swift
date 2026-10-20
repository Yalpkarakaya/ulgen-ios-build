import SwiftUI

public struct ComingSoonModal: View {
    public var featureName: String
    public var description: String? = nil
    public var isDarkMode: Bool
    public var onDismiss: () -> Void

    public init(
        featureName: String,
        description: String? = nil,
        isDarkMode: Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.featureName = featureName
        self.description = description
        self.isDarkMode = isDarkMode
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Modal Card
            VStack(spacing: 0) {
                // Header Row (Close Button)
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textMuted(isDark: isDarkMode))
                            .frame(width: 32, height: 32)
                            .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.scaleSpring(scale: 0.90))
                }
                .padding(.bottom, 6)

                // Hourglass Icon Emblem (Zero Emoji)
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color(hex: "#0F766E").opacity(0.25) : Color(hex: "#CCFBF1"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isDarkMode ? Color(hex: "#14B8A6").opacity(0.4) : Color(hex: "#99F6E4"), lineWidth: 1)
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "hourglass")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "#0D9488"))
                }
                .padding(.bottom, 16)

                // Feature Name Title
                Text(featureName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)

                // "YAKINDA" Badge
                Text("YAKINDA")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isDarkMode ? Color(hex: "#5EEAD4") : Color(hex: "#0F766E"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isDarkMode ? Color(hex: "#134E4A") : Color(hex: "#CCFBF1"))
                    .cornerRadius(6)
                    .padding(.bottom, 14)

                // Description
                Text(description ?? "Bu modül aktif geliştirme aşamasındadır. Yaklaşan güncelleme ile donanım ve proje takip iş akışlarınıza entegre edilecektir.")
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .foregroundColor(AppTheme.textMuted(isDark: isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 22)

                // Primary Button
                Button(action: onDismiss) {
                    Text("Anladım")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .buttonStyle(.scaleSpring(scale: 0.95))
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(isDarkMode ? Color(hex: "#1E1B18") : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.border(isDark: isDarkMode), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDarkMode ? 0.5 : 0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
    }
}
