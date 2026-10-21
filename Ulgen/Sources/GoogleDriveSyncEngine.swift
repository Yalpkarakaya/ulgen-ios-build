import Foundation

/// 1:1 Google Drive REST API v3 Visible Hierarchy Sync Engine matching Android `GoogleDriveSyncEngine.kt`.
/// Uses visible user Drive hierarchy:
/// Ülgen Takip/
///   ├── Ülgen Takip - Tüm Sistem Yedeği.json (Ana sistem yedeği)
///   ├── <Proje Başlığı>/ (Her projenin kendi ana klasörü)
///   │     ├── <Proje Başlığı> - Proje Yedeği.json
///   │     ├── Medyalar/
///   │     └── Yedekler/
///   └── Paylaşılan Projeler/
public class GoogleDriveSyncEngine: ObservableObject {
    public static let shared = GoogleDriveSyncEngine()

    public static let defaultFileName = "takip_data.json"
    public static let visibleMasterBackupName = "Ülgen Takip - Tüm Sistem Yedeği.json"
    public static let driveFilesApi = "https://www.googleapis.com/drive/v3/files"
    public static let driveUploadApi = "https://www.googleapis.com/upload/drive/v3/files"
    public static let driveAboutApi = "https://www.googleapis.com/drive/v3/about?fields=user"
    public static let folderMime = "application/vnd.google-apps.folder"

    public static let rootFolderName = "Ülgen Takip"
    public static let projectMediaSubfolderName = "Medyalar"
    public static let projectBackupsSubfolderName = "Yedekler"
    public static let sharedProjectsFolderName = "Paylaşılan Projeler"

    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTimestamp: Date? = nil
    @Published public var userEmail: String = ""

    public var isAuthorized: Bool {
        guard let token = accessToken else { return false }
        return !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var isAuthenticated: Bool {
        return isAuthorized
    }

    private var accessToken: String? = nil
    private let session = URLSession(configuration: .default)

    public init() {
        if let savedToken = UserDefaults.standard.string(forKey: "ulgen_google_access_token"), !savedToken.isEmpty {
            self.accessToken = savedToken
        }
        if let savedEmail = UserDefaults.standard.string(forKey: "ulgen_google_user_email"), !savedEmail.isEmpty {
            self.userEmail = savedEmail
        }
    }

    public struct DriveFileItem: Codable, Identifiable {
        public var id: String
        public var name: String
        public var size: String?
        public var modifiedTime: String?
        public var createdTime: String?
        public var mimeType: String?
        public var parents: [String]?
        public var trashed: Bool?
    }

    public struct DriveFileListResponse: Codable {
        public var files: [DriveFileItem]?
        public var nextPageToken: String?
    }

    public struct DriveMasterPayload: Codable {
        public var projects: [Project]
        public var deletedProjectIds: [DeletedItemRecord]
        public var timestamp: Int64

        public init(projects: [Project], deletedProjectIds: [DeletedItemRecord], timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
            self.projects = projects
            self.deletedProjectIds = deletedProjectIds
            self.timestamp = timestamp
        }
    }

    public func setAccessToken(_ token: String) {
        let clean = token.trimmingCharacters(in: .whitespacesAndNewlines)
        self.accessToken = clean
        UserDefaults.standard.set(clean, forKey: "ulgen_google_access_token")
    }

    public func signOut() {
        self.accessToken = nil
        self.userEmail = ""
        UserDefaults.standard.removeObject(forKey: "ulgen_google_access_token")
        UserDefaults.standard.removeObject(forKey: "ulgen_google_user_email")
        MqttSyncEngine.shared.disconnect()
        MqttSyncEngine.shared.userEmail = ""
        ProjectRepository.shared.userProfile.email = ""
        ProjectRepository.shared.saveLocalDataDirect()
    }

    public func verifyAndSaveToken(_ token: String) async throws -> (email: String, name: String) {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty, let url = URL(string: Self.driveAboutApi) else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz yetkilendirme belirteci"])
        }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await session.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "GoogleDriveSyncEngine", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Google Drive API doğrulaması başarısız (HTTP \(statusCode)). Belirteç geçersiz veya süresi dolmuş."])
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userObj = json["user"] as? [String: Any] else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı profili çözümlenemedi."])
        }

        let email = (userObj["emailAddress"] as? String) ?? "kullanici@ulgen.app"
        let name = (userObj["displayName"] as? String) ?? "Ülgen Mühendisi"

        DispatchQueue.main.async {
            self.setAccessToken(cleanToken)
            self.userEmail = email
            UserDefaults.standard.set(email, forKey: "ulgen_google_user_email")
            ProjectRepository.shared.userProfile.email = email
            ProjectRepository.shared.userProfile.displayName = name
            ProjectRepository.shared.saveLocalDataDirect()
            MqttSyncEngine.shared.userEmail = email
        }

        return (email, name)
    }

    public func syncNow() async throws {
        guard isAuthorized else { return }
        DispatchQueue.main.async { self.isSyncing = true }
        defer {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.lastSyncTimestamp = Date()
            }
        }

        if let remote = try await fetchMasterBackup() {
            DispatchQueue.main.async {
                for p in remote.projects {
                    ProjectRepository.shared.mergeIncomingProject(p)
                }
            }
        }

        _ = try await pushMasterBackup(
            projects: ProjectRepository.shared.projects,
            deleted: ProjectRepository.shared.deletedProjectIds
        )
    }

    // MARK: - Root & Folder Management

    public func ensureRootFolder() async throws -> String {
        guard let token = accessToken, !token.isEmpty else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 401, userInfo: [NSLocalizedDescriptionKey: "Yetkilendirme jetonu bulunamadı"])
        }

        // Query for existing folder
        let q = "mimeType = '\(Self.folderMime)' and name = '\(Self.rootFolderName)' and trashed = false and 'root' in parents"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name)&spaces=drive") else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz arama URL'si"])
        }

        var req = URLRequest(url: queryURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await session.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 200,
           let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: data),
           let first = list.files?.first {
            return first.id
        }

        // Create folder if not found
        guard let createURL = URL(string: Self.driveFilesApi) else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz oluşturma URL'si"])
        }

        var createReq = URLRequest(url: createURL)
        createReq.httpMethod = "POST"
        createReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createReq.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "name": Self.rootFolderName,
            "mimeType": Self.folderMime,
            "parents": ["root"]
        ]
        createReq.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (cData, cResp) = try await session.data(for: createReq)
        if (cResp as? HTTPURLResponse)?.statusCode == 200 || (cResp as? HTTPURLResponse)?.statusCode == 201,
           let created = try? JSONDecoder().decode(DriveFileItem.self, from: cData) {
            return created.id
        }

        throw NSError(domain: "GoogleDriveSyncEngine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Kök klasör oluşturulamadı"])
    }

    // MARK: - Master Backup Sync (1:1 with VISIBLE_MASTER_BACKUP_NAME)

    public func pushMasterBackup(projects: [Project], deleted: [DeletedItemRecord]) async throws -> Bool {
        guard let token = accessToken, !token.isEmpty else { return false }
        let rootFolderId = try await ensureRootFolder()

        let payload = DriveMasterPayload(projects: projects, deletedProjectIds: deleted)
        let jsonData = try JSONEncoder().encode(payload)

        // Find existing master file in root folder
        let q = "name = '\(Self.visibleMasterBackupName)' and '\(rootFolderId)' in parents and trashed = false"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name)") else {
            return false
        }

        var searchReq = URLRequest(url: queryURL)
        searchReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (sData, _) = try await session.data(for: searchReq)
        let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: sData)
        let existingId = list?.files?.first?.id

        if let fileId = existingId {
            // Update existing file content
            guard let updateURL = URL(string: "\(Self.driveUploadApi)/\(fileId)?uploadType=media") else { return false }
            var upReq = URLRequest(url: updateURL)
            upReq.httpMethod = "PATCH"
            upReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            upReq.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            upReq.httpBody = jsonData

            let (_, uResp) = try await session.data(for: upReq)
            return (uResp as? HTTPURLResponse)?.statusCode == 200
        } else {
            // Multipart create
            let boundary = "-------UlgenBoundary\(UUID().uuidString)"
            guard let uploadURL = URL(string: "\(Self.driveUploadApi)?uploadType=multipart") else { return false }

            var postReq = URLRequest(url: uploadURL)
            postReq.httpMethod = "POST"
            postReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            postReq.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            let metadataJson = "{\"name\":\"\(Self.visibleMasterBackupName)\",\"parents\":[\"\(rootFolderId)\"]}"

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
            body.append("\(metadataJson)\r\n".data(using: .utf8)!)

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            body.append(jsonData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            postReq.httpBody = body
            let (_, pResp) = try await session.data(for: postReq)
            return (pResp as? HTTPURLResponse)?.statusCode == 200
        }
    }

    public func fetchMasterBackup() async throws -> (projects: [Project], deleted: [DeletedItemRecord])? {
        guard let token = accessToken, !token.isEmpty else { return nil }
        let rootFolderId = try await ensureRootFolder()

        let q = "name = '\(Self.visibleMasterBackupName)' and '\(rootFolderId)' in parents and trashed = false"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name)") else {
            return nil
        }

        var searchReq = URLRequest(url: queryURL)
        searchReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (sData, _) = try await session.data(for: searchReq)
        guard let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: sData),
              let fileId = list.files?.first?.id else {
            return nil
        }

        guard let downloadURL = URL(string: "\(Self.driveFilesApi)/\(fileId)?alt=media") else { return nil }
        var dlReq = URLRequest(url: downloadURL)
        dlReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (dlData, dlResp) = try await session.data(for: dlReq)
        if (dlResp as? HTTPURLResponse)?.statusCode == 200 {
            if let payload = try? JSONDecoder().decode(DriveMasterPayload.self, from: dlData) {
                return (payload.projects, payload.deletedProjectIds)
            }
        }
        return nil
    }

    // MARK: - Visible Tree Hierarchy & Subfolder Management (1:1 Android)

    private var folderCache: [String: String] = [:]

    public func sanitizeDriveFolderName(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Genel Proje" : String(cleaned.prefix(80))
    }

    public func sanitizeDriveFileName(_ raw: String, fallback: String = "dosya") -> String {
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? fallback : cleaned
    }

    public func ensureProjectFolder(projectId: String, projectTitle: String) async throws -> String {
        if let cached = folderCache["proj_\(projectId)"], !cached.isEmpty {
            return cached
        }

        guard let token = accessToken, !token.isEmpty else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 401, userInfo: [NSLocalizedDescriptionKey: "Yetkilendirme jetonu bulunamadı"])
        }

        let rootFolderId = try await ensureRootFolder()
        let cleanTitle = sanitizeDriveFolderName(projectTitle)

        // Query for existing project folder inside root
        let q = "mimeType = '\(Self.folderMime)' and name = '\(cleanTitle)' and '\(rootFolderId)' in parents and trashed = false"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name)&spaces=drive") else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz arama URL'si"])
        }

        var req = URLRequest(url: queryURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await session.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 200,
           let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: data),
           let first = list.files?.first {
            folderCache["proj_\(projectId)"] = first.id
            return first.id
        }

        // Create project folder inside root
        guard let createURL = URL(string: Self.driveFilesApi) else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz oluşturma URL'si"])
        }

        var createReq = URLRequest(url: createURL)
        createReq.httpMethod = "POST"
        createReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createReq.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "name": cleanTitle,
            "mimeType": Self.folderMime,
            "parents": [rootFolderId],
            "appProperties": [
                "ulgenRole": "project_root",
                "ulgenProjectId": projectId
            ]
        ]
        createReq.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (cData, cResp) = try await session.data(for: createReq)
        if (cResp as? HTTPURLResponse)?.statusCode == 200 || (cResp as? HTTPURLResponse)?.statusCode == 201,
           let created = try? JSONDecoder().decode(DriveFileItem.self, from: cData) {
            folderCache["proj_\(projectId)"] = created.id
            return created.id
        }

        throw NSError(domain: "GoogleDriveSyncEngine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Proje klasörü oluşturulamadı"])
    }

    public func ensureProjectMediaFolder(projectId: String, projectTitle: String) async throws -> String {
        if let cached = folderCache["media_\(projectId)"], !cached.isEmpty {
            return cached
        }

        guard let token = accessToken, !token.isEmpty else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 401, userInfo: [NSLocalizedDescriptionKey: "Yetkilendirme jetonu bulunamadı"])
        }

        let projectFolderId = try await ensureProjectFolder(projectId: projectId, projectTitle: projectTitle)

        // Query for existing Medyalar subfolder inside projectFolderId
        let q = "mimeType = '\(Self.folderMime)' and name = '\(Self.projectMediaSubfolderName)' and '\(projectFolderId)' in parents and trashed = false"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name)&spaces=drive") else {
            return projectFolderId
        }

        var req = URLRequest(url: queryURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await session.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 200,
           let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: data),
           let first = list.files?.first {
            folderCache["media_\(projectId)"] = first.id
            return first.id
        }

        // Create Medyalar subfolder
        guard let createURL = URL(string: Self.driveFilesApi) else { return projectFolderId }
        var createReq = URLRequest(url: createURL)
        createReq.httpMethod = "POST"
        createReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createReq.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "name": Self.projectMediaSubfolderName,
            "mimeType": Self.folderMime,
            "parents": [projectFolderId]
        ]
        createReq.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (cData, cResp) = try await session.data(for: createReq)
        if (cResp as? HTTPURLResponse)?.statusCode == 200 || (cResp as? HTTPURLResponse)?.statusCode == 201,
           let created = try? JSONDecoder().decode(DriveFileItem.self, from: cData) {
            folderCache["media_\(projectId)"] = created.id
            return created.id
        }

        return projectFolderId
    }

    public func ensureProjectBackupsFolder(projectId: String, projectTitle: String) async throws -> String {
        if let cached = folderCache["backups_\(projectId)"], !cached.isEmpty {
            return cached
        }

        guard let token = accessToken, !token.isEmpty else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 401, userInfo: [NSLocalizedDescriptionKey: "Yetkilendirme jetonu bulunamadı"])
        }

        let projectFolderId = try await ensureProjectFolder(projectId: projectId, projectTitle: projectTitle)

        // Query for existing Yedekler subfolder
        let q = "mimeType = '\(Self.folderMime)' and name = '\(Self.projectBackupsSubfolderName)' and '\(projectFolderId)' in parents and trashed = false"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name)&spaces=drive") else {
            return projectFolderId
        }

        var req = URLRequest(url: queryURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await session.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 200,
           let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: data),
           let first = list.files?.first {
            folderCache["backups_\(projectId)"] = first.id
            return first.id
        }

        // Create Yedekler subfolder
        guard let createURL = URL(string: Self.driveFilesApi) else { return projectFolderId }
        var createReq = URLRequest(url: createURL)
        createReq.httpMethod = "POST"
        createReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createReq.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = [
            "name": Self.projectBackupsSubfolderName,
            "mimeType": Self.folderMime,
            "parents": [projectFolderId]
        ]
        createReq.httpBody = try JSONSerialization.data(withJSONObject: metadata)

        let (cData, cResp) = try await session.data(for: createReq)
        if (cResp as? HTTPURLResponse)?.statusCode == 200 || (cResp as? HTTPURLResponse)?.statusCode == 201,
           let created = try? JSONDecoder().decode(DriveFileItem.self, from: cData) {
            folderCache["backups_\(projectId)"] = created.id
            return created.id
        }

        return projectFolderId
    }

    /// Syncs single project visible hierarchy: `Ülgen Takip / <Proje Başlığı> / <Proje Başlığı> - Proje Yedeği.json`
    public func syncSingleProjectTreeToDrive(project: Project) async throws -> String {
        guard let token = accessToken, !token.isEmpty, !project.deleted else {
            return ""
        }

        let projectFolderId = try await ensureProjectFolder(projectId: project.id, projectTitle: project.title)
        _ = try? await ensureProjectMediaFolder(projectId: project.id, projectTitle: project.title)
        _ = try? await ensureProjectBackupsFolder(projectId: project.id, projectTitle: project.title)

        let cleanTitle = sanitizeDriveFolderName(project.title)
        let fileName = sanitizeDriveFileName("\(cleanTitle) - Proje Yedeği.json")
        let jsonData = try JSONEncoder().encode(project)

        // Query for existing project backup file inside projectFolderId
        let q = "'\(projectFolderId)' in parents and trashed = false and (name = '\(fileName)' or appProperties has { key='ulgenRole' and value='project_main_json' })"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name)") else {
            return projectFolderId
        }

        var searchReq = URLRequest(url: queryURL)
        searchReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (sData, _) = try await session.data(for: searchReq)
        let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: sData)
        let existingId = list?.files?.first?.id

        if let fileId = existingId {
            guard let updateURL = URL(string: "\(Self.driveUploadApi)/\(fileId)?uploadType=media") else { return projectFolderId }
            var upReq = URLRequest(url: updateURL)
            upReq.httpMethod = "PATCH"
            upReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            upReq.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            upReq.httpBody = jsonData
            _ = try await session.data(for: upReq)
        } else {
            let boundary = "-------proj_\(UUID().uuidString)"
            guard let uploadURL = URL(string: "\(Self.driveUploadApi)?uploadType=multipart") else { return projectFolderId }

            var postReq = URLRequest(url: uploadURL)
            postReq.httpMethod = "POST"
            postReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            postReq.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            let metadataJson = "{\"name\":\"\(fileName)\",\"parents\":[\"\(projectFolderId)\"],\"appProperties\":{\"ulgenRole\":\"project_main_json\",\"ulgenProjectId\":\"\(project.id)\"}}"

            body.append("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n\(metadataJson)\r\n".data(using: .utf8)!)
            body.append("--\(boundary)\r\nContent-Type: application/json\r\n\r\n".data(using: .utf8)!)
            body.append(jsonData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            postReq.httpBody = body
            _ = try await session.data(for: postReq)
        }

        return projectFolderId
    }

    /// Uploads media binary into `Ülgen Takip / <Proje Başlığı> / Medyalar/`
    public func uploadMediaBinaryToDrive(
        mediaId: String,
        fileData: Data,
        mimeType: String,
        originalFileName: String,
        projectId: String,
        projectTitle: String
    ) async throws -> String {
        guard let token = accessToken, !token.isEmpty, !fileData.isEmpty else { return "" }

        let mediaFolderId = try await ensureProjectMediaFolder(projectId: projectId, projectTitle: projectTitle)
        let safeName = sanitizeDriveFileName(originalFileName, fallback: "medya_\(mediaId.prefix(6)).jpg")

        let boundary = "-------media_\(UUID().uuidString)"
        guard let uploadURL = URL(string: "\(Self.driveUploadApi)?uploadType=multipart") else { return "" }

        var postReq = URLRequest(url: uploadURL)
        postReq.httpMethod = "POST"
        postReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        postReq.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let metadataJson = "{\"name\":\"\(safeName)\",\"parents\":[\"\(mediaFolderId)\"],\"appProperties\":{\"ulgenRole\":\"media\",\"ulgenProjectId\":\"\(projectId)\",\"ulgenMediaId\":\"\(mediaId)\"}}"

        body.append("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n\(metadataJson)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        postReq.httpBody = body
        let (pData, pResp) = try await session.data(for: postReq)
        if (pResp as? HTTPURLResponse)?.statusCode == 200 || (pResp as? HTTPURLResponse)?.statusCode == 201,
           let created = try? JSONDecoder().decode(DriveFileItem.self, from: pData) {
            return created.id
        }

        return ""
    }

    /// Downloads media binary directly from Google Drive
    public func downloadMediaBinaryFromDrive(driveFileId: String) async throws -> Data {
        guard let token = accessToken, !token.isEmpty, !driveFileId.isEmpty else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz Drive dosya kimliği"])
        }

        guard let downloadURL = URL(string: "\(Self.driveFilesApi)/\(driveFileId)?alt=media") else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz indirme URL'si"])
        }

        var dlReq = URLRequest(url: downloadURL)
        dlReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (dlData, dlResp) = try await session.data(for: dlReq)
        guard let httpResp = dlResp as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw NSError(domain: "GoogleDriveSyncEngine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Medya Drive'dan indirilemedi"])
        }

        return dlData
    }

    /// Permanently deletes a file from Google Drive (e.g., when user deletes a media item or backup)
    public func deleteDriveFile(fileId: String) async throws -> Bool {
        let cleanId = fileId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let token = accessToken, !token.isEmpty, !cleanId.isEmpty, cleanId != "local" else {
            return false
        }

        guard let deleteURL = URL(string: "\(Self.driveFilesApi)/\(cleanId)") else { return false }
        var delReq = URLRequest(url: deleteURL)
        delReq.httpMethod = "DELETE"
        delReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, delResp) = try await session.data(for: delReq)
        let status = (delResp as? HTTPURLResponse)?.statusCode ?? 500
        return status >= 200 && status < 300 || status == 404
    }

    /// Uploads a snapshot backup to `Ülgen Takip / <Proje Başlığı> / Yedekler/`
    public func uploadProjectBackupSnapshotToDrive(
        project: Project,
        reason: String,
        pool: String = "manual"
    ) async throws -> String {
        guard let token = accessToken, !token.isEmpty, !project.deleted else { return "" }

        let backupsFolderId = try await ensureProjectBackupsFolder(projectId: project.id, projectTitle: project.title)
        let cleanTitle = sanitizeDriveFolderName(project.title)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateStr = formatter.string(from: Date())
        let typeTag = pool == "manual" ? "Manuel" : "Otomatik"
        let fileName = sanitizeDriveFileName("\(cleanTitle)_\(typeTag)_Yedek_\(dateStr).json")

        let jsonData = try JSONEncoder().encode(project)
        let boundary = "-------snap_\(UUID().uuidString)"
        guard let uploadURL = URL(string: "\(Self.driveUploadApi)?uploadType=multipart") else { return "" }

        var postReq = URLRequest(url: uploadURL)
        postReq.httpMethod = "POST"
        postReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        postReq.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let metadataJson = "{\"name\":\"\(fileName)\",\"parents\":[\"\(backupsFolderId)\"],\"description\":\"Ülgen Takip Proje Yedeği (\(reason))\",\"appProperties\":{\"ulgenRole\":\"project_snapshot_backup\",\"ulgenProjectId\":\"\(project.id)\",\"ulgenPool\":\"\(pool)\"}}"

        body.append("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n\(metadataJson)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        postReq.httpBody = body
        let (pData, pResp) = try await session.data(for: postReq)
        if (pResp as? HTTPURLResponse)?.statusCode == 200 || (pResp as? HTTPURLResponse)?.statusCode == 201,
           let created = try? JSONDecoder().decode(DriveFileItem.self, from: pData) {
            return created.id
        }

        return ""
    }

    /// Lists backup snapshots from `Ülgen Takip / <Proje Başlığı> / Yedekler/`
    public func listProjectBackups(projectId: String, projectTitle: String) async throws -> [DriveFileItem] {
        guard let token = accessToken, !token.isEmpty else { return [] }

        let backupsFolderId = try await ensureProjectBackupsFolder(projectId: projectId, projectTitle: projectTitle)
        let q = "'\(backupsFolderId)' in parents and trashed = false and mimeType != '\(Self.folderMime)'"
        guard let encodedQ = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let queryURL = URL(string: "\(Self.driveFilesApi)?q=\(encodedQ)&fields=files(id,name,size,modifiedTime)&spaces=drive") else {
            return []
        }

        var req = URLRequest(url: queryURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await session.data(for: req)
        if (resp as? HTTPURLResponse)?.statusCode == 200,
           let list = try? JSONDecoder().decode(DriveFileListResponse.self, from: data) {
            return list.files ?? []
        }

        return []
    }
}
