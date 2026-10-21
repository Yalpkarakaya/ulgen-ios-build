import Foundation

/// 1:1 Parity Implementation of Android `com.ulgen.takip.data.sync.MergeEngine.kt`.
/// Handles Authoritative Convergence, Last-Write-Wins (LWW) conflict resolution,
/// tombstone tracking (preventing resurrection), and deep item/topic level merging.
public enum MergeEngine {

    /// Merges local and remote project collections respecting deleted item records (tombstones).
    public static func mergeProjects(
        localProjects: [Project],
        remoteProjects: [Project],
        tombstones: [DeletedItemRecord] = []
    ) -> [Project] {
        let tombstoneMap = Dictionary(
            tombstones.filter { !$0.id.isEmpty }.map { ($0.id, $0.deletedAt) },
            uniquingKeysWith: { max($0, $1) }
        )

        func isTombstoned(_ p: Project) -> Bool {
            if p.deleted || p.tombstone { return true }
            guard let delTime = tombstoneMap[p.id] else { return false }
            return p.lastUpdated <= delTime + 10_000 // 10 second tolerance
        }

        var mergedMap: [String: Project] = [:]

        for proj in localProjects {
            if !isTombstoned(proj) {
                mergedMap[proj.id] = proj
            }
        }

        for remote in remoteProjects {
            if !isTombstoned(remote) {
                if let local = mergedMap[remote.id] {
                    mergedMap[remote.id] = mergeSingleProject(local: local, remote: remote)
                } else {
                    mergedMap[remote.id] = sanitizeProjectTombstones(remote)
                }
            }
        }

        return Array(mergedMap.values).sorted {
            if $0.pinned != $1.pinned {
                return $0.pinned && !$1.pinned
            }
            return $0.lastUpdated > $1.lastUpdated
        }
    }

    /// Recursively sanitizes a project against its internal `deletedIds` tombstones.
    public static func sanitizeProjectTombstones(_ project: Project) -> Project {
        let tombstoneMap = Dictionary(
            project.deletedIds.filter { !$0.id.isEmpty }.map { ($0.id, $0.deletedAt) },
            uniquingKeysWith: { max($0, $1) }
        )

        var sanitized = project

        sanitized.mainTopics = project.mainTopics.compactMap { topic in
            if topic.deleted || topic.tombstone { return nil }
            if let delTime = tombstoneMap[topic.id], topic.lastUpdated <= delTime + 10_000 {
                return nil
            }

            var cleanTopic = topic
            cleanTopic.subTopics = topic.subTopics.compactMap { sub in
                if sub.deleted || sub.tombstone { return nil }
                if let delTime = tombstoneMap[sub.id], sub.lastUpdated <= delTime + 10_000 {
                    return nil
                }

                var cleanSub = sub
                cleanSub.items = sub.items.filter { item in
                    if item.deleted || item.tombstone { return false }
                    if let delTime = tombstoneMap[item.id], item.lastUpdated <= delTime + 10_000 {
                        return false
                    }
                    return true
                }
                return cleanSub
            }
            return cleanTopic
        }

        return sanitized
    }

    /// Performs a field-level and hierarchical Last-Write-Wins (LWW) merge between two versions of a project.
    public static func mergeSingleProject(local: Project, remote: Project) -> Project {
        // If one is deleted or tombstone, the newer deletion state wins
        if remote.deleted || remote.tombstone {
            if remote.lastUpdated >= local.lastUpdated {
                return remote
            }
        }
        if local.deleted || local.tombstone {
            if local.lastUpdated >= remote.lastUpdated {
                return local
            }
        }

        let isRemoteNewer = remote.lastUpdated >= local.lastUpdated
        let newer = isRemoteNewer ? remote : local
        let older = isRemoteNewer ? local : remote

        // Merge internal deleted IDs
        let mergedDeletedIds = mergeDeletedIds(local.deletedIds, remote.deletedIds)

        // Merge main topics recursively
        let mergedTopics = mergeMainTopics(
            localTopics: local.mainTopics,
            remoteTopics: remote.mainTopics,
            tombstones: mergedDeletedIds
        )

        // Merge media
        let mergedMedia = mergeMedia(localMedia: local.media, remoteMedia: remote.media)

        // Merge notes
        let mergedNotes = mergeNotes(localNotes: local.notes, remoteNotes: remote.notes)

        // Merge members
        let mergedMembers = mergeMembers(localMembers: local.members, remoteMembers: remote.members)

        // Construct converged project
        var result = Project(
            id: local.id,
            title: newer.title.isEmpty ? older.title : newer.title,
            description: newer.description.isEmpty ? older.description : newer.description,
            category: newer.category.isEmpty ? older.category : newer.category,
            priority: newer.priority.isEmpty ? older.priority : newer.priority,
            startDate: newer.startDate ?? older.startDate,
            deadline: newer.deadline ?? older.deadline,
            endDate: newer.endDate ?? older.endDate,
            createdDate: newer.createdDate ?? older.createdDate,
            knownTopics: newer.knownTopics.isEmpty ? older.knownTopics : newer.knownTopics,
            learningGoals: newer.learningGoals.isEmpty ? older.learningGoals : newer.learningGoals,
            resources: newer.resources.isEmpty ? older.resources : newer.resources,
            objectives: !newer.objectives.isEmpty ? newer.objectives : older.objectives,
            recommendedResources: !newer.recommendedResources.isEmpty ? newer.recommendedResources : older.recommendedResources,
            progress: newer.progress,
            estimatedHours: max(local.estimatedHours, remote.estimatedHours),
            estimatedMinutes: max(local.estimatedMinutes, remote.estimatedMinutes),
            mainTopics: mergedTopics,
            media: mergedMedia,
            notes: mergedNotes,
            customColors: newer.customColors ?? older.customColors,
            archived: newer.archived,
            deleted: false,
            tombstone: false,
            pinned: newer.pinned,
            shared: newer.shared || older.shared,
            shareEnabled: newer.shareEnabled || older.shareEnabled,
            shareCode: newer.shareCode ?? older.shareCode,
            sharedProjectId: newer.sharedProjectId ?? older.sharedProjectId,
            ownerId: newer.ownerId.isEmpty ? older.ownerId : newer.ownerId,
            driveFileId: newer.driveFileId ?? older.driveFileId,
            deletedIds: mergedDeletedIds,
            members: mergedMembers,
            chatSessions: !newer.chatSessions.isEmpty ? newer.chatSessions : older.chatSessions,
            createdAt: min(local.createdAt, remote.createdAt),
            lastUpdated: max(local.lastUpdated, remote.lastUpdated),
            completionDate: newer.completionDate ?? older.completionDate,
            completedAt: newer.completedAt ?? older.completedAt
        )

        // Recalculate progress based on converged tasks
        var total = 0
        var completed = 0
        for t in result.mainTopics {
            for s in t.subTopics {
                for i in s.items {
                    total += 1
                    if i.completed { completed += 1 }
                }
            }
        }
        result.progress = total > 0 ? Int((Double(completed) / Double(total)) * 100.0) : 0

        return result
    }

    public static func mergeDeletedIds(_ listA: [DeletedItemRecord], _ listB: [DeletedItemRecord]) -> [DeletedItemRecord] {
        var map: [String: Int64] = [:]
        for item in (listA + listB) where !item.id.isEmpty {
            map[item.id] = max(map[item.id] ?? 0, item.deletedAt)
        }
        return map.map { DeletedItemRecord(id: $0.key, deletedAt: $0.value) }
    }

    private static func mergeMainTopics(
        localTopics: [MainTopic],
        remoteTopics: [MainTopic],
        tombstones: [DeletedItemRecord]
    ) -> [MainTopic] {
        let tombstoneMap = Dictionary(tombstones.map { ($0.id, $0.deletedAt) }, uniquingKeysWith: { max($0, $1) })

        func isTombstoned(_ t: MainTopic) -> Bool {
            if t.deleted || t.tombstone { return true }
            guard let delTime = tombstoneMap[t.id] else { return false }
            return t.lastUpdated <= delTime + 10_000
        }

        var map: [String: MainTopic] = [:]

        for t in localTopics where !isTombstoned(t) {
            map[t.id] = t
        }

        for r in remoteTopics where !isTombstoned(r) {
            if let l = map[r.id] {
                let isRemoteNewer = r.lastUpdated >= l.lastUpdated
                let newer = isRemoteNewer ? r : l
                let older = isRemoteNewer ? l : r

                let mergedSubTopics = mergeSubTopics(
                    localSubs: l.subTopics,
                    remoteSubs: r.subTopics,
                    tombstones: tombstones
                )

                let mergedMedia = Array(Set(l.attachedMedia + r.attachedMedia))

                map[r.id] = MainTopic(
                    id: l.id,
                    title: newer.title.isEmpty ? older.title : newer.title,
                    description: newer.description.isEmpty ? older.description : newer.description,
                    estimatedHours: max(l.estimatedHours, r.estimatedHours),
                    estimatedMinutes: max(l.estimatedMinutes, r.estimatedMinutes),
                    subTopics: mergedSubTopics,
                    attachedMedia: mergedMedia,
                    aiEdited: newer.aiEdited || older.aiEdited,
                    deleted: false,
                    tombstone: false,
                    order: newer.order,
                    createdAt: min(l.createdAt, r.createdAt),
                    lastUpdated: max(l.lastUpdated, r.lastUpdated)
                )
            } else {
                map[r.id] = r
            }
        }

        return Array(map.values).sorted { $0.order < $1.order }
    }

    private static func mergeSubTopics(
        localSubs: [SubTopic],
        remoteSubs: [SubTopic],
        tombstones: [DeletedItemRecord]
    ) -> [SubTopic] {
        let tombstoneMap = Dictionary(tombstones.map { ($0.id, $0.deletedAt) }, uniquingKeysWith: { max($0, $1) })

        func isTombstoned(_ s: SubTopic) -> Bool {
            if s.deleted || s.tombstone { return true }
            guard let delTime = tombstoneMap[s.id] else { return false }
            return s.lastUpdated <= delTime + 10_000
        }

        var map: [String: SubTopic] = [:]

        for s in localSubs where !isTombstoned(s) {
            map[s.id] = s
        }

        for r in remoteSubs where !isTombstoned(r) {
            if let l = map[r.id] {
                let isRemoteNewer = r.lastUpdated >= l.lastUpdated
                let newer = isRemoteNewer ? r : l
                let older = isRemoteNewer ? l : r

                let mergedItems = mergeItems(
                    localItems: l.items,
                    remoteItems: r.items,
                    tombstones: tombstones
                )

                let mergedMedia = mergeMedia(localMedia: l.media, remoteMedia: r.media)
                let mergedNotes = mergeNotes(localNotes: l.notes, remoteNotes: r.notes)
                let mergedAttached = Array(Set(l.attachedMedia + r.attachedMedia))

                map[r.id] = SubTopic(
                    id: l.id,
                    title: newer.title.isEmpty ? older.title : newer.title,
                    description: newer.description.isEmpty ? older.description : newer.description,
                    completed: newer.completed,
                    autoCompleted: newer.autoCompleted,
                    completionDate: newer.completionDate ?? older.completionDate,
                    estimatedHours: max(l.estimatedHours, r.estimatedHours),
                    estimatedMinutes: max(l.estimatedMinutes, r.estimatedMinutes),
                    items: mergedItems,
                    notes: mergedNotes,
                    media: mergedMedia,
                    attachedMedia: mergedAttached,
                    deleted: false,
                    tombstone: false,
                    order: newer.order,
                    createdAt: min(l.createdAt, r.createdAt),
                    lastUpdated: max(l.lastUpdated, r.lastUpdated)
                )
            } else {
                map[r.id] = r
            }
        }

        return Array(map.values).sorted { $0.order < $1.order }
    }

    private static func mergeItems(
        localItems: [Item],
        remoteItems: [Item],
        tombstones: [DeletedItemRecord]
    ) -> [Item] {
        let tombstoneMap = Dictionary(tombstones.map { ($0.id, $0.deletedAt) }, uniquingKeysWith: { max($0, $1) })

        func isTombstoned(_ i: Item) -> Bool {
            if i.deleted || i.tombstone { return true }
            guard let delTime = tombstoneMap[i.id] else { return false }
            return i.lastUpdated <= delTime + 10_000
        }

        var map: [String: Item] = [:]

        for i in localItems where !isTombstoned(i) {
            map[i.id] = i
        }

        for r in remoteItems where !isTombstoned(r) {
            if let l = map[r.id] {
                let isRemoteNewer = r.lastUpdated >= l.lastUpdated
                let newer = isRemoteNewer ? r : l
                let older = isRemoteNewer ? l : r

                let mergedAttached = Array(Set(l.attachedMedia + r.attachedMedia))

                map[r.id] = Item(
                    id: l.id,
                    title: newer.title.isEmpty ? older.title : newer.title,
                    description: newer.description.isEmpty ? older.description : newer.description,
                    estimatedHours: max(l.estimatedHours, r.estimatedHours),
                    estimatedMinutes: max(l.estimatedMinutes, r.estimatedMinutes),
                    completed: newer.completed,
                    autoCompleted: newer.autoCompleted,
                    completionDate: newer.completionDate ?? older.completionDate,
                    notes: newer.notes.isEmpty ? older.notes : newer.notes,
                    attachedMedia: mergedAttached,
                    quantity: max(1, newer.quantity), // Authoritative latest counter!
                    deleted: false,
                    tombstone: false,
                    order: newer.order,
                    lastUpdated: max(l.lastUpdated, r.lastUpdated)
                )
            } else {
                map[r.id] = r
            }
        }

        return Array(map.values).sorted { $0.order < $1.order }
    }

    private static func mergeMedia(localMedia: [MediaItem], remoteMedia: [MediaItem]) -> [MediaItem] {
        var map: [String: MediaItem] = [:]
        for m in localMedia {
            map[m.id] = m
        }
        for r in remoteMedia {
            if let l = map[r.id] {
                // Keep the one with valid driveFileId or latest data
                var converged = r
                if (converged.driveFileId?.isEmpty ?? true) && !(l.driveFileId?.isEmpty ?? true) {
                    converged.driveFileId = l.driveFileId
                }
                if (converged.base64Data?.isEmpty ?? true) && !(l.base64Data?.isEmpty ?? true) {
                    converged.base64Data = l.base64Data
                }
                map[r.id] = converged
            } else {
                map[r.id] = r
            }
        }
        return Array(map.values)
    }

    private static func mergeNotes(localNotes: [Note], remoteNotes: [Note]) -> [Note] {
        var map: [String: Note] = [:]
        for n in (localNotes + remoteNotes) {
            if let existing = map[n.id] {
                map[n.id] = existing.createdAt >= n.createdAt ? existing : n
            } else {
                map[n.id] = n
            }
        }
        return Array(map.values).sorted { $0.createdAt > $1.createdAt }
    }

    private static func mergeMembers(localMembers: [ProjectMember], remoteMembers: [ProjectMember]) -> [ProjectMember] {
        var map: [String: ProjectMember] = [:]
        for m in (localMembers + remoteMembers) {
            let key = m.email.isEmpty ? m.id : m.email
            map[key] = m
        }
        return Array(map.values)
    }
}
