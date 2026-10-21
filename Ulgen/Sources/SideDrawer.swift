import SwiftUI

public struct SideDrawer: View {
    @Binding var isOpen: Bool
    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var mqtt = MqttSyncEngine.shared
    @ObservedObject var drive = GoogleDriveSyncEngine.shared
    @State private var comingSoonFeature: String? = nil
    @State private var showingGoogleSignIn: Bool = false

    var onSelectView: (String) -> Void

    public var body: some View {
        ZStack(alignment: .trailing) {
            if isOpen {
                // Dimmed Backdrop
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isOpen = false
                        }
                    }

                // Drawer Panel Content (Slides in from the RIGHT / .trailing)
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Gradient Header with User Info & Close Button
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            // User Avatar (52dp circle with 2dp border - 1:1 Android SideDrawer.kt lines 149-152)
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                    .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))

                                Image(systemName: "person.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                let activeEmail = !drive.userEmail.isEmpty ? drive.userEmail : (!mqtt.userEmail.isEmpty ? mqtt.userEmail : repo.userProfile.email)
                                Text(repo.userProfile.displayName.isEmpty ? (activeEmail.isEmpty ? "Misafir Kullanıcı" : activeEmail) : repo.userProfile.displayName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                Text(activeEmail.isEmpty ? "Giriş Yapılmadı" : activeEmail)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)

                                if !activeEmail.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color(hex: "#86EFAC"))
                                        Text("Google & MQTT Aktif")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(Color(hex: "#86EFAC"))
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            .padding(.leading, 4)

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isOpen = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.scaleSpring(scale: 0.88))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 48)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.primaryStart, AppTheme.primaryEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // MARK: - 7 Sections Menu Items (1:1 with Android SideDrawer.kt)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            // 1. HESAP & BULUT EŞİTLEME
                            sectionHeader("HESAP & BULUT EŞİTLEME")

                            let activeEmail = !drive.userEmail.isEmpty ? drive.userEmail : (!mqtt.userEmail.isEmpty ? mqtt.userEmail : repo.userProfile.email)

                            if activeEmail.isEmpty {
                                Button(action: {
                                    Haptics.light()
                                    showingGoogleSignIn = true
                                }) {
                                    HStack(spacing: 12) {
                                        GoogleGIconView(size: 20)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Google ile Bağlan")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(hex: "#8A4B1A"))

                                            Text("Drive yedekleme ve cihazlar arası anlık senkronizasyon")
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                                .lineLimit(1)
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.clear)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.scaleSpring(scale: 0.97))
                            }

                            drawerActionItem(icon: "arrow.triangle.2.circlepath", title: "Bulutla Eşitle", subtitle: "Google Drive ve cihazlar arası çift yönlü eşitleme") {
                                Haptics.light()
                                Task {
                                    await repo.syncWithCloud()
                                }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isOpen = false
                                }
                            }
                            drawerActionItem(icon: "icloud.and.arrow.down", title: "Buluttan İndir", subtitle: "Google Drive'daki ana kopyayı cihaza çeker") {
                                Haptics.light()
                                Task {
                                    if let remote = try? await drive.fetchMasterBackup() {
                                        await MainActor.run {
                                            for p in remote.projects {
                                                repo.mergeIncomingProject(p)
                                            }
                                        }
                                    } else {
                                        await repo.syncWithCloud()
                                    }
                                }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isOpen = false
                                }
                            }

                            if !activeEmail.isEmpty {
                                drawerActionItem(icon: "rectangle.portrait.and.arrow.right", title: "Güvenli Çıkış Yap", subtitle: "Hesap oturumunu kapat", isDestructive: true) {
                                    Haptics.medium()
                                    drive.signOut()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isOpen = false
                                    }
                                }
                            }

                            divider

                            // 2. PROJELER
                            sectionHeader("PROJELER")
                            drawerButton(icon: "folder", title: "Tüm Projeler (Dashboard)", badge: "\(repo.activeProjects.count)", id: "dashboard")
                            drawerPlaceholderItem(icon: "chart.bar.xaxis", title: "İstatistikler")
                            drawerPlaceholderItem(icon: "tag", title: "Etiketler")
                            drawerPlaceholderItem(icon: "square.grid.2x2", title: "Kategoriler")
                            drawerButton(icon: "archivebox", title: "Arşivdeki Projeler", badge: "\(repo.archivedProjects.count)", id: "archive")
                            drawerButton(icon: "trash", title: "Çöp Kutusu", badge: "\(repo.trashedProjects.count)", id: "trash")
                            drawerPlaceholderItem(icon: "qrcode.viewfinder", title: "QR Kod Tarayıcı")

                            divider

                            // 3. HATIRLATICILAR
                            sectionHeader("HATIRLATICILAR")
                            drawerPlaceholderItem(icon: "calendar", title: "Takvim")
                            drawerPlaceholderItem(icon: "clock", title: "Hatırlatıcılar")

                            divider

                            // 4. YÖNETİM
                            sectionHeader("YÖNETİM")
                            drawerButton(icon: "wrench.and.screwdriver", title: "Admin Paneli", id: "admin")

                            divider

                            // 5. AYARLAR
                            sectionHeader("AYARLAR")
                            drawerButton(icon: "gearshape", title: "Profil ve Ayarlar", id: "profile")
                            drawerActionItem(icon: "paintpalette", title: "Tema & Görünüm", subtitle: repo.isDarkMode ? "Karanlık Mod (Açık)" : "Aydınlık Mod (Açık)") {
                                Haptics.light()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    repo.isDarkMode.toggle()
                                }
                            }
                            drawerButton(icon: "externaldrive", title: "Veri Yönetimi", id: "profile")

                            divider

                            // 6. DESTEK
                            sectionHeader("DESTEK")
                            drawerPlaceholderItem(icon: "questionmark.circle", title: "Yardım Merkezi")
                            drawerPlaceholderItem(icon: "bubble.left.and.bubble.right", title: "Sık Sorulan Sorular")
                            drawerPlaceholderItem(icon: "envelope", title: "İletişim")
                            drawerPlaceholderItem(icon: "square.and.pencil", title: "Geri Bildirim")

                            divider

                            // 7. HAKKINDA
                            sectionHeader("HAKKINDA")
                            drawerPlaceholderItem(icon: "info.circle", title: "Hakkımızda")
                            drawerPlaceholderItem(icon: "shield", title: "Gizlilik Politikası")
                            drawerPlaceholderItem(icon: "doc.text", title: "Kullanım Koşulları")
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                    }

                    Spacer()

                    // MARK: - Footer with Reset Button & Version Info
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            Haptics.heavy()
                            repo.resetAllData()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isOpen = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.slash.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#EF4444"))
                                Text("Her Şeyi Sıfırla")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(hex: "#EF4444"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#EF4444").opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#EF4444").opacity(0.25), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(.scaleSpring(scale: 0.96))

                        Text("Versiyon 4.5.0 - Inline UI & DnD")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                    .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color(hex: "#FAF8F5"))
                    .overlay(Rectangle().frame(height: 1).foregroundColor(AppTheme.borderSubtle(isDark: repo.isDarkMode)), alignment: .top)
                }
                .frame(width: 310)
                .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color.white)
                .ignoresSafeArea()
                .transition(.move(edge: .trailing))
            }

            // MARK: - Coming Soon Modal Overlay
            if let feature = comingSoonFeature {
                ComingSoonModal(
                    featureName: feature,
                    isDarkMode: repo.isDarkMode,
                    onDismiss: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            comingSoonFeature = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showingGoogleSignIn) {
            GoogleSignInModal()
        }
    }

    // Section Header (Matching DrawerSectionHeader in Android)
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#78716C"))
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    // Divider (Matching DrawerDivider in Android)
    private var divider: some View {
        Rectangle()
            .fill(repo.isDarkMode ? Color.white.opacity(0.08) : Color(hex: "#E2DDD5"))
            .frame(height: 1)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
    }

    // Navigation Button (Dashboard, Archive, Trash, Profile, Admin)
    private func drawerButton(icon: String, title: String, badge: String? = nil, id: String) -> some View {
        Button(action: {
            Haptics.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isOpen = false
            }
            if id != "dashboard" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onSelectView(id)
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

                Spacer()

                if let b = badge, !b.isEmpty, b != "0" {
                    Text(b)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(repo.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.scaleSpring(scale: 0.97))
    }

    // Placeholder Button (Triggers ComingSoonModal)
    private func drawerPlaceholderItem(icon: String, title: String) -> some View {
        Button(action: {
            Haptics.light()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                comingSoonFeature = title
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.scaleSpring(scale: 0.97))
    }

    // Action Item (Sync, Cloud Pull, Theme Toggle, Sign Out)
    private func drawerActionItem(icon: String, title: String, subtitle: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isDestructive ? Color(hex: "#EF4444") : AppTheme.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDestructive ? Color(hex: "#EF4444") : AppTheme.textBody(isDark: repo.isDarkMode))

                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundColor(isDestructive ? Color(hex: "#EF4444").opacity(0.8) : AppTheme.textMuted(isDark: repo.isDarkMode))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, subtitle != nil ? 8 : 10)
            .background(Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.scaleSpring(scale: 0.97))
    }
}

/// 1:1 Official Google G Multi-Color Emblem Vector
/// Corresponds to the official SVG in index.html (line 18932).
public struct GoogleGIconView: View {
    public var size: CGFloat = 20

    public init(size: CGFloat = 20) {
        self.size = size
    }

    public var body: some View {
        Canvas { context, sz in
            let s = sz.width / 48.0

            var redPath = Path()
            redPath.move(to: CGPoint(x: 24.0 * s, y: 9.5 * s))
            redPath.addCurve(to: CGPoint(x: (24.0 + 9.21) * s, y: (9.5 + 3.6) * s), control1: CGPoint(x: (24.0 + 3.54) * s, y: (9.5 + 0.0) * s), control2: CGPoint(x: (24.0 + 6.71) * s, y: (9.5 + 1.22) * s))
            redPath.addLine(to: CGPoint(x: 40.06 * s, y: 6.25 * s))
            redPath.addCurve(to: CGPoint(x: 24.0 * s, y: 0.0 * s), control1: CGPoint(x: 35.9 * s, y: 2.38 * s), control2: CGPoint(x: 30.47 * s, y: 0.0 * s))
            redPath.addCurve(to: CGPoint(x: 2.56 * s, y: 13.22 * s), control1: CGPoint(x: 14.62 * s, y: 0.0 * s), control2: CGPoint(x: 6.51 * s, y: 5.38 * s))
            redPath.addLine(to: CGPoint(x: 10.54 * s, y: 19.41 * s))
            redPath.addCurve(to: CGPoint(x: 24.0 * s, y: 9.5 * s), control1: CGPoint(x: 12.43 * s, y: 13.72 * s), control2: CGPoint(x: 17.74 * s, y: 9.5 * s))
            redPath.closeSubpath()
            context.fill(redPath, with: .color(Color(hex: "#EA4335")))

            var bluePath = Path()
            bluePath.move(to: CGPoint(x: 46.98 * s, y: 24.55 * s))
            bluePath.addCurve(to: CGPoint(x: (46.98 - 0.38) * s, y: (24.55 - 4.55) * s), control1: CGPoint(x: 46.98 * s, y: (24.55 - 1.57) * s), control2: CGPoint(x: (46.98 - 0.15) * s, y: (24.55 - 3.09) * s))
            bluePath.addLine(to: CGPoint(x: 24.0 * s, y: 20.0 * s))
            bluePath.addLine(to: CGPoint(x: 24.0 * s, y: 29.02 * s))
            bluePath.addLine(to: CGPoint(x: 36.94 * s, y: 29.02 * s))
            bluePath.addCurve(to: CGPoint(x: (36.94 - 4.78) * s, y: (29.02 + 7.18) * s), control1: CGPoint(x: (36.94 - 0.58) * s, y: (29.02 + 2.96) * s), control2: CGPoint(x: (36.94 - 2.26) * s, y: (29.02 + 5.48) * s))
            bluePath.addLine(to: CGPoint(x: 39.89 * s, y: 42.2 * s))
            bluePath.addCurve(to: CGPoint(x: (39.89 + 7.09) * s, y: (42.2 - 17.65) * s), control1: CGPoint(x: (39.89 + 4.51) * s, y: (42.2 - 4.18) * s), control2: CGPoint(x: (39.89 + 7.09) * s, y: (42.2 - 10.36) * s))
            bluePath.closeSubpath()
            context.fill(bluePath, with: .color(Color(hex: "#4285F4")))

            var yellowPath = Path()
            yellowPath.move(to: CGPoint(x: 10.53 * s, y: 28.59 * s))
            yellowPath.addCurve(to: CGPoint(x: (10.53 - 0.76) * s, y: (28.59 - 4.59) * s), control1: CGPoint(x: (10.53 - 0.48) * s, y: (28.59 - 1.45) * s), control2: CGPoint(x: (10.53 - 0.76) * s, y: (28.59 - 2.99) * s))
            yellowPath.addCurve(to: CGPoint(x: 10.53 * s, y: 19.41 * s), control1: CGPoint(x: 9.77 * s, y: 24.0 * s), control2: CGPoint(x: 10.04 * s, y: 20.86 * s))
            yellowPath.addLine(to: CGPoint(x: 2.55 * s, y: 13.22 * s))
            yellowPath.addCurve(to: CGPoint(x: 0.0 * s, y: 24.0 * s), control1: CGPoint(x: 0.92 * s, y: 16.46 * s), control2: CGPoint(x: 0.0 * s, y: 20.12 * s))
            yellowPath.addCurve(to: CGPoint(x: 2.56 * s, y: 34.78 * s), control1: CGPoint(x: 0.0 * s, y: 27.88 * s), control2: CGPoint(x: 0.92 * s, y: 31.54 * s))
            yellowPath.addLine(to: CGPoint(x: 10.53 * s, y: 28.59 * s))
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(Color(hex: "#FBBC05")))

            var greenPath = Path()
            greenPath.move(to: CGPoint(x: 24.0 * s, y: 48.0 * s))
            greenPath.addCurve(to: CGPoint(x: (24.0 + 15.89) * s, y: (48.0 - 5.81) * s), control1: CGPoint(x: (24.0 + 6.48) * s, y: 48.0 * s), control2: CGPoint(x: (24.0 + 11.93) * s, y: (48.0 - 2.13) * s))
            greenPath.addLine(to: CGPoint(x: 32.16 * s, y: 36.19 * s))
            greenPath.addCurve(to: CGPoint(x: (32.16 - 8.16) * s, y: (36.19 + 2.3) * s), control1: CGPoint(x: (32.16 - 2.15) * s, y: (36.19 + 1.45) * s), control2: CGPoint(x: (32.16 - 4.92) * s, y: (36.19 + 2.3) * s))
            greenPath.addCurve(to: CGPoint(x: (24.0 - 13.47) * s, y: (38.49 - 9.91) * s), control1: CGPoint(x: (24.0 - 6.26) * s, y: 38.49 * s), control2: CGPoint(x: (24.0 - 11.57) * s, y: (38.49 - 4.22) * s))
            greenPath.addLine(to: CGPoint(x: 2.55 * s, y: 34.77 * s))
            greenPath.addCurve(to: CGPoint(x: 24.0 * s, y: 48.0 * s), control1: CGPoint(x: 6.51 * s, y: 42.62 * s), control2: CGPoint(x: 14.62 * s, y: 48.0 * s))
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(Color(hex: "#34A853")))
        }
        .frame(width: size, height: size)
    }
}
