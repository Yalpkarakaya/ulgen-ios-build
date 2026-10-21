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
            ProjectRepository.shared.userProfile.fullName = name
            ProjectRepository.shared.saveLocalDataDirect()
            MqttSyncEngine.shared.start(email: email)
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
}
