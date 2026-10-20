import SwiftUI

public struct SideDrawer: View {
    @Binding var isOpen: Bool
    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var mqtt = MqttSyncEngine.shared
    @State private var comingSoonFeature: String? = nil

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
                            // User Avatar
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Y Alperen Karakaya")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                Text(mqtt.userEmail.isEmpty ? "yalpkarakaya@gmail.com" : mqtt.userEmail)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
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

                        // MQTT / Sync Status Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(mqtt.isConnected ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))
                                .frame(width: 8, height: 8)
                            Text(mqtt.isConnected ? "HiveMQ Çevrimiçi (Galaxy S25+ Senkron)" : "Yerel Mod (Çevrimdışı)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(20)
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
                            drawerActionItem(icon: "arrow.triangle.2.circlepath", title: "Bulutla Eşitle", subtitle: "Cihazlar arası anlık senkronizasyon") {
                                Haptics.light()
                                mqtt.requestInitialSync()
                            }
                            drawerActionItem(icon: "icloud.and.arrow.down", title: "Buluttan İndir", subtitle: "Sunucudaki ana kopyayı cihaza çeker") {
                                Haptics.light()
                                mqtt.requestInitialSync()
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
                    .padding(14)
                    .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color(hex: "#FAF8F5"))
                    .overlay(Rectangle().frame(height: 1).foregroundColor(AppTheme.borderSubtle(isDark: repo.isDarkMode)), alignment: .top)
                }
                .frame(width: 310)
                .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color.white)
                .ignoresSafeArea(edges: .vertical)
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

    // Action Item (Sync, Cloud Pull, Theme Toggle)
    private func drawerActionItem(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))

                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
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
