import SwiftUI

public struct AdminView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Diagnostics Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SİSTEM METRİKLERİ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            diagRow("Toplam Proje Kaydı", "\(repo.projects.count)")
                            diagRow("Aktif Projeler", "\(repo.activeProjects.count)")
                            diagRow("Arşivlenmiş Projeler", "\(repo.archivedProjects.count)")
                            diagRow("Çöp Kutusundaki Projeler", "\(repo.trashedProjects.count)")
                            diagRow("Tombstone (Mezarlık) Kimlikleri", "\(repo.deletedProjectIds.count)")
                        }
                        .padding(16)
                        .neumorphicCard(isDark: repo.isDarkMode)

                        // Data Actions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("VERİTABANI BAKIMI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                            Button(action: {
                                repo.saveLocalData()
                                Haptics.success()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Diske Zorla Yaz (Force Flush)")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppTheme.primary.opacity(0.12))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.scaleSpring(scale: 0.96))

                            Button(action: {
                                repo.deletedProjectIds.removeAll()
                                repo.saveLocalData()
                                Haptics.heavy()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.bin")
                                    Text("Tombstone Mezarlık Kayıtlarını Temizle")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#EF4444"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#EF4444").opacity(0.12))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.scaleSpring(scale: 0.96))
                        }
                        .padding(16)
                        .neumorphicCard(isDark: repo.isDarkMode)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Sistem ve Admin Konsolu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                        .buttonStyle(.scaleSpring(scale: 0.92))
                }
            }
        }
    }

    private func diagRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.primary)
        }
    }
}
