import Foundation
import Combine
import SwiftUI

public class ProjectRepository: ObservableObject {
    public static let shared = ProjectRepository()

    @Published public var projects: [Project] = []
    @Published public var deletedProjectIds: [DeletedItemRecord] = []
    @Published public var notifications: [AppNotification] = []
    @Published public var apiKeys: ApiKeysConfig = ApiKeysConfig()
    @Published public var isDarkMode: Bool = true
    @Published public var activeCategory: String = "Tümü"
    @Published public var searchQuery: String = ""
    @Published public var sortBy: String = "name_asc" // Deterministik sıralama kuralı: LOWER(name) ASC

    private let fileURL: URL
    private let deletedFileURL: URL
    private let notifFileURL: URL
    private let apiKeysFileURL: URL

    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("projects.json")
        self.deletedFileURL = docs.appendingPathComponent("deleted_projects.json")
        self.notifFileURL = docs.appendingPathComponent("notifications.json")
        self.apiKeysFileURL = docs.appendingPathComponent("api_keys.json")
        loadLocalData()
    }

    // MARK: - Data Persistence
    public func loadLocalData() {
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode([Project].self, from: data) {
            self.projects = loaded
        } else {
            // İlk açılış: Donanım Mühendisliği Başlangıç Projeleri
            self.projects = [
                Project(
                    title: "1MHz GaN Senkron Buck-Boost",
                    description: "EPC2001C GaN FET'ler ve STM32G474 HRTIM tabanlı yüksek frekans güç katı tasarımı.",
                    category: "Donanım",
                    priority: "high",
                    progress: 65,
                    mainTopics: [
                        MainTopic(
                            title: "Şematik ve Güç Katı",
                            description: "LTspice simülasyonları ve Altium şematik girişi.",
                            subTopics: [
                                SubTopic(
                                    title: "MOSFET Sürücü Devresi",
                                    items: [
                                        Item(title: "UCC27282 bootstrap kondansatör hesabı", completed: true, quantity: 2),
                                        Item(title: "Gate dirençleri sönümleme testi", completed: true, quantity: 4),
                                        Item(title: "Dead-time optimizasyonu (HRTIM)", completed: false, quantity: 1)
                                    ]
                                )
                            ]
                        ),
                        MainTopic(
                            title: "PCB Layout ve Termal Tasarım",
                            description: "4 katmanlı 2oz bakır empedans kontrollü kart.",
                            subTopics: [
                                SubTopic(
                                    title: "Termal Via Yerleşimi",
                                    items: [
                                        Item(title: "GaN pedleri altına 0.3mm via dizilimi", completed: false, quantity: 16)
                                    ]
                                )
                            ]
                        )
                    ],
                    pinned: true
                ),
                Project(
                    title: "STM32 CAN-FD Telemetri Ünitesi",
                    description: "Atölye tezgahı ve araç sensörleri için izole CAN-FD / BLE veri kaydedici.",
                    category: "Gömülü",
                    priority: "medium",
                    progress: 30,
                    mainTopics: [
                        MainTopic(
                            title: "Firmware Geliştirme",
                            description: "FreeRTOS ve RingBuffer kuyruk mimarisi.",
                            subTopics: [
                                SubTopic(
                                    title: "CAN-FD Driver",
                                    items: [
                                        Item(title: "FDCAN1 filtre tablosu yapılandırması", completed: true, quantity: 1),
                                        Item(title: "DMA tabanlı UART köprüsü", completed: false, quantity: 1)
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
            saveLocalData()
        }

        if let delData = try? Data(contentsOf: deletedFileURL),
           let delLoaded = try? JSONDecoder().decode([DeletedItemRecord].self, from: delData) {
            self.deletedProjectIds = delLoaded
        }

        if let notifData = try? Data(contentsOf: notifFileURL),
           let notifLoaded = try? JSONDecoder().decode([AppNotification].self, from: notifData) {
            self.notifications = notifLoaded
        } else {
            self.notifications = [
                AppNotification(title: "Ülgen iOS Aktif", message: "Yerel SwiftUI mimarisi ve MQTT canlı senkronizasyon motoru devrede.", type: "info")
            ]
        }

        if let keysData = try? Data(contentsOf: apiKeysFileURL),
           let keysLoaded = try? JSONDecoder().decode(ApiKeysConfig.self, from: keysData) {
            self.apiKeys = keysLoaded
        }
    }

    public func saveLocalData() {
        if let data = try? JSONEncoder().encode(projects) {
            try? data.write(to: fileURL)
        }
        if let delData = try? JSONEncoder().encode(deletedProjectIds) {
            try? delData.write(to: deletedFileURL)
        }
        if let notifData = try? JSONEncoder().encode(notifications) {
            try? notifData.write(to: notifFileURL)
        }
        if let keysData = try? JSONEncoder().encode(apiKeys) {
            try? keysData.write(to: apiKeysFileURL)
        }
    }

    // MARK: - Project CRUD
    public func addProject(
        title: String,
        description: String,
        category: String,
        priority: String
    ) {
        let newProj = Project(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            priority: priority,
            mainTopics: [
                MainTopic(
                    title: "Aşama 1: Hazırlık",
                    description: "Temel planlama ve gereksinimler",
                    subTopics: [
                        SubTopic(
                            title: "İlk Görevler",
                            items: [
                                Item(title: "Gereksinim analizi ve malzeme listesi", completed: false, quantity: 1)
                            ]
                        )
                    ]
                )
            ]
        )
        projects.insert(newProj, at: 0)
        saveLocalData()
        Haptics.success()
        MqttSyncEngine.shared.publishProjectChange(newProj)
    }

    public func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            recalculateProgress(for: &updated)
            projects[idx] = updated
            saveLocalData()
            MqttSyncEngine.shared.publishProjectChange(updated)
        }
    }

    public func deleteProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            var proj = projects[idx]
            proj.deleted = true
            proj.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            projects[idx] = proj
            deletedProjectIds.append(DeletedItemRecord(id: id))
            saveLocalData()
            Haptics.heavy()
            MqttSyncEngine.shared.publishProjectDelete(id: id)
        }
    }

    public func permanentDeleteProject(id: String) {
        projects.removeAll(where: { $0.id == id })
        deletedProjectIds.append(DeletedItemRecord(id: id))
        saveLocalData()
        Haptics.heavy()
        MqttSyncEngine.shared.publishProjectDelete(id: id)
    }

    public func restoreProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].deleted = false
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData()
            Haptics.success()
            MqttSyncEngine.shared.publishProjectChange(projects[idx])
        }
    }

    public func toggleArchive(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].archived.toggle()
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData()
            Haptics.light()
            MqttSyncEngine.shared.publishProjectChange(projects[idx])
        }
    }

    public func togglePin(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].pinned.toggle()
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData()
            Haptics.light()
            MqttSyncEngine.shared.publishProjectChange(projects[idx])
        }
    }

    // MARK: - Topic & Item Tree Operations
    public func addMainTopic(projectId: String, title: String, description: String) {
        guard let idx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let newTopic = MainTopic(title: title, description: description)
        projects[idx].mainTopics.append(newTopic)
        projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(for: &projects[idx])
        saveLocalData()
        Haptics.success()
        MqttSyncEngine.shared.publishProjectChange(projects[idx])
    }

    public func addSubTopic(projectId: String, mainTopicId: String, title: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        guard let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }) else { return }
        let newSub = SubTopic(title: title)
        projects[pIdx].mainTopics[tIdx].subTopics.append(newSub)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(for: &projects[pIdx])
        saveLocalData()
        Haptics.success()
        MqttSyncEngine.shared.publishProjectChange(projects[pIdx])
    }

    public func addItem(projectId: String, mainTopicId: String, subTopicId: String, title: String, quantity: Int = 1) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        guard let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }) else { return }
        guard let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }) else { return }

        let newItem = Item(title: title, quantity: quantity)
        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.append(newItem)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(for: &projects[pIdx])
        saveLocalData()
        Haptics.success()
        MqttSyncEngine.shared.publishProjectChange(projects[pIdx])
    }

    public func toggleItem(projectId: String, topicId: String, subTopicId: String, itemId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var project = projects[pIdx]

        for tIdx in 0..<project.mainTopics.count {
            if project.mainTopics[tIdx].id == topicId {
                for sIdx in 0..<project.mainTopics[tIdx].subTopics.count {
                    if project.mainTopics[tIdx].subTopics[sIdx].id == subTopicId {
                        for iIdx in 0..<project.mainTopics[tIdx].subTopics[sIdx].items.count {
                            if project.mainTopics[tIdx].subTopics[sIdx].items[iIdx].id == itemId {
                                project.mainTopics[tIdx].subTopics[sIdx].items[iIdx].completed.toggle()
                                project.mainTopics[tIdx].subTopics[sIdx].items[iIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
                                Haptics.medium()
                            }
                        }
                    }
                }
            }
        }

        project.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        recalculateProgress(for: &project)
        projects[pIdx] = project
        saveLocalData()
        MqttSyncEngine.shared.publishProjectChange(project)
    }

    public func adjustItemQuantity(projectId: String, topicId: String, subTopicId: String, itemId: String, delta: Int) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var project = projects[pIdx]

        for tIdx in 0..<project.mainTopics.count {
            if project.mainTopics[tIdx].id == topicId {
                for sIdx in 0..<project.mainTopics[tIdx].subTopics.count {
                    if project.mainTopics[tIdx].subTopics[sIdx].id == subTopicId {
                        for iIdx in 0..<project.mainTopics[tIdx].subTopics[sIdx].items.count {
                            if project.mainTopics[tIdx].subTopics[sIdx].items[iIdx].id == itemId {
                                let newQty = max(0, project.mainTopics[tIdx].subTopics[sIdx].items[iIdx].quantity + delta)
                                project.mainTopics[tIdx].subTopics[sIdx].items[iIdx].quantity = newQty
                                project.mainTopics[tIdx].subTopics[sIdx].items[iIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
                                Haptics.light()
                            }
                        }
                    }
                }
            }
        }

        project.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        projects[pIdx] = project
        saveLocalData()
        MqttSyncEngine.shared.publishProjectChange(project)
    }

    public func addMedia(projectId: String, name: String, mimeType: String, base64: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let media = MediaItem(uri: "", mimeType: mimeType, name: name, base64Data: base64)
        projects[pIdx].media.append(media)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData()
        Haptics.success()
        MqttSyncEngine.shared.publishProjectChange(projects[pIdx])
    }

    public func addNote(projectId: String, content: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let note = Note(content: content)
        projects[pIdx].notes.append(note)
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData()
        Haptics.success()
        MqttSyncEngine.shared.publishProjectChange(projects[pIdx])
    }

    public func addChatMessage(projectId: String, role: String, content: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        let msg = ChatMessage(role: role, content: content)
        if projects[pIdx].chatSessions.isEmpty {
            projects[pIdx].chatSessions.append(ChatSession(messages: [msg]))
        } else {
            projects[pIdx].chatSessions[0].messages.append(msg)
            projects[pIdx].chatSessions[0].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        }
        projects[pIdx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
        saveLocalData()
    }

    private func recalculateProgress(for project: inout Project) {
        var totalItems = 0
        var completedItems = 0
        for topic in project.mainTopics where !topic.deleted {
            for sub in topic.subTopics where !sub.deleted {
                for item in sub.items where !item.deleted {
                    totalItems += 1
                    if item.completed { completedItems += 1 }
                }
            }
        }
        if totalItems > 0 {
            project.progress = Int((Double(completedItems) / Double(totalItems)) * 100)
        } else {
            project.progress = 0
        }
    }

    // MARK: - Query & Filtered Lists
    public var activeProjects: [Project] {
        projects.filter { !$0.deleted && !$0.archived }
    }

    public var archivedProjects: [Project] {
        projects.filter { !$0.deleted && $0.archived }
    }

    public var trashedProjects: [Project] {
        projects.filter { $0.deleted }
    }

    public var filteredProjects: [Project] {
        var list = activeProjects

        if activeCategory != "Tümü" {
            list = list.filter { $0.category.lowercased() == activeCategory.lowercased() }
        }

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q)
            }
        }

        switch sortBy {
        case "name_asc":
            list.sort {
                if $0.pinned != $1.pinned { return $0.pinned && !$1.pinned }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case "progress_desc":
            list.sort {
                if $0.pinned != $1.pinned { return $0.pinned && !$1.pinned }
                return $0.progress > $1.progress
            }
        case "priority_desc":
            list.sort {
                let pOrder = ["high": 3, "medium": 2, "low": 1]
                let p0 = pOrder[$0.priority.lowercased()] ?? 0
                let p1 = pOrder[$1.priority.lowercased()] ?? 0
                return p0 > p1
            }
        default:
            list.sort {
                if $0.pinned != $1.pinned { return $0.pinned && !$1.pinned }
                return $0.lastUpdated > $1.lastUpdated
            }
        }

        return list
    }
}
