import SwiftUI

public struct SideDrawer: View {
    @Binding var isOpen: Bool
    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var mqtt = MqttSyncEngine.shared

    var onSelectView: (String) -> Void

    public var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                // Dimmed Backdrop
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isOpen = false
                        }
                    }

                // Drawer Content
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Ülgen")
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(AppTheme.primary)

                            Spacer()

                            Button(action: {
                                withAnimation { isOpen = false }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                    .frame(width: 32, height: 32)
                                    .background(AppTheme.card(isDark: repo.isDarkMode))
                                    .clipShape(Circle())
                            }
                        }

                        Text("Donanım & Mühendislik Proje Takip Sistemi")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                        // Device Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(mqtt.isConnected ? Color(hex: "#10B981") : Color(hex: "#EF4444"))
                                .frame(width: 8, height: 8)
                            Text(mqtt.isConnected ? "MQTT Çevrimiçi (Galaxy S25+ Senkron)" : "Yerel Mod")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(AppTheme.card(isDark: repo.isDarkMode))

                    Divider().background(AppTheme.border(isDark: repo.isDarkMode))

                    // Menu Items
                    ScrollView {
                        VStack(spacing: 6) {
                            drawerButton(icon: "folder.fill", title: "Projelerim", badge: "\(repo.activeProjects.count)", id: "dashboard")
                            drawerButton(icon: "archivebox.fill", title: "Arşivlenmiş Projeler", badge: "\(repo.archivedProjects.count)", id: "archive")
                            drawerButton(icon: "trash.fill", title: "Çöp Kutusu", badge: "\(repo.trashedProjects.count)", id: "trash")
                            drawerButton(icon: "person.crop.circle", title: "Profil & Senkronizasyon", id: "profile")
                            drawerButton(icon: "wrench.and.screwdriver.fill", title: "Admin & Sistem Konsolu", id: "admin")
                        }
                        .padding(14)
                    }

                    Spacer()

                    // Footer Version & Diagnostics
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ülgen iOS Native v1.2.0")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                        Text("İzole HiveMQ ve SideStore Otomasyonu")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card(isDark: repo.isDarkMode))
                }
                .frame(width: 300)
                .background(AppTheme.bg(isDark: repo.isDarkMode))
                .ignoresSafeArea(edges: .vertical)
                .transition(.move(edge: .leading))
            }
        }
    }

    private func drawerButton(icon: String, title: String, badge: String? = nil, id: String) -> some View {
        Button(action: {
            Haptics.light()
            withAnimation { isOpen = false }
            onSelectView(id)
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(repo.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(AppTheme.card(isDark: repo.isDarkMode))
            .cornerRadius(10)
        }
    }
}
