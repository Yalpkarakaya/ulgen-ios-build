import Foundation

/// 1:1 Parity Implementation of Android `com.ulgen.takip.data.local.ProjectBackupManager.kt`.
/// Manages automated & manual project snapshot history, 90-second debounce coalescing,
/// time-clustering reduction, and background Google Drive visible folder backups.
public class ProjectBackupManager {
    public static let shared = ProjectBackupManager()

    public static let backupMaxAuto = 25
    public static let backupMaxManual = 20
    public static let backupCoalesceWindowMs: Int64 = 90 * 1000 // 90 seconds

    private let backupsDir: URL
    private let queue = DispatchQueue(label: "com.ulgen.projectbackups", qos: .utility)
    private var lastAutoBackupTimes: [String: Int64] = [:]
    private var lastAutoBackupStats: [String: BackupStats] = [:]

    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.backupsDir = docs.appendingPathComponent("project_backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)
    }

    private func getBackupFileURL(projectId: String, pool: String) -> URL {
        return backupsDir.appendingPathComponent("takip_backups_\(pool)_\(projectId).json")
    }

    public static func countProjectTasks(_ project: Project) -> BackupStats {
        var topics = project.mainTopics.count
        var completedTopics = 0
        var subs = 0
        var completedSubs = 0
        var items = 0
        var completedItems = 0
        var notesCount = project.notes.count

        for topic in project.mainTopics {
            subs += topic.subTopics.count
            var topicAllDone = true
            for sub in topic.subTopics {
                items += sub.items.count
                var subAllDone = true
                for item in sub.items {
                    if item.completed {
                        completedItems += 1
                    } else {
                        subAllDone = false
                    }
                }
                if sub.items.isEmpty { subAllDone = false }
                if subAllDone { completedSubs += 1 }
                if !subAllDone { topicAllDone = false }
            }
            if topic.subTopics.isEmpty { topicAllDone = false }
            if topicAllDone { completedTopics += 1 }
        }

        let media = project.media.count
        let cloudMedia = project.media.filter { !($0.driveFileId ?? "").isEmpty }.count
        let aiChats = project.chatSessions.count
        let progress = project.progress
        let total = topics + subs + items + media + notesCount + aiChats

        return BackupStats(
            topics: topics,
            completedTopics: completedTopics,
            subs: subs,
            completedSubs: completedSubs,
            items: items,
            completedItems: completedItems,
            notes: notesCount,
            links: 0,
            media: media,
            cloudMedia: cloudMedia,
            localMedia: media,
            aiChats: aiChats,
            progress: progress,
            total: total
        )
    }

    public static func hasStructuralDifference(_ statsA: BackupStats?, _ statsB: BackupStats?) -> Bool {
        guard let a = statsA, let b = statsB else { return true }
        return a.topics != b.topics ||
            a.completedTopics != b.completedTopics ||
            a.subs != b.subs ||
            a.completedSubs != b.completedSubs ||
            a.items != b.items ||
            a.completedItems != b.completedItems ||
            a.notes != b.notes ||
            a.media != b.media ||
            a.cloudMedia != b.cloudMedia ||
            a.aiChats != b.aiChats ||
            a.progress != b.progress
    }

    public func getProjectBackups(projectId: String, pool: String = "manual") -> [ProjectBackup] {
        let url = getBackupFileURL(projectId: projectId, pool: pool)
        guard let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([ProjectBackup].self, from: data) else {
            return []
        }
        return list.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    public func createProjectBackup(
        project: Project,
        reason: String,
        pool: String = "manual",
        force: Bool = false
    ) -> ProjectBackup? {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let stats = Self.countProjectTasks(project)

        // Auto backup coalescing check
        if pool == "auto" && !force {
            if let lastTime = lastAutoBackupTimes[project.id],
               (now - lastTime) < Self.backupCoalesceWindowMs,
               let lastStats = lastAutoBackupStats[project.id],
               !Self.hasStructuralDifference(lastStats, stats) {
                return nil
            }
        }

        let isoDate = ISO8601DateFormatter().string(from: Date())
        let backup = ProjectBackup(
            createdAt: isoDate,
            reason: reason,
            title: project.title,
            type: pool,
            stats: stats,
            data: project,
            pool: pool
        )

        var currentList = getProjectBackups(projectId: project.id, pool: pool)
        currentList.insert(backup, at: 0)

        // Time-Clustering Reduction
        let maxCount = (pool == "auto") ? Self.backupMaxAuto : Self.backupMaxManual
        reduceByTimeClustering(backups: &currentList, maxCount: maxCount)

        // Save local JSON file
        let url = getBackupFileURL(projectId: project.id, pool: pool)
        if let data = try? JSONEncoder().encode(currentList) {
            try? data.write(to: url)
        }

        if pool == "auto" {
            lastAutoBackupTimes[project.id] = now
            lastAutoBackupStats[project.id] = stats
        }

        // Upload snapshot to Google Drive `Ülgen Takip / <Proje Başlığı> / Yedekler/`
        if GoogleDriveSyncEngine.shared.isAuthorized {
            Task {
                _ = try? await GoogleDriveSyncEngine.shared.uploadProjectBackupSnapshotToDrive(
                    project: project,
                    reason: reason,
                    pool: pool
                )
            }
        }

        return backup
    }

    public func deleteProjectBackup(projectId: String, backupId: String, pool: String = "manual") {
        var currentList = getProjectBackups(projectId: projectId, pool: pool)
        currentList.removeAll { $0.id == backupId }

        let url = getBackupFileURL(projectId: projectId, pool: pool)
        if let data = try? JSONEncoder().encode(currentList) {
            try? data.write(to: url)
        }
    }

    public func exportProjectToJson(_ project: Project) -> String {
        let envelope = ExportedProjectBackup(
            project: project,
            stats: Self.countProjectTasks(project),
            backupHistory: getProjectBackups(projectId: project.id, pool: "manual")
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(envelope),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    private func reduceByTimeClustering(backups: inout [ProjectBackup], maxCount: Int) {
        while backups.count > maxCount {
            if backups.count <= 2 {
                backups.removeLast()
                break
            }
            var minGap: Double = .greatestFiniteMagnitude
            var minGapIdx = -1
            let isoFormatter = ISO8601DateFormatter()

            for i in 0..<(backups.count - 1) {
                let timeA = isoFormatter.date(from: backups[i].createdAt)?.timeIntervalSince1970 ?? 0
                let timeB = isoFormatter.date(from: backups[i + 1].createdAt)?.timeIntervalSince1970 ?? 0
                let gap = abs(timeA - timeB)
                if gap < minGap {
                    minGap = gap
                    minGapIdx = i
                }
            }

            if minGapIdx == -1 {
                backups.removeLast()
                continue
            }

            let candidateA = backups[minGapIdx]
            let candidateB = backups[minGapIdx + 1]
            if candidateA.stats.total < candidateB.stats.total {
                backups.remove(at: minGapIdx)
            } else {
                backups.remove(at: minGapIdx + 1)
            }
        }
    }
}
