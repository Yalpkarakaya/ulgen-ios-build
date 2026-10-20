import Foundation

// MARK: - App Models matching com.ulgen.takip.data.model.Models.kt

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

    public init(id: String = UUID().uuidString, uri: String = "", mimeType: String = "image/jpeg", name: String = "") {
        self.id = id
        self.uri = uri
        self.mimeType = mimeType
        self.name = name
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
    public var primaryColor: String?
    public var accentColor: String?

    public init(primaryColor: String? = nil, accentColor: String? = nil) {
        self.primaryColor = primaryColor
        self.accentColor = accentColor
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
        senderDeviceId: String = "iPhone 17",
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
