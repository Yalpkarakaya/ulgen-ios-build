import SwiftUI

/// 1:1 Parity Implementation of Android `com.ulgen.takip.ui.screens.backup.BackupModal.kt`.
/// Provides complete manual & automated snapshot backup management, Google Drive `Yedekler/`
/// visible subfolder browser, instant snapshot creation, and authoritative project restoration.
public struct BackupModal: View {
    public var project: Project
    public var onDismiss: () -> Void = {}
    public var onProjectRestored: (Project) -> Void = { _ in }

    @ObservedObject var repo = ProjectRepository.shared
    @ObservedObject var drive = GoogleDriveSyncEngine.shared
    @State private var activeTab: String = "manual" // "manual", "auto", "drive"
    @State private var manualBackups: [ProjectBackup] = []
    @State private var autoBackups: [ProjectBackup] = []
    @State private var driveBackups: [GoogleDriveSyncEngine.DriveFileItem] = []
    @State private var isLoadingDrive: Bool = false
    @State private var restoreConfirmBackup: ProjectBackup? = nil
    @State private var isCreatingBackup: Bool = false
    @State private var driveFolderId: String? = nil

    private var currentStats: BackupStats {
        ProjectBackupManager.countProjectTasks(project)
    }

    public init(
        project: Project,
        onDismiss: @escaping () -> Void = {},
        onProjectRestored: @escaping (Project) -> Void = { _ in }
    ) {
        self.project = project
        self.onDismiss = onDismiss
        self.onProjectRestored = onProjectRestored
    }

    public var body: some View {
        ZStack {
            // Dark Backdrop Scrim
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Centered Modal Dialog Card (1:1 Android BackupModal)
            VStack(alignment: .leading, spacing: 14) {
                // Header Row
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#D97706"))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Yedekleme & Geçmiş")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))

                        Text(project.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            .lineLimit(1)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                            .frame(width: 28, height: 28)
                            .background(repo.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.scaleSpring(scale: 0.90))
                }

                // Project Stats Capsule Strip
                HStack(spacing: 8) {
                    statPill(label: "Başlık", value: "\(currentStats.topics)")
                    statPill(label: "Alt Başlık", value: "\(currentStats.subs)")
                    statPill(label: "Görev", value: "\(currentStats.completedItems)/\(currentStats.items)")
                    statPill(label: "Medya", value: "\(currentStats.media)")
                    statPill(label: "İlerleme", value: "%\(currentStats.progress)")
                }
                .padding(8)
                .background(repo.isDarkMode ? Color(hex: "#26221E") : Color(hex: "#FAF8F5"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(repo.isDarkMode ? Color(hex: "#3D3832") : Color(hex: "#E5E1D8"), lineWidth: 1)
                )

                // 3-Segment Tab Bar (Manuel / Otomatik / Google Drive)
                HStack(spacing: 0) {
                    tabButton(id: "manual", title: "Manuel (\(manualBackups.count))")
                    tabButton(id: "auto", title: "Otomatik (\(autoBackups.count))")
                    tabButton(id: "drive", title: "Google Drive")
                }
                .padding(3)
                .background(repo.isDarkMode ? Color(hex: "#262320") : Color(hex: "#EFECE6"))
                .cornerRadius(10)

                // Tab Content List
                Group {
                    if activeTab == "drive" {
                        driveBackupsList
                    } else if activeTab == "auto" {
                        backupsList(backups: autoBackups, pool: "auto")
                    } else {
                        backupsList(backups: manualBackups, pool: "manual")
                    }
                }
                .frame(height: 220)

                // Bottom Action Buttons
                VStack(spacing: 8) {
                    Button(action: createNewBackup) {
                        HStack(spacing: 6) {
                            if isCreatingBackup {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text("Yeni Manuel Yedek Al")
                        }
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color(hex: "#D97706"))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.scaleSpring(scale: 0.96))
                    .disabled(isCreatingBackup)

                    HStack(spacing: 8) {
                        if drive.isAuthorized {
                            Button(action: openDriveFolder) {
                                HStack(spacing: 5) {
                                    Image(systemName: "folder")
                                    Text("Drive Klasörünü Aç")
                                }
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(Color(hex: "#3B82F6"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(Color(hex: "#3B82F6").opacity(0.12))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.scaleSpring(scale: 0.96))
                        }

                        Button(action: onDismiss) {
                            Text("Kapat")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(repo.isDarkMode ? Color(hex: "#292524") : Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#D6D1C7"), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.scaleSpring(scale: 0.96))
                    }
                }
            }
            .padding(18)
            .background(repo.isDarkMode ? Color(hex: "#1E1B18") : Color(hex: "#FFFFFF"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(repo.isDarkMode ? Color(hex: "#44403C") : Color(hex: "#E2DDD5"), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 16)
        }
        .onAppear {
            reloadBackups()
        }
        .alert(item: $restoreConfirmBackup) { bk in
            Alert(
                title: Text("Yedekten Geri Yükle"),
                message: Text("Bu işlem mevcut proje içeriğini '\(bk.reason)' anındaki verilerle değiştirecektir. Devam etmek istiyor musunuz?"),
                primaryButton: .destructive(Text("Geri Yükle")) {
                    Haptics.heavy()
                    var restored = bk.data
                    restored.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
                    repo.updateProject(restored)
                    onProjectRestored(restored)
                    onDismiss()
                },
                secondaryButton: .cancel(Text("İptal"))
            )
        }
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
            Text(label)
                .font(.system(size: 9.5))
                .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
        }
        .frame(maxWidth: .infinity)
    }

    private func tabButton(id: String, title: String) -> some View {
        Button(action: {
            Haptics.light()
            activeTab = id
            if id == "drive" {
                loadDriveBackups()
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: activeTab == id ? .bold : .medium))
                .foregroundColor(activeTab == id ? .white : (repo.isDarkMode ? Color(hex: "#A8A29E") : Color(hex: "#57534E")))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(activeTab == id ? Color(hex: "#D97706") : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(.scaleSpring(scale: 0.96))
    }

    private func backupsList(backups: [ProjectBackup], pool: String) -> some View {
        ScrollView {
            if backups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    Text("Bu kategoride henüz kayıtlı yedek bulunmuyor.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(backups) { bk in
                        backupCard(bk, pool: pool)
                    }
                }
            }
        }
    }

    private func backupCard(_ bk: ProjectBackup, pool: String) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bk.reason)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    .lineLimit(1)

                Text(formatIsoDate(bk.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))

                HStack(spacing: 6) {
                    Text("\(bk.stats.completedItems)/\(bk.stats.items) Görev")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#10B981"))
                    Text("%\(bk.stats.progress)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#D97706"))
                }
            }

            Spacer()

            // Restore Button
            Button(action: {
                Haptics.medium()
                restoreConfirmBackup = bk
            }) {
                Text("Geri Yükle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#10B981"))
                    .cornerRadius(6)
            }
            .buttonStyle(.scaleSpring(scale: 0.92))

            // Delete Button
            Button(action: {
                Haptics.light()
                ProjectBackupManager.shared.deleteProjectBackup(projectId: project.id, backupId: bk.id, pool: pool)
                reloadBackups()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .frame(width: 26, height: 26)
                    .background(Color(hex: "#EF4444").opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.scaleSpring(scale: 0.88))
        }
        .padding(10)
        .background(repo.isDarkMode ? Color(hex: "#26221E") : Color(hex: "#FAF8F5"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(repo.isDarkMode ? Color(hex: "#3D3832") : Color(hex: "#E5E1D8"), lineWidth: 1)
        )
    }

    private var driveBackupsList: some View {
        ScrollView {
            if !drive.isAuthorized {
                VStack(spacing: 8) {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    Text("Google Drive oturumu açık değil.")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                    Text("Yan menüden Google ile bağlanarak Drive klasöründeki yedekleri görüntüleyebilirsiniz.")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else if isLoadingDrive {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Drive klasörü taranıyor...")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else if driveBackups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                    Text("Drive 'Yedekler/' klasöründe henüz snapshot bulunmuyor.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(driveBackups) { file in
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#3B82F6"))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.textHeading(isDark: repo.isDarkMode))
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    if let size = file.size, let szInt = Int64(size) {
                                        Text("\(szInt / 1024) KB")
                                            .font(.system(size: 10))
                                            .foregroundColor(AppTheme.textMuted(isDark: repo.isDarkMode))
                                    }
                                    Text("Google Drive")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(hex: "#10B981"))
                                }
                            }

                            Spacer()

                            Button(action: {
                                downloadAndRestoreDriveBackup(file: file)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.circle")
                                    Text("İndir & Geri Yükle")
                                }
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#3B82F6"))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.scaleSpring(scale: 0.92))
                        }
                        .padding(10)
                        .background(repo.isDarkMode ? Color(hex: "#26221E") : Color(hex: "#FAF8F5"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(repo.isDarkMode ? Color(hex: "#3D3832") : Color(hex: "#E5E1D8"), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func reloadBackups() {
        manualBackups = ProjectBackupManager.shared.getProjectBackups(projectId: project.id, pool: "manual")
        autoBackups = ProjectBackupManager.shared.getProjectBackups(projectId: project.id, pool: "auto")
    }

    private func loadDriveBackups() {
        guard drive.isAuthorized else { return }
        isLoadingDrive = true
        Task {
            let files = (try? await drive.listProjectBackups(projectId: project.id, projectTitle: project.title)) ?? []
            let fId = try? await drive.ensureProjectBackupsFolder(projectId: project.id, projectTitle: project.title)
            await MainActor.run {
                self.driveBackups = files
                self.driveFolderId = fId
                self.isLoadingDrive = false
            }
        }
    }

    private func createNewBackup() {
        isCreatingBackup = true
        Haptics.light()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let reason = "Manuel Kullanıcı Yedeği (\(formatter.string(from: Date())))"

        _ = ProjectBackupManager.shared.createProjectBackup(
            project: project,
            reason: reason,
            pool: "manual",
            force: true
        )

        reloadBackups()
        if activeTab == "drive" {
            loadDriveBackups()
        }
        isCreatingBackup = false
        Haptics.success()
    }

    private func downloadAndRestoreDriveBackup(file: GoogleDriveSyncEngine.DriveFileItem) {
        Task {
            if let data = try? await drive.downloadMediaBinaryFromDrive(driveFileId: file.id),
               let restored = try? JSONDecoder().decode(Project.self, from: data) {
                await MainActor.run {
                    Haptics.heavy()
                    var updated = restored
                    updated.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
                    repo.updateProject(updated)
                    onProjectRestored(updated)
                    onDismiss()
                }
            }
        }
    }

    private func openDriveFolder() {
        let fId = driveFolderId ?? ""
        let urlStr = fId.isEmpty ? "https://drive.google.com" : "https://drive.google.com/drive/folders/\(fId)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    private func formatIsoDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let d = formatter.date(from: iso) {
            let out = DateFormatter()
            out.locale = Locale(identifier: "tr_TR")
            out.dateFormat = "dd.MM.yyyy HH:mm"
            return out.string(from: d)
        }
        return iso
    }
}
