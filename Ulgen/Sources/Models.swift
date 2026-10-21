import Foundation

// MARK: - Production Models matching com.ulgen.takip.data.model.*

public struct Project: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var description: String
    public var category: String
    public var priority: String
    public var startDate: String?
    public var deadline: String?
    public var endDate: String?
    public var createdDate: String?
    public var knownTopics: String
    public var learningGoals: String
    public var resources: String
    public var objectives: [String]
    public var recommendedResources: [String]
    public var progress: Int
    public var estimatedHours: Int
    public var estimatedMinutes: Int
    public var mainTopics: [MainTopic]
    public var media: [MediaItem]
    public var notes: [Note]
    public var customColors: CustomColorConfig?
    public var archived: Bool
    public var deleted: Bool
    public var tombstone: Bool
    public var pinned: Bool
    public var shared: Bool
    public var shareEnabled: Bool
    public var shareCode: String?
    public var sharedProjectId: String?
    public var ownerId: String
    public var driveFileId: String?
    public var deletedIds: [DeletedItemRecord]
    public var members: [ProjectMember]
    public var chatSessions: [ChatSession]
    public var createdAt: Int64
    public var lastUpdated: Int64
    public var completionDate: Int64?
    public var completedAt: Int64?

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        description: String = "",
        category: String = "Genel",
        priority: String = "medium",
        startDate: String? = nil,
        deadline: String? = nil,
        endDate: String? = nil,
        createdDate: String? = nil,
        knownTopics: String = "",
        learningGoals: String = "",
        resources: String = "",
        objectives: [String] = [],
        recommendedResources: [String] = [],
        progress: Int = 0,
        estimatedHours: Int = 0,
        estimatedMinutes: Int = 0,
        mainTopics: [MainTopic] = [],
        media: [MediaItem] = [],
        notes: [Note] = [],
        customColors: CustomColorConfig? = nil,
        archived: Bool = false,
        deleted: Bool = false,
        tombstone: Bool = false,
        pinned: Bool = false,
        shared: Bool = false,
        shareEnabled: Bool = false,
        shareCode: String? = nil,
        sharedProjectId: String? = nil,
        ownerId: String = "local",
        driveFileId: String? = nil,
        deletedIds: [DeletedItemRecord] = [],
        members: [ProjectMember] = [],
        chatSessions: [ChatSession] = [],
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastUpdated: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        completionDate: Int64? = nil,
        completedAt: Int64? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.startDate = startDate
        self.deadline = deadline
        self.endDate = endDate
        self.createdDate = createdDate
        self.knownTopics = knownTopics
        self.learningGoals = learningGoals
        self.resources = resources
        self.objectives = objectives
        self.recommendedResources = recommendedResources
        self.progress = progress
        self.estimatedHours = estimatedHours
        self.estimatedMinutes = estimatedMinutes
        self.mainTopics = mainTopics
        self.media = media
        self.notes = notes
        self.customColors = customColors
        self.archived = archived
        self.deleted = deleted
        self.tombstone = tombstone
        self.pinned = pinned
        self.shared = shared
        self.shareEnabled = shareEnabled
        self.shareCode = shareCode
        self.sharedProjectId = sharedProjectId
        self.ownerId = ownerId
        self.driveFileId = driveFileId
        self.deletedIds = deletedIds
        self.members = members
        self.chatSessions = chatSessions
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.completionDate = completionDate
        self.completedAt = completedAt
    }
}

public struct MainTopic: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var description: String
    public var estimatedHours: Int
    public var estimatedMinutes: Int
    public var subTopics: [SubTopic]
    public var attachedMedia: [String]
    public var aiEdited: Bool
    public var deleted: Bool
    public var tombstone: Bool
    public var order: Int
    public var createdAt: Int64
    public var lastUpdated: Int64

    public var completed: Bool {
        guard !subTopics.isEmpty else { return false }
        return subTopics.allSatisfy { sub in
            if !sub.items.isEmpty {
                return sub.items.allSatisfy { $0.completed }
            }
            return sub.completed
        }
    }

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        description: String = "",
        estimatedHours: Int = 0,
        estimatedMinutes: Int = 0,
        subTopics: [SubTopic] = [],
        attachedMedia: [String] = [],
        aiEdited: Bool = false,
        deleted: Bool = false,
        tombstone: Bool = false,
        order: Int = 0,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastUpdated: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.estimatedHours = estimatedHours
        self.estimatedMinutes = estimatedMinutes
        self.subTopics = subTopics
        self.attachedMedia = attachedMedia
        self.aiEdited = aiEdited
        self.deleted = deleted
        self.tombstone = tombstone
        self.order = order
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

public struct SubTopic: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var description: String
    public var completed: Bool
    public var autoCompleted: Bool
    public var completionDate: Int64?
    public var estimatedHours: Int
    public var estimatedMinutes: Int
    public var items: [Item]
    public var notes: [Note]
    public var media: [MediaItem]
    public var attachedMedia: [String]
    public var deleted: Bool
    public var tombstone: Bool
    public var order: Int
    public var createdAt: Int64
    public var lastUpdated: Int64

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        description: String = "",
        completed: Bool = false,
        autoCompleted: Bool = false,
        completionDate: Int64? = nil,
        estimatedHours: Int = 0,
        estimatedMinutes: Int = 0,
        items: [Item] = [],
        notes: [Note] = [],
        media: [MediaItem] = [],
        attachedMedia: [String] = [],
        deleted: Bool = false,
        tombstone: Bool = false,
        order: Int = 0,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastUpdated: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.completed = completed
        self.autoCompleted = autoCompleted
        self.completionDate = completionDate
        self.estimatedHours = estimatedHours
        self.estimatedMinutes = estimatedMinutes
        self.items = items
        self.notes = notes
        self.media = media
        self.attachedMedia = attachedMedia
        self.deleted = deleted
        self.tombstone = tombstone
        self.order = order
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

public struct Item: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var description: String
    public var estimatedHours: Int
    public var estimatedMinutes: Int
    public var completed: Bool
    public var autoCompleted: Bool
    public var completionDate: Int64?
    public var notes: String
    public var attachedMedia: [String]
    public var quantity: Int
    public var deleted: Bool
    public var tombstone: Bool
    public var order: Int
    public var lastUpdated: Int64

    public var displayTitle: String {
        return title.isEmpty ? description : title
    }

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        description: String = "",
        estimatedHours: Int = 0,
        estimatedMinutes: Int = 0,
        completed: Bool = false,
        autoCompleted: Bool = false,
        completionDate: Int64? = nil,
        notes: String = "",
        attachedMedia: [String] = [],
        quantity: Int = 1,
        deleted: Bool = false,
        tombstone: Bool = false,
        order: Int = 0,
        lastUpdated: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.estimatedHours = estimatedHours
        self.estimatedMinutes = estimatedMinutes
        self.completed = completed
        self.autoCompleted = autoCompleted
        self.completionDate = completionDate
        self.notes = notes
        self.attachedMedia = attachedMedia
        self.quantity = quantity
        self.deleted = deleted
        self.tombstone = tombstone
        self.order = order
        self.lastUpdated = lastUpdated
    }
}

public struct Note: Codable, Identifiable, Hashable {
    public var id: String
    public var content: String
    public var createdAt: Int64

    public init(id: String = UUID().uuidString, content: String = "", createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

public struct MediaItem: Codable, Identifiable, Hashable {
    public var id: String
    public var uri: String
    public var mimeType: String
    public var name: String
    public var base64Data: String?
    public var driveFileId: String?
    public var size: Int64
    public var createdAt: Int64

    public init(
        id: String = UUID().uuidString,
        uri: String = "",
        mimeType: String = "image/jpeg",
        name: String = "",
        base64Data: String? = nil,
        driveFileId: String? = nil,
        size: Int64 = 0,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.uri = uri
        self.mimeType = mimeType
        self.name = name
        self.base64Data = base64Data
        self.driveFileId = driveFileId
        self.size = size
        self.createdAt = createdAt
    }
}

public struct ProjectMember: Codable, Identifiable, Hashable {
    public var id: String
    public var email: String
    public var role: String
    public var displayName: String

    public init(id: String = UUID().uuidString, email: String = "", role: String = "viewer", displayName: String = "") {
        self.id = id
        self.email = email
        self.role = role
        self.displayName = displayName
    }
}

public struct CustomColorConfig: Codable, Hashable {
    public var primary: String?
    public var primaryColor: String?
    public var accentColor: String?
    public var cardBg: String?
    public var border: String?
    public var borderColor: String?
    public var progressBar: String?
    public var textColor: String?

    public init(
        primary: String? = nil,
        primaryColor: String? = nil,
        accentColor: String? = nil,
        cardBg: String? = nil,
        border: String? = nil,
        borderColor: String? = nil,
        progressBar: String? = nil,
        textColor: String? = nil
    ) {
        self.primary = primary
        self.primaryColor = primaryColor ?? primary
        self.accentColor = accentColor
        self.cardBg = cardBg
        self.border = border
        self.borderColor = borderColor ?? border
        self.progressBar = progressBar
        self.textColor = textColor
    }
}

public struct DeletedItemRecord: Codable, Identifiable, Hashable {
    public var id: String
    public var deletedAt: Int64

    public init(id: String = "", deletedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.id = id
        self.deletedAt = deletedAt
    }
}

public struct AccountSyncEvent: Codable {
    public var eventId: String
    public var senderDeviceId: String
    public var eventType: String
    public var projectId: String?
    public var timestamp: Int64
    public var projectJson: String?

    public init(
        eventId: String = UUID().uuidString,
        senderDeviceId: String = "",
        eventType: String = "DATA_CHANGED",
        projectId: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        projectJson: String? = nil
    ) {
        self.eventId = eventId
        self.senderDeviceId = senderDeviceId
        self.eventType = eventType
        self.projectId = projectId
        self.timestamp = timestamp
        self.projectJson = projectJson
    }
}

// MARK: - User Profile (Generic, 1:1 with ProfileScreen.kt)
public struct UserProfile: Codable, Hashable {
    public var uid: String
    public var displayName: String
    public var username: String
    public var email: String
    public var avatarUrl: String?
    public var avatarBase64: String?

    public init(
        uid: String = UUID().uuidString,
        displayName: String = "",
        username: String = "",
        email: String = "",
        avatarUrl: String? = nil,
        avatarBase64: String? = nil
    ) {
        self.uid = uid
        self.displayName = displayName
        self.username = username
        self.email = email
        self.avatarUrl = avatarUrl
        self.avatarBase64 = avatarBase64
    }
}

// MARK: - MChat / AI Models
public struct ChatSession: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var messages: [ChatMessage]
    public var createdAt: Int64
    public var lastUpdated: Int64

    public init(id: String = UUID().uuidString, title: String = "Yeni Sohbet", messages: [ChatMessage] = [], createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000), lastUpdated: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

public struct ChatMessage: Codable, Identifiable, Hashable {
    public var id: String
    public var role: String // "user" or "assistant"
    public var content: String
    public var timestamp: Int64

    public init(id: String = UUID().uuidString, role: String, content: String, timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Notification Model
public struct AppNotification: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var message: String
    public var type: String // "info", "sync", "warning"
    public var timestamp: Int64
    public var isRead: Bool

    public init(id: String = UUID().uuidString, title: String, message: String, type: String = "info", timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000), isRead: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

// MARK: - API Keys Configuration
public struct ApiKeysConfig: Codable, Hashable {
    public var geminiApiKey: String
    public var openaiApiKey: String
    public var claudeApiKey: String
    public var deepseekApiKey: String
    public var preferredModel: String

    public init(
        geminiApiKey: String = "",
        openaiApiKey: String = "",
        claudeApiKey: String = "",
        deepseekApiKey: String = "",
        preferredModel: String = "gemini-2.5-flash"
    ) {
        self.geminiApiKey = geminiApiKey
        self.openaiApiKey = openaiApiKey
        self.claudeApiKey = claudeApiKey
        self.deepseekApiKey = deepseekApiKey
        self.preferredModel = preferredModel
    }
}

// MARK: - Backup Models (1:1 with Android BackupModels.kt)
public struct BackupStats: Codable, Hashable {
    public var topics: Int
    public var completedTopics: Int
    public var subs: Int
    public var completedSubs: Int
    public var items: Int
    public var completedItems: Int
    public var notes: Int
    public var links: Int
    public var media: Int
    public var cloudMedia: Int
    public var localMedia: Int
    public var aiChats: Int
    public var progress: Int
    public var total: Int

    public init(
        topics: Int = 0,
        completedTopics: Int = 0,
        subs: Int = 0,
        completedSubs: Int = 0,
        items: Int = 0,
        completedItems: Int = 0,
        notes: Int = 0,
        links: Int = 0,
        media: Int = 0,
        cloudMedia: Int = 0,
        localMedia: Int = 0,
        aiChats: Int = 0,
        progress: Int = 0,
        total: Int = 0
    ) {
        self.topics = topics
        self.completedTopics = completedTopics
        self.subs = subs
        self.completedSubs = completedSubs
        self.items = items
        self.completedItems = completedItems
        self.notes = notes
        self.links = links
        self.media = media
        self.cloudMedia = cloudMedia
        self.localMedia = localMedia
        self.aiChats = aiChats
        self.progress = progress
        self.total = total
    }
}

public struct ProjectBackup: Codable, Identifiable, Hashable {
    public var id: String
    public var createdAt: String
    public var reason: String
    public var title: String
    public var type: String // "auto" or "manual"
    public var stats: BackupStats
    public var data: Project
    public var pool: String

    public init(
        id: String = "bk_\(Int64(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6))",
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        reason: String = "Otomatik Yedekleme",
        title: String = "",
        type: String = "auto",
        stats: BackupStats = BackupStats(),
        data: Project,
        pool: String = "auto"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.reason = reason
        self.title = title
        self.type = type
        self.stats = stats
        self.data = data
        self.pool = pool
    }
}

public struct ExportedProjectBackup: Codable {
    public var version: Int
    public var exportedAt: String
    public var appName: String
    public var project: Project
    public var stats: BackupStats?
    public var backupHistory: [ProjectBackup]

    public init(
        version: Int = 1,
        exportedAt: String = ISO8601DateFormatter().string(from: Date()),
        appName: String = "Ülgen Takip",
        project: Project,
        stats: BackupStats? = nil,
        backupHistory: [ProjectBackup] = []
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.appName = appName
        self.project = project
        self.stats = stats
        self.backupHistory = backupHistory
    }
}

public struct FullSystemBackupEnvelope: Codable {
    public var version: Int
    public var exportedAt: String
    public var appName: String
    public var projects: [Project]
    public var projectBackups: [String: [ProjectBackup]]
    public var mediaBackupMode: String
    public var isDarkMode: Bool

    public init(
        version: Int = 1,
        exportedAt: String = ISO8601DateFormatter().string(from: Date()),
        appName: String = "Ülgen Takip Tam Sistem Yedeği",
        projects: [Project] = [],
        projectBackups: [String: [ProjectBackup]] = [:],
        mediaBackupMode: String = "cloud_permanent",
        isDarkMode: Bool = false
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.appName = appName
        self.projects = projects
        self.projectBackups = projectBackups
        self.mediaBackupMode = mediaBackupMode
        self.isDarkMode = isDarkMode
    }
}
