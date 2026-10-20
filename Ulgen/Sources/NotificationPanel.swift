import SwiftUI

public struct NotificationPanel: View {
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode)
                    .ignoresSafeArea()

                if repo.notifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        Text("Bildirim Yok")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                        Text("Sistem olayları ve senkronizasyon uyarıları burada görünür.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(repo.notifications) { notif in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: notif.type == "warning" ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                        .foregroundColor(notif.type == "warning" ? Color(hex: "#F59E0B") : AppTheme.primary)
                                        .font(.system(size: 18))
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(notif.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                        Text(notif.message)
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                        Text(Date(timeIntervalSince1970: Double(notif.timestamp) / 1000).formatted())
                                            .font(.system(size: 10))
                                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                    }

                                    Spacer()
                                }
                                .padding(12)
                                .neumorphicCard(isDark: repo.isDarkMode)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Temizle") {
                        repo.notifications.removeAll()
                        repo.saveLocalData()
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}
