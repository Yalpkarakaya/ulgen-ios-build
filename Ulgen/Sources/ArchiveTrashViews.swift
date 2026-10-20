import SwiftUI

// MARK: - Archive View
public struct ArchiveView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()

                if repo.archivedProjects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 44))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        Text("Arşivlenmiş Proje Yok")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(repo.archivedProjects) { project in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(project.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                        Spacer()
                                        Button("Geri Yükle") {
                                            repo.toggleArchive(id: project.id)
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.primary)
                                    }
                                    Text(project.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                        .lineLimit(2)
                                }
                                .padding(14)
                                .neumorphicCard(isDark: repo.isDarkMode)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Arşiv")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Trash View
public struct TrashView: View {
    @ObservedObject var repo = ProjectRepository.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmEmpty = false

    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg(isDark: repo.isDarkMode).ignoresSafeArea()

                if repo.trashedProjects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 44))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        Text("Çöp Kutusu Boş")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(repo.trashedProjects) { project in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(project.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                        Spacer()
                                        Button("Kurtar") {
                                            repo.restoreProject(id: project.id)
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.primary)

                                        Button("Yok Et") {
                                            repo.permanentDeleteProject(id: project.id)
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#EF4444"))
                                        .padding(.leading, 8)
                                    }
                                    Text(project.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.textBody(isDark: repo.isDarkMode))
                                        .lineLimit(2)
                                }
                                .padding(14)
                                .neumorphicCard(isDark: repo.isDarkMode)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Çöp Kutusu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .destructiveAction) {
                    if !repo.trashedProjects.isEmpty {
                        Button("Boşalt") {
                            showConfirmEmpty = true
                        }
                        .foregroundColor(Color(hex: "#EF4444"))
                    }
                }
            }
            .alert("Çöp Kutusunu Boşalt", isPresented: $showConfirmEmpty) {
                Button("İptal", role: .cancel) { }
                Button("Tümünü Sil", role: .destructive) {
                    for p in repo.trashedProjects {
                        repo.permanentDeleteProject(id: p.id)
                    }
                }
            } message: {
                Text("Çöp kutusundaki tüm projeler kalıcı olarak silinecektir. Bu işlem geri alınamaz.")
            }
        }
    }
}
