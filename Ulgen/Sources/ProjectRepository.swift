import Foundation
import Combine
import SwiftUI

public class ProjectRepository: ObservableObject {
    public static let shared = ProjectRepository()

    @Published public var projects: [Project] = []
    @Published public var deletedProjectIds: [DeletedItemRecord] = []
    @Published public var isDarkMode: Bool = true
    @Published public var activeCategory: String = "Tümü"
    @Published public var searchQuery: String = ""
    @Published public var sortBy: String = "name_asc" // Deterministik sıralama kuralı: LOWER(name) ASC

    private let fileURL: URL
    private let deletedFileURL: URL
    private var cancellables = Set<AnyCancellable>()

    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent("projects.json")
        self.deletedFileURL = docs.appendingPathComponent("deleted_projects.json")
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
    }

    public func saveLocalData() {
        if let data = try? JSONEncoder().encode(projects) {
            try? data.write(to: fileURL)
        }
        if let delData = try? JSONEncoder().encode(deletedProjectIds) {
            try? delData.write(to: deletedFileURL)
        }
    }

    // MARK: - CRUD Operations
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
                    title: "Ana Aşama 1",
                    description: "İlk çalışma adımları",
                    subTopics: [
                        SubTopic(
                            title: "Görevler",
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
            let removed = projects.remove(at: idx)
            deletedProjectIds.append(DeletedItemRecord(id: id))
            saveLocalData()
            Haptics.heavy()
            MqttSyncEngine.shared.publishProjectDelete(id: id)
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

    // MARK: - Query & Filtered List
    public var filteredProjects: [Project] {
        var list = projects.filter { !$0.deleted && !$0.archived }

        if activeCategory != "Tümü" {
            list = list.filter { $0.category.lowercased() == activeCategory.lowercased() }
        }

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q)
            }
        }

        // Deterministik Sıralama: Sabit ve kararlı liste
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
        default:
            list.sort {
                if $0.pinned != $1.pinned { return $0.pinned && !$1.pinned }
                return $0.lastUpdated > $1.lastUpdated
            }
        }

        return list
    }
}
