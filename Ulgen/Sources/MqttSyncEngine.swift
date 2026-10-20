import Foundation
import CryptoKit

public class MqttSyncEngine: ObservableObject {
    public static let shared = MqttSyncEngine()

    @Published public var isConnected: Bool = false
    @Published public var userEmail: String = "" {
        didSet {
            UserDefaults.standard.set(userEmail, forKey: "ulgen_sync_email")
            subscribeToAccountChannel()
        }
    }
    @Published public var lastSyncTimestamp: Date? = nil

    private let deviceId: String = "iPhone 17"
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)

    public init() {
        self.userEmail = UserDefaults.standard.string(forKey: "ulgen_sync_email") ?? ""
        if !userEmail.isEmpty {
            subscribeToAccountChannel()
        }
    }

    public func sha256(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else { return "" }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        self.isConnected = false
    }

    public func subscribeToAccountChannel() {
        guard !userEmail.isEmpty else { return }
        let hash = sha256(userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        let topic = "ulgen/account/\(hash)"
        print("[MqttSyncEngine] Subscribing to topic: \(topic)")

        // WebSocket MQTT connection to HiveMQ
        connectWebSocket(topic: topic)
    }

    private func connectWebSocket(topic: String) {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)

        // HiveMQ Public WSS endpoint
        guard let url = URL(string: "wss://broker.hivemq.com:8884/mqtt") else { return }
        let request = URLRequest(url: url)
        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        self.isConnected = true
        self.lastSyncTimestamp = Date()
        listenMessages()
    }

    private func listenMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingMessage(text)
                    }
                @unknown default:
                    break
                }
                self.listenMessages()
            case .failure(let error):
                print("[MqttSyncEngine] WebSocket error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            }
        }
    }

    private func handleIncomingMessage(_ payload: String) {
        guard let data = payload.data(using: .utf8),
              let event = try? JSONDecoder().decode(AccountSyncEvent.self, from: data) else {
            return
        }

        // Echo Suppression: Kendi ürettiğimiz paketi reddet
        guard event.senderDeviceId != self.deviceId else { return }

        DispatchQueue.main.async {
            self.lastSyncTimestamp = Date()

            if event.eventType == "PROJECT_DELETE", let pId = event.projectId {
                ProjectRepository.shared.deleteProject(id: pId)
            } else if let projectJson = event.projectJson,
                      let pData = projectJson.data(using: .utf8),
                      let incomingProject = try? JSONDecoder().decode(Project.self, from: pData) {
                // LWW (Last-Write-Wins): Eğer yerel son değişiklikten eskiyse ezme
                if let existing = ProjectRepository.shared.projects.first(where: { $0.id == incomingProject.id }) {
                    if incomingProject.lastUpdated > existing.lastUpdated {
                        ProjectRepository.shared.updateProject(incomingProject)
                    }
                } else {
                    ProjectRepository.shared.projects.insert(incomingProject, at: 0)
                    ProjectRepository.shared.saveLocalData()
                }
            }
        }
    }

    public func publishProjectChange(_ project: Project) {
        guard let pData = try? JSONEncoder().encode(project),
              let pJson = String(data: pData, encoding: .utf8) else { return }

        let event = AccountSyncEvent(
            senderDeviceId: self.deviceId,
            eventType: "PROJECT_UPSERT",
            projectId: project.id,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            projectJson: pJson
        )

        sendEvent(event)
    }

    public func publishProjectDelete(id: String) {
        let event = AccountSyncEvent(
            senderDeviceId: self.deviceId,
            eventType: "PROJECT_DELETE",
            projectId: id,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        sendEvent(event)
    }

    private func sendEvent(_ event: AccountSyncEvent) {
        guard let data = try? JSONEncoder().encode(event),
              let jsonStr = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(jsonStr)) { error in
            if let error = error {
                print("[MqttSyncEngine] Send error: \(error.localizedDescription)")
            }
        }
    }
}
