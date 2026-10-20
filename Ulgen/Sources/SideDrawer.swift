import SwiftUI

public struct SideDrawer: View {
    @Binding var isOpen: Bool
    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var mqtt = MqttSyncEngine.shared

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

                    // MARK: - Menu Items
                    ScrollView {
                        VStack(spacing: 4) {
                            drawerButton(icon: "folder", title: "Projelerim", badge: "\(repo.activeProjects.count)", id: "dashboard")
                            drawerButton(icon: "archivebox", title: "Arşivlenmiş Projeler", badge: "\(repo.archivedProjects.count)", id: "archive")
                            drawerButton(icon: "trash", title: "Çöp Kutusu", badge: "\(repo.trashedProjects.count)", id: "trash")
                            drawerButton(icon: "person.crop.circle", title: "Profil & Hesap Eşleme", id: "profile")
                            drawerButton(icon: "wrench.and.screwdriver", title: "Admin & API Havuzu", id: "admin")
                        }
                        .padding(14)
                    }

                    Spacer()

                    // MARK: - Footer
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ülgen iOS Native v1.2.2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                        Text("Donanım & Mühendislik Proje Takip Sistemi")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(repo.isDarkMode ? AppTheme.cardSurfaceDark : AppTheme.bgLight)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(AppTheme.borderSubtle(isDark: repo.isDarkMode)), alignment: .top)
                }
                .frame(width: 310)
                .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color.white)
                .ignoresSafeArea(edges: .vertical)
                .transition(.move(edge: .trailing))
            }
        }
    }

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
            .padding(.vertical, 11)
            .background(Color.clear)
            .cornerRadius(10)
        }
    }
}
