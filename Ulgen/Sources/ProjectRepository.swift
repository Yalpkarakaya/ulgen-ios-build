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
    @Published public var selectedCategory: String = "all"
    @Published public var selectedPriority: String = "all"
    @Published public var searchQuery: String = ""
    @Published public var sortOption: String = "custom" // "custom", "alpha_asc", "alpha_desc", "update_desc", "update_asc", "priority_asc", "priority_desc", "deadline_asc", "deadline_asc_rev"

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
            // Android ProjectFileStore.kt ile 1:1 Tam Eşleşen Başlangıç Verileri
            self.projects = [
                Project(
                    id: "sample-p1-kotlin",
                    title: "Kotlin & Jetpack Compose ile Android Geliştirme",
                    description: "Modern deklaratif UI mimarisi ve saf Kotlin ile uçtan uca native mobil uygulama geliştirme süreci.",
                    category: "proje",
                    priority: "high",
                    startDate: "2026-01-10",
                    deadline: "2026-12-31",
                    progress: 50,
                    mainTopics: [
                        MainTopic(
                            id: "t1",
                            title: "1. Temel Kotlin ve Modern Android Mimarisi",
                            description: "Coroutines, Flow, MVVM ve State yönetimi prensipleri.",
                            subTopics: [
                                SubTopic(
                                    id: "st1-1",
                                    title: "Kotlin Coroutines & Asenkron Programlama",
                                    completed: true,
                                    items: [
                                        Item(title: "Dispatcher ve Scope yönetimi", completed: true, quantity: 1),
                                        Item(title: "StateFlow ve SharedFlow kullanımı", completed: true, quantity: 1)
                                    ],
                                    notes: [Note(content = "StateFlow, UI state'lerini saklamak ve gözlemlemek için en iyi pratiktir.")]
                                ),
                                SubTopic(
                                    id: "st1-2",
                                    title: "Jetpack Compose Deklaratif UI Temelleri",
                                    completed: true,
                                    items: [
                                        Item(title: "Composable fonksiyonlar ve Modifier zincirleri", completed: true, quantity: 1),
                                        Item(title: "State Hoisting ve Unidirectional Data Flow", completed: true, quantity: 1)
                                    ]
                                )
                            ]
                        ),
                        MainTopic(
                            id: "t2",
                            title: "2. Veri Yönetimi ve Yerel Depolama",
                            description: "DataStore, Room ve Dosya Tabanlı JSON depolama.",
                            subTopics: [
                                SubTopic(
                                    id: "st2-1",
                                    title: "Preferences & Proto DataStore",
                                    completed: false,
                                    items: [
                                        Item(title: "Kullanıcı ayarlarının asenkron saklanması", completed: false, quantity: 1),
                                        Item(title: "Karanlık/Aydınlık mod persistansı", completed: true, quantity: 1)
                                    ]
                                ),
                                SubTopic(
                                    id: "st2-2",
                                    title: "Gist / Bulut Yedekleme Entegrasyonu",
                                    completed: false,
                                    items: [
                                        Item(title: "GitHub Gist REST API entegrasyonu", completed: false, quantity: 1),
                                        Item(title: "Otomatik çift yönlü senkronizasyon", completed: false, quantity: 1)
                                    ]
                                )
                            ]
                        )
                    ],
                    pinned: true
                ),
                Project(
                    id: "sample-p2-ai",
                    title: "Yapay Zeka & Derin Öğrenme Çalışmaları",
                    description: "Modern transformer mimarileri ve makine öğrenimi modelleri üzerine araştırma ve uygulama planı.",
                    category: "ders",
                    priority: "medium",
                    startDate: "2026-03-01",
                    deadline: "2026-10-15",
                    progress: 25,
                    mainTopics: [
                        MainTopic(
                            id: "t2-1",
                            title: "1. Matematiksel Temeller & Python Kütüphaneleri",
                            description: "Lineer cebir, olasılık ve PyTorch temelleri.",
                            subTopics: [
                                SubTopic(
                                    id: "st2-1-1",
                                    title: "PyTorch Tensor İşlemleri & Autograd",
                                    completed: false,
                                    items: [
                                        Item(title: "Tensor manipülasyonları ve GPU kullanımı", completed: true, quantity: 1),
                                        Item(title: "Geriye yayılım (Backpropagation) hesapları", completed: false, quantity: 1)
                                    ]
                                )
                            ]
                        )
                    ],
                    pinned: false
                )
            ]
            saveLocalData()
        }

        // Load other tables
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
    }

    public func saveLocalData() {
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
        saveLocalData()
    }

    public func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            projects[idx] = updated
            saveLocalData()
        }
    }

    public func togglePin(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].pinned.toggle()
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData()
        }
    }

    public func toggleArchive(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].archived.toggle()
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData()
        }
    }

    public func deleteProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].deleted = true
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData()
        }
    }

    public func restoreProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].deleted = false
            projects[idx].lastUpdated = Int64(Date().timeIntervalSince1970 * 1000)
            saveLocalData()
        }
    }

    public func permanentDeleteProject(id: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects.remove(at: idx)
            deletedProjectIds.append(DeletedItemRecord(id: id, deletedAt: Int64(Date().timeIntervalSince1970 * 1000)))
            saveLocalData()
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
        recalculateProgress(projectId: projectId)
        saveLocalData()
    }

    public func updateMainTopic(projectId: String, topic: MainTopic) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        if let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topic.id }) {
            projects[pIdx].mainTopics[tIdx] = topic
            recalculateProgress(projectId: projectId)
            saveLocalData()
        }
    }

    public func deleteMainTopic(projectId: String, topicId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].mainTopics.removeAll { $0.id == topicId }
        recalculateProgress(projectId: projectId)
        saveLocalData()
    }

    public func addSubTopic(projectId: String, mainTopicId: String, title: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }) else { return }
        let newSub = SubTopic(title: title)
        projects[pIdx].mainTopics[tIdx].subTopics.append(newSub)
        recalculateProgress(projectId: projectId)
        saveLocalData()
    }

    public func deleteSubTopic(projectId: String, mainTopicId: String, subTopicId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }) else { return }
        projects[pIdx].mainTopics[tIdx].subTopics.removeAll { $0.id == subTopicId }
        recalculateProgress(projectId: projectId)
        saveLocalData()
    }

    public func addItem(projectId: String, mainTopicId: String, subTopicId: String, title: String, quantity: Int = 1) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == mainTopicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }) else { return }
        let newItem = Item(title: title, quantity: quantity)
        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.append(newItem)
        recalculateProgress(projectId: projectId)
        saveLocalData()
    }

    public func toggleItem(projectId: String, topicId: String, subTopicId: String, itemId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }),
              let iIdx = projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.firstIndex(where: { $0.id == itemId }) else { return }

        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items[iIdx].completed.toggle()
        recalculateProgress(projectId: projectId)
        saveLocalData()
    }

    public func updateItemQuantity(projectId: String, topicId: String, subTopicId: String, itemId: String, delta: Int) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }),
              let iIdx = projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.firstIndex(where: { $0.id == itemId }) else { return }

        let cur = projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items[iIdx].quantity
        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items[iIdx].quantity = max(1, cur + delta)
        saveLocalData()
    }

    public func deleteItem(projectId: String, topicId: String, subTopicId: String, itemId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }),
              let tIdx = projects[pIdx].mainTopics.firstIndex(where: { $0.id == topicId }),
              let sIdx = projects[pIdx].mainTopics[tIdx].subTopics.firstIndex(where: { $0.id == subTopicId }) else { return }

        projects[pIdx].mainTopics[tIdx].subTopics[sIdx].items.removeAll { $0.id == itemId }
        recalculateProgress(projectId: projectId)
        saveLocalData()
    }

    public func addNote(projectId: String, content: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].notes.insert(Note(content: content), at: 0)
        saveLocalData()
    }

    public func deleteNote(projectId: String, noteId: String) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[pIdx].notes.removeAll { $0.id == noteId }
        saveLocalData()
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
}
