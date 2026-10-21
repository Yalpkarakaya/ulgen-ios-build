import Foundation
import Combine
import SwiftUI

// MARK: - ProjectRepository (1:1 with ProjectRepository.kt)
public class ProjectRepository: ObservableObject {
    public static let shared = ProjectRepository()

    @Published public var projects: [Project] = []
    @Published public var deletedProjectIds: [DeletedItemRecord] = []
    @Published public var notifications: [AppNotification] = []
    @Published public var apiKeys: ApiKeysConfig = ApiKeysConfig()
    @Published public var userProfile: UserProfile = UserProfile()
    @Published public var isDarkMode: Bool = false
    @Published public var selectedCategory: String = "all"
    @Published public var selectedPriority: String = "all"
    @Published public var searchQuery: String = ""
    @Published public var sortOption: String = "custom"
    @Published public var isSyncing: Bool = false

    private let fileURL: URL
    private let deletedFileURL: URL
    private let notifFileURL: URL
    private let apiKeysFileURL: URL
    private let profileFileURL: URL

    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("projects.json")
        self.deletedFileURL = docs.appendingPathComponent("deleted_projects.json")
        self.notifFileURL = docs.appendingPathComponent("notifications.json")
        self.apiKeysFileURL = docs.appendingPathComponent("api_keys.json")
        self.profileFileURL = docs.appendingPathComponent("user_profile.json")
        loadLocalData()
    }

    // MARK: - Filtered & Sorted Projects
    public var activeProjects: [Project] {
        projects.filter { !$0.archived && !$0.deleted }
    }

    public var archivedProjects: [Project] {
        projects.filter { $0.archived && !$0.deleted }
    }

    public var trashedProjects: [Project] {
        projects.filter { $0.deleted }
    }

    public var filteredProjects: [Project] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matched = activeProjects.filter { p in
            let matchesSearch: Bool = {
                if q.isEmpty { return true }
                if p.title.lowercased().contains(q) { return true }
                if p.description.lowercased().contains(q) { return true }
                return p.mainTopics.contains { topic in
                    topic.title.lowercased().contains(q) ||
                    topic.subTopics.contains { sub in
                        sub.title.lowercased().contains(q) ||
                        sub.items.contains { item in item.title.lowercased().contains(q) }
                    }
                }
            }()

            let normCat = normalizeCategory(p.category)
            let matchesCat = (selectedCategory == "all") || (normCat == selectedCategory)

            let normPrio = normalizePriority(p.priority)
            let matchesPrio = (selectedPriority == "all") || (normPrio == selectedPriority)

            return matchesSearch && matchesCat && matchesPrio
        }

        // Apply sorting: Pinned always first!
        let pinned = matched.filter { $0.pinned }
        let unpinned = matched.filter { !$0.pinned }

        return sortList(pinned) + sortList(unpinned)
    }

    private func sortList(_ list: [Project]) -> [Project] {
        switch sortOption {
        case "alpha_asc":
            return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case "alpha_desc":
            return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case "update_desc":
            return list.sorted { $0.lastUpdated > $1.lastUpdated }
        case "update_asc":
            return list.sorted { $0.lastUpdated < $1.lastUpdated }
        case "priority_asc":
            return list.sorted { priorityScore($0.priority) < priorityScore($1.priority) }
        case "priority_desc":
            return list.sorted { priorityScore($0.priority) > priorityScore($1.priority) }
        case "deadline_asc":
            return list.sorted { ($0.deadline ?? "9999") < ($1.deadline ?? "9999") }
        case "deadline_asc_rev":
            return list.sorted { ($0.deadline ?? "0000") > ($1.deadline ?? "0000") }
        default:
            return list // "custom" preserves drag-and-drop order
        }
    }

    private func priorityScore(_ priority: String) -> Int {
        switch normalizePriority(priority) {
        case "urgent": return 4
        case "high": return 3
        case "normal": return 2
        case "low": return 1
        default: return 2
        }
    }

    public func normalizeCategory(_ cat: String?) -> String {
        let norm = (cat ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if norm.contains("ders") || norm == "blue" { return "ders" }
        if norm.contains("proje") || norm.contains("yazilim") || norm == "green" { return "proje" }
        if norm.contains("meslek") || norm.contains("kariyer") || norm == "purple" { return "mesleki" }
        if norm.contains("hobi") || norm == "orange" { return "hobi" }
        return "diger"
    }

    public func normalizePriority(_ prio: String?) -> String {
        let norm = (prio ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch norm {
        case "low", "dusuk", "düşük", "green": return "low"
        case "normal", "orta", "medium", "yellow": return "normal"
        case "high", "yuksek", "yüksek", "orange": return "high"
        case "urgent", "acil", "red", "very_high": return "urgent"
        default: return "normal"
        }
    }

    // MARK: - Data Persistence
    public func loadLocalData() {
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode([Project].self, from: data), !loaded.isEmpty {
            self.projects = loaded
        } else {
            // Default sample projects (1:1 Ground Truth matching Android ProjectFileStore.kt createSampleProjects())
            self.projects = [
                Project(
                    id: "p-kotlin-compose",
                    title: "Kotlin & Jetpack Compose ile Android Geliştirme",
                    description: "Modern deklaratif UI mimarisi ve saf Kotlin ile uçtan uca native mobil uygulama geliştirme süreci.",
                    category: "Yazılım",
                    priority: "high",
                    startDate: "2026-10-21",
                    deadline: "2026-12-31",
                    progress: 62,
                    mainTopics: [
                        MainTopic(
                            id: "t1-kotlin",
                            title: "1. Temel Kotlin ve Modern Android Mimarisi",
                            description: "Coroutines, Flow, MVVM ve State yönetimi prensipleri.",
                            subTopics: [
                                SubTopic(
                                    id: "st1-1",
                                    title: "Kotlin Coroutines & Asenkron Programlama",
                                    completed: true,
                                    items: [
                                        Item(id: "i1-1", title: "Dispatcher ve Scope yönetimi", completed: true, quantity: 1),
                                        Item(id: "i1-2", title: "StateFlow ve SharedFlow kullanımı", completed: true, quantity: 1)
                                    ],
                                    notes: [Note(content: "StateFlow, UI state'lerini saklamak ve gözlemlemek için en iyi pratiktir.")]
                                ),
                                SubTopic(
                                    id: "st1-2",
                                    title: "Jetpack Compose Deklaratif UI Temelleri",
                                    completed: true,
                                    items: [
                                        Item(id: "i1-3", title: "Composable fonksiyonlar ve Modifier zincirleri", completed: true, quantity: 1),
                                        Item(id: "i1-4", title: "State Hoisting ve Unidirectional Data Flow", completed: true, quantity: 1)
                                    ]
                                )
                            ]
                        ),
                        MainTopic(
                            id: "t2-data",
                            title: "2. Veri Yönetimi ve Yerel Depolama",
                            description: "DataStore, Room ve Dosya Tabanlı JSON depolama.",
                            subTopics: [
                                SubTopic(
                                    id: "st2-1",
                                    title: "Preferences & Proto DataStore",
                                    completed: false,
                                    items: [
                                        Item(id: "i2-1", title: "Kullanıcı ayarlarının asenkron saklanması", completed: false, quantity: 1),
                                        Item(id: "i2-2", title: "Karanlık/Aydınlık mod persistansı", completed: true, quantity: 1)
                                    ]
                                ),
                                SubTopic(
                                    id: "st2-2",
                                    title: "Gist / Bulut Yedekleme Entegrasyonu",
                                    completed: false,
                                    items: [
                                        Item(id: "i2-3", title: "GitHub Gist REST API entegrasyonu", completed: false, quantity: 1),
                                        Item(id: "i2-4", title: "Otomatik çift yönlü senkronizasyon", completed: false, quantity: 1)
                                    ]
                                )
                            ]
                        )
                    ],
                    pinned: true
                ),
                Project(
                    id: "p-ai-deep-learning",
                    title: "Yapay Zeka & Derin Öğrenme Çalışmaları",
                    description: "Modern transformer mimarileri ve makine öğrenimi modelleri üzerine araştırma ve uygulama planı.",
                    category: "Ders",
                    priority: "medium",
                    startDate: "2026-10-21",
                    deadline: "2026-10-15",
                    progress: 0,
                    mainTopics: [
                        MainTopic(
                            id: "t1-ai",
                            title: "1. Matematiksel Temeller & Python Kütüphaneleri",
                            description: "Lineer cebir, olasılık ve PyTorch temelleri.",
                            subTopics: [
                                SubTopic(
                                    id: "st-ai-1",
                                    title: "PyTorch Tensor İşlemleri & Autograd",
                                    completed: false,
                                    items: [
                                        Item(id: "i-ai-1", title: "Tensor manipülasyonları ve GPU kullanımı", completed: false, quantity: 1),
                                        Item(id: "i-ai-2", title: "Geriye yayılım (Backpropagation) hesapları", completed: false, quantity: 1)
                                    ]
                                )
                            ]
                        )
                    ],
                    pinned: false
                )
            ]
            saveLocalDataDirect()
        }

        if let data = try? Data(contentsOf: deletedFileURL),
           let loaded = try? JSONDecoder().decode([DeletedItemRecord].self, from: data) {
            self.deletedProjectIds = loaded
        }

        if let data = try? Data(contentsOf: notifFileURL),
           let loaded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            self.notifications = loaded
        }

        if let data = try? Data(contentsOf: apiKeysFileURL),
           let loaded = try? JSONDecoder().decode(ApiKeysConfig.self, from: data) {
            self.apiKeys = loaded
        }

        if let data = try? Data(contentsOf: profileFileURL),
           let loaded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = loaded
        } else {
            let email = UserDefaults.standard.string(forKey: "ulgen_sync_email") ?? ""
            self.userProfile = UserProfile(
                displayName: email.isEmpty ? "Kullanıcı" : email.components(separatedBy: "@").first?.capitalized ?? "Kullanıcı",
                username: email.isEmpty ? "kullanici" : email.components(separatedBy: "@").first?.lowercased() ?? "kullanici",
                email: email
            )
        }
    }

    public func saveLocalDataDirect() {
        if let data = try? JSONEncoder().encode(projects) {
            try? data.write(to: fileURL)
        }
        if let data = try? JSONEncoder().encode(deletedProjectIds) {
            try? data.write(to: deletedFileURL)
        }
        if let data = try? JSONEncoder().encode(notifications) {
            try? data.write(to: notifFileURL)
        }
        if let data = try? JSONEncoder().encode(apiKeys) {
            try? data.write(to: apiKeysFileURL)
        }
        if let data = try? JSONEncoder().encode(userProfile) {
            try? data.write(to: profileFileURL)
        }
    }

    public func saveLocalData(modifiedProjectId: String? = nil, isDeletion: Bool = false) {
        saveLocalDataDirect()

        // Real-Time Cross-Device Sync Broadcast (HiveMQ MQTT & Cloudflare Worker KV)
        if isDeletion, let delId = modifiedProjectId {
            MqttSyncEngine.shared.broadcastProjectDelete(id: delId)
            Task {
                _ = await CloudflareSyncService.deleteProject(id: delId)
            }
        } else if let modId = modifiedProjectId, let project = projects.first(where: { $0.id == modId }) {
            MqttSyncEngine.shared.broadcastProjectChange(project)
            Task {
                _ = await CloudflareSyncService.pushProject(project)
            }
        } else {
            let event = AccountSyncEvent(
                senderDeviceId: MqttSyncEngine.shared.deviceId,
                eventType: "STATE_SYNC",
                timestamp: Int64(Date().timeIntervalSince1970 * 1000)
            )
            MqttSyncEngine.shared.broadcastAccountEvent(event)
        }
    }

    // MARK: - Incoming Remote Sync Handlers
    public func mergeIncomingProject(_ incoming: Project) {
        // Tombstone Check
        if let tombstone = deletedProjectIds.first(where: { $0.id == incoming.id }) {
            if incoming.lastUpdated <= tombstone.deletedAt + 10_000 {
                return
            }
        }

        if let idx = projects.firstIndex(where: { $0.id == incoming.id }) {
            // Last-Write-Wins (LWW)
            if incoming.lastUpdated >= projects[idx].lastUpdated {
                projects[idx] = incoming
                recalculateProgress(projectId: incoming.id)
                saveLocalDataDirect()
            }
        } else {
            projects.insert(incoming, at: 0)
            recalculateProgress(projectId: incoming.id)
            saveLocalDataDirect()
        }
    }

    public func deleteProjectLocally(id: String) {
        projects.removeAll { $0.id == id }
        if !deletedProjectIds.contains(where: { $0.id == id }) {
            deletedProjectIds.append(DeletedItemRecord(id: id, deletedAt: Int64(Date().timeIntervalSince1970 * 1000)))
        }
        saveLocalDataDirect()
    }

    public func syncWithCloud() async {
        DispatchQueue.main.async {
            self.isSyncing = true
        }

        // 1. Cloudflare Worker KV Sync (push local & fetch remote)
        for p in projects {
            _ = await CloudflareSyncService.pushProject(p)
            if let remote = await CloudflareSyncService.fetchProject(id: p.id) {
                DispatchQueue.main.async {
                    self.mergeIncomingProject(remote)
                }
            }
        }

        // 2. Google Drive Master Backup Sync (Bidirectional LWW)
        if !userProfile.email.isEmpty {
            if let remoteBackup = try? await GoogleDriveSyncEngine.shared.fetchMasterBackup() {
                for remoteP in remoteBackup.projects {
                    DispatchQueue.main.async {
                        self.mergeIncomingProject(remoteP)
                    }
                }
            }
            _ = try? await GoogleDriveSyncEngine.shared.pushMasterBackup(projects: projects, deleted: deletedProjectIds)
        }

        // 3. MQTT Live Broadcast
        let event = AccountSyncEvent(
            senderDeviceId: MqttSyncEngine.shared.deviceId,
            eventType: "STATE_SYNC",
            projectId: "all",
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        MqttSyncEngine.shared.broadcastAccountEvent(event)

        DispatchQueue.main.async {
            self.isSyncing = false
            MqttSyncEngine.shared.lastSyncTimestamp = Date()
        }
    }

    // MARK: - Project CRUD
    public func addProject(
        title: String,
        description: String,
        category: String,
        priority: String,
        startDate: String? = nil,
        deadline: String? = nil,
        customColors: CustomColorConfig? = nil
    ) {
        let newP = Project(
            title: title,
            description: description,
            category: category,
            priority: priority,
            startDate: startDate,
            deadline: deadline,
            customColors: customColors
        )
        projects.insert(newP, at: 0)
        saveLocalData(modifiedProjectId: newP.id)
    }

    public func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            projects[idx] = updated
            saveLocalData(modifiedProjectId: updated.id)
        }
    }

    public func togglePin(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].pinned.toggle()
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData(modifiedProjectId: id)
        }
    }

    public func toggleArchive(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].archived.toggle()
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData(modifiedProjectId: id)
        }
    }

    public func deleteProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].deleted = true
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData(modifiedProjectId: id)
        }
    }

    public func restoreProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].deleted = false
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData(modifiedProjectId: id)
        }
    }

    public func permanentDeleteProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects.remove(at: idx)
            deletedProjectIds.append(DeletedItemRecord(id: id, deletedAt: Int64(Date().timeIntervalSince1970 * 1000)))
            saveLocalData(modifiedProjectId: id, isDeletion: true)
        }
    }

    // MARK: - Reordering
    public func reorderProjects(fromOffsets: IndexSet, toOffset: Int) {
        projects.move(fromOffsets: fromOffsets, toOffset: toOffset)
        saveLocalData()
    }

    // MARK: - Topic Operations
    public func addMainTopic(projectId: String, title: String, description: String = "", estimatedHours: Int = 0) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let newTopic = MainTopic(
            title: title,
            description: description,
            estimatedHours: estimatedHours
        )
        projects[pIdx].mainTopics.append(newTopic)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func updateMainTopic(projectId: String, topic: MainTopic) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        if let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topic.id }) {
            projects[pIdx].mainTopics[tIdx] = topic
            projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            recalculateProgress(projectId: projectId)
            saveLocalData(modifiedProjectId: projectId)
        }
    }

    public func deleteMainTopic(projectId: String, topicId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].mainTopics.removeAll { $0.id == topicId }
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func addSubTopic(projectId: String, mainTopicId: String, title: String, description: String = "") {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }) else { return }
        let newSub = SubTopic(title: title, description: description)
        projects[pIdx].mainTopics[tIdx].subTopics.append(newSub)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func updateSubTopic(projectId: String, mainTopicId: String, subTopic: SubTopic) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }) else { return }
        if let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopic.id }) {
            projects[pIdx].mainTopics[tIdx].subTopics[sIdx] = subTopic
            projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            recalculateProgress(projectId: projectId)
            saveLocalData(modifiedProjectId: projectId)
        }
    }

    public func deleteSubTopic(projectId: String, mainTopicId: String, subTopicId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }) else { return }
        projects[pIdx].mainTopics[tIdx].subTopics.removeAll { $0.id == subTopicId }
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func addItem(projectId: String, mainTopicId: String, subTopicId: String, title: String, quantity: Int = 1) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }) else { return }
        let newItem = Item(title: title, quantity: quantity)
        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.append(newItem)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func toggleItem(projectId: String, topicId: String, subTopicId: String, itemId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }),
              let iIdx = projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.firstIndex(where: { $0.id == itemId }) else { return }

        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items[iIdx].completed.toggle()
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func toggleSubTopic(projectId: String, mainTopicId: String, subTopicId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }) else { return }

        let allDone = projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.allSatisfy { $0.completed }
        let newStatus = !allDone
        for i in 0..<projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.count {
            projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items[i].completed = newStatus
        }
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func updateItemQuantity(projectId: String, topicId: String, subTopicId: String, itemId: String, delta: Int) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }),
              let iIdx = projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.firstIndex(where: { $0.id == itemId }) else { return }

        let cur = projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items[iIdx].quantity
        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items[iIdx].quantity = max(1, cur + delta)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func deleteItem(projectId: String, topicId: String, subTopicId: String, itemId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }) else { return }

        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.removeAll { $0.id == itemId }
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(projectId: projectId)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func addNote(projectId: String, content: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].notes.insert(Note(content: content), at: 0)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func deleteNote(projectId: String, noteId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].notes.removeAll { $0.id == noteId }
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func recalculateProgress(projectId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var total = 0
        var completed = 0

        for t in projects[pIdx].mainTopics {
            for s in t.subTopics {
                for i in s.items {
                    total += 1
                    if i.completed { completed += 1 }
                }
            }
        }

        if total > 0 {
            projects[pIdx].progress = Int(Double(completed) / Double(total) * 100.0)
        }
    }

    public func addChatSession(projectId: String, session: ChatSession) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].chatSessions.insert(session, at: 0)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func addChatMessage(projectId: String, role: String, content: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let newMsg = ChatMessage(role: role, content: content)
        if projects[pIdx].chatSessions.isEmpty {
            projects[pIdx].chatSessions.append(ChatSession(title: "Mühendislik Sohbeti", messages: [newMsg]))
        } else {
            projects[pIdx].chatSessions[0].messages.append(newMsg)
        }
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData(modifiedProjectId: projectId)
    }

    public func updateUserProfile(displayName: String, username: String, email: String) {
        self.userProfile.displayName = displayName
        self.userProfile.username = username
        self.userProfile.email = email
        saveLocalDataDirect()

        // Also update MqttSyncEngine email if changed
        if MqttSyncEngine.shared.userEmail != email {
            MqttSyncEngine.shared.userEmail = email
        }
    }

    public func resetAllData() {
        projects.removeAll()
        deletedProjectIds.removeAll()
        notifications.removeAll()
        saveLocalDataDirect()
    }
}
