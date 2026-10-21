import Foundation

/// 1:1 Cloudflare Worker KV REST API Service matching Android `CloudflareSyncService.kt`.
/// Backend URL: https://takip-backend.ulgennotes.workers.dev
public enum CloudflareSyncService {
    public static let baseURL = "https://takip-backend.ulgennotes.workers.dev"

    private static var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        return URLSession(configuration: config)
    }()

    // MARK: - Projects

    public static func pushProject(_ project: Project) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/project/\(project.id)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(project) else { return false }
        request.httpBody = data

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    public static func fetchProject(id: String) async -> Project? {
        guard let url = URL(string: "\(baseURL)/api/project/\(id)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await session.data(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                let decoder = JSONDecoder()
                return try? decoder.decode(Project.self, from: data)
            }
            return nil
        } catch {
            return nil
        }
    }

    public static func deleteProject(id: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/project/\(id)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Media

    public static func registerMedia(mediaItem: MediaItem) async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/media/register") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(mediaItem) else { return false }
        request.httpBody = data

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Admin & Storage

    public static func getStorageStats() async -> String? {
        guard let url = URL(string: "\(baseURL)/api/admin/storage-stats") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await session.data(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                return String(data: data, encoding: .utf8)
            }
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Usernames & Accounts

    public static func checkUsername(_ username: String) async -> (available: Bool, message: String) {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "@", with: "")
        guard !clean.isEmpty, let url = URL(string: "\(baseURL)/api/username/check?username=\(clean)") else {
            return (true, "Müsait")
        }

        do {
            let (data, resp) = try await session.data(from: url)
            if (resp as? HTTPURLResponse)?.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let available = json["available"] as? Bool ?? false
                let msg = json["message"] as? String ?? (available ? "Kullanıcı adı müsait" : "Bu kullanıcı adı alınmış")
                return (available, msg)
            }
            return (true, "Yerel modda onaylandı")
        } catch {
            return (true, "Çevrimdışı onay: \(error.localizedDescription)")
        }
    }

    public static func claimUsername(
        username: String,
        uid: String,
        email: String? = nil,
        displayName: String? = nil,
        avatarUrl: String? = nil
    ) async -> (success: Bool, message: String) {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "@", with: "")
        guard let url = URL(string: "\(baseURL)/api/username/claim") else {
            return (false, "Geçersiz URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        var dict: [String: Any] = [
            "username": clean,
            "uid": uid
        ]
        if let email = email, !email.isEmpty { dict["email"] = email }
        if let displayName = displayName, !displayName.isEmpty { dict["displayName"] = displayName }
        if let avatarUrl = avatarUrl, !avatarUrl.isEmpty { dict["avatarUrl"] = avatarUrl }

        guard let body = try? JSONSerialization.data(withJSONObject: dict) else {
            return (false, "Serileştirme hatası")
        }
        request.httpBody = body

        do {
            let (data, resp) = try await session.data(for: request)
            let isOk = (resp as? HTTPURLResponse)?.statusCode == 200
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let success = json["success"] as? Bool ?? isOk
                let msg = json["message"] as? String ?? (success ? "Kullanıcı adı başarıyla alındı" : "Hata oluştu")
                return (success, msg)
            }
            return (isOk, isOk ? "Başarılı" : "Sunucu hatası")
        } catch {
            return (true, "Çevrimdışı yerel kayıt")
        }
    }

    public static func lookupUsername(_ username: String) async -> RemoteUserProfile? {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "@", with: "")
        guard !clean.isEmpty, let url = URL(string: "\(baseURL)/api/username/lookup/\(clean)") else {
            return nil
        }

        do {
            let (data, resp) = try await session.data(from: url)
            if (resp as? HTTPURLResponse)?.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userDict = json["user"] as? [String: Any] {
                let userData = try JSONSerialization.data(withJSONObject: userDict)
                return try? JSONDecoder().decode(RemoteUserProfile.self, from: userData)
            }
            return nil
        } catch {
            return nil
        }
    }
}

public struct RemoteUserProfile: Codable, Hashable {
    public var username: String
    public var uid: String
    public var email: String?
    public var displayName: String?
    public var avatarUrl: String?
    public var updatedAt: String?

    public init(
        username: String = "",
        uid: String = "",
        email: String? = nil,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        updatedAt: String? = nil
    ) {
        self.username = username
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.updatedAt = updatedAt
    }
}
