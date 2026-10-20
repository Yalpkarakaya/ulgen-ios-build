import Foundation
import Network
import CryptoKit

/// Production MQTT 3.1.1 Real-Time Synchronization Engine over TCP (`tcp://broker.hivemq.com:1883`)
/// Provides 1:1 parity with Android `MqttSyncEngine.kt`.
public class MqttSyncEngine: ObservableObject {
    public static let shared = MqttSyncEngine()

    @Published public var isConnected: Bool = false
    @Published public var lastSyncTimestamp: Date? = nil
    @Published public var userEmail: String = "" {
        didSet {
            UserDefaults.standard.set(userEmail, forKey: "ulgen_sync_email")
            subscribeToAccountChannel()
        }
    }

    public let deviceId: String
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.ulgen.mqtt", qos: .userInitiated)
    private var pingTimer: Timer?
    private var currentTopic: String?
    private var isConnecting: Bool = false
    private var reconnectWorkItem: DispatchWorkItem?

    public init() {
        // Persistent unique device identifier (Zero Hardcoding)
        if let savedDevId = UserDefaults.standard.string(forKey: "ulgen_device_id"), !savedDevId.isEmpty {
            self.deviceId = savedDevId
        } else {
            let newId = "ios_" + UUID().uuidString.prefix(8)
            UserDefaults.standard.set(String(newId), forKey: "ulgen_device_id")
            self.deviceId = String(newId)
        }

        self.userEmail = UserDefaults.standard.string(forKey: "ulgen_sync_email") ?? ""
        if !userEmail.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.subscribeToAccountChannel()
            }
        }
    }

    public static func sha256Hex(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else { return "" }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public func disconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        pingTimer?.invalidate()
        pingTimer = nil
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }

    public func subscribeToAccountChannel() {
        let clean = userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else {
            disconnect()
            return
        }

        // Android 1:1 Parity: val hash = sha256(clean).take(24)
        let fullHash = Self.sha256Hex(clean)
        let hash24 = String(fullHash.prefix(24))
        let topic = "ulgen/account/\(hash24)"
        self.currentTopic = topic

        connectAndSubscribe(topic: topic)
    }

    private func connectAndSubscribe(topic: String) {
        guard !isConnecting else { return }
        disconnect()

        isConnecting = true
        let host = NWEndpoint.Host("broker.hivemq.com")
        let port = NWEndpoint.Port(rawValue: 1883)!
        let conn = NWConnection(host: host, port: port, using: .tcp)
        self.connection = conn

        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isConnecting = false
                self.sendConnectPacket()
                self.startReceiving()
            case .failed(let error):
                print("[MqttSyncEngine] Connection failed: \(error)")
                self.isConnecting = false
                self.scheduleReconnect()
            case .cancelled:
                self.isConnecting = false
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            default:
                break
            }
        }

        conn.start(queue: queue)
    }

    private func scheduleReconnect() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        reconnectWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.userEmail.isEmpty else { return }
            self.subscribeToAccountChannel()
        }
        reconnectWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 5.0, execute: workItem)
    }

    // MARK: - MQTT 3.1.1 Packet Framing

    private func sendConnectPacket() {
        var varHeader: [UInt8] = [
            0x00, 0x04, 0x4D, 0x51, 0x54, 0x54, // Protocol Name: "MQTT"
            0x04,                               // Protocol Level: 4 (MQTT 3.1.1)
            0x02,                               // Connect Flags: Clean Session
            0x00, 0x3C                          // Keep Alive: 60 seconds
        ]

        let clientId = "ulgen_ios_\(deviceId)"
        guard let clientData = clientId.data(using: .utf8) else { return }
        let clientLen = UInt16(clientData.count)
        varHeader.append(UInt8(clientLen >> 8))
        varHeader.append(UInt8(clientLen & 0xFF))
        varHeader.append(contentsOf: clientData)

        var packet: [UInt8] = [0x10] // CONNECT
        packet.append(contentsOf: encodeRemainingLength(varHeader.count))
        packet.append(contentsOf: varHeader)

        sendData(Data(packet))
    }

    private func sendSubscribePacket(topic: String) {
        guard let topicData = topic.data(using: .utf8) else { return }
        var payload: [UInt8] = [
            0x00, 0x01 // Packet ID: 1
        ]
        let topicLen = UInt16(topicData.count)
        payload.append(UInt8(topicLen >> 8))
        payload.append(UInt8(topicLen & 0xFF))
        payload.append(contentsOf: topicData)
        payload.append(0x01) // QoS 1

        var packet: [UInt8] = [0x82] // SUBSCRIBE
        packet.append(contentsOf: encodeRemainingLength(payload.count))
        packet.append(contentsOf: payload)

        sendData(Data(packet))
    }

    public func broadcastProjectChange(_ project: Project) {
        guard let pData = try? JSONEncoder().encode(project),
              let pJson = String(data: pData, encoding: .utf8) else { return }

        let event = AccountSyncEvent(
            senderDeviceId: self.deviceId,
            eventType: "PROJECT_UPSERT",
            projectId: project.id,
            timestamp: project.lastUpdated,
            projectJson: pJson
        )

        broadcastAccountEvent(event)
    }

    public func broadcastProjectDelete(id: String) {
        let event = AccountSyncEvent(
            senderDeviceId: self.deviceId,
            eventType: "PROJECT_DELETE",
            projectId: id,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        broadcastAccountEvent(event)
    }

    public func broadcastAccountEvent(_ event: AccountSyncEvent) {
        guard let topic = currentTopic, isConnected else { return }
        guard let eventData = try? JSONEncoder().encode(event) else { return }

        publish(topic: topic, payload: eventData)
    }

    private func publish(topic: String, payload: Data) {
        guard let topicData = topic.data(using: .utf8) else { return }
        var varHeader: [UInt8] = []
        let topicLen = UInt16(topicData.count)
        varHeader.append(UInt8(topicLen >> 8))
        varHeader.append(UInt8(topicLen & 0xFF))
        varHeader.append(contentsOf: topicData)
        varHeader.append(contentsOf: payload)

        var packet: [UInt8] = [0x30] // PUBLISH QoS 0
        packet.append(contentsOf: encodeRemainingLength(varHeader.count))
        packet.append(contentsOf: varHeader)

        sendData(Data(packet))
    }

    private func sendPing() {
        let pingPacket: [UInt8] = [0xC0, 0x00]
        sendData(Data(pingPacket))
    }

    private func sendData(_ data: Data) {
        connection?.send(content: data, completion: .contentProcessed({ [weak self] error in
            if let error = error {
                print("[MqttSyncEngine] Send error: \(error)")
                self?.scheduleReconnect()
            }
        }))
    }

    private func encodeRemainingLength(_ length: Int) -> [UInt8] {
        var num = length
        var bytes: [UInt8] = []
        repeat {
            var digit = UInt8(num % 128)
            num /= 128
            if num > 0 {
                digit |= 0x80
            }
            bytes.append(digit)
        } while num > 0
        return bytes
    }

    // MARK: - Incoming Message Loop

    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            if let data = content, !data.isEmpty {
                self.processIncomingBytes(data)
            }
            if error != nil || isComplete {
                self.scheduleReconnect()
            } else {
                self.startReceiving()
            }
        }
    }

    private func processIncomingBytes(_ data: Data) {
        guard data.count >= 2 else { return }
        let packetType = (data[0] & 0xF0) >> 4

        switch packetType {
        case 2: // CONNACK
            if data.count >= 4 && data[3] == 0x00 {
                DispatchQueue.main.async {
                    self.isConnected = true
                    self.lastSyncTimestamp = Date()
                }
                if let topic = self.currentTopic {
                    self.sendSubscribePacket(topic: topic)
                }
                // Setup keepAlive ping every 30s
                DispatchQueue.main.async {
                    self.pingTimer?.invalidate()
                    self.pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                        self?.queue.async { self?.sendPing() }
                    }
                }
            }
        case 3: // PUBLISH
            parsePublishPacket(data)
        case 13: // PINGRESP
            break
        default:
            break
        }
    }

    private func parsePublishPacket(_ data: Data) {
        // Skip header byte and variable remaining length
        var idx = 1
        var multiplier = 1
        var remLen = 0
        while idx < data.count {
            let byte = Int(data[idx])
            remLen += (byte & 0x7F) * multiplier
            multiplier *= 128
            idx += 1
            if (byte & 0x80) == 0 { break }
        }

        guard idx + 2 <= data.count else { return }
        let topicLen = (Int(data[idx]) << 8) | Int(data[idx + 1])
        idx += 2
        guard idx + topicLen <= data.count else { return }
        // Topic string
        idx += topicLen

        // QoS 1 check (if header has QoS 1, 2-byte packet ID is present)
        let qos = (data[0] & 0x06) >> 1
        if qos > 0 {
            idx += 2
        }

        guard idx <= data.count else { return }
        let payloadData = data.subdata(in: idx..<data.count)

        if let event = try? JSONDecoder().decode(AccountSyncEvent.self, from: payloadData) {
            // Echo Suppression: Ignore our own messages
            guard event.senderDeviceId != self.deviceId else { return }

            DispatchQueue.main.async {
                self.lastSyncTimestamp = Date()
                self.handleIncomingAccountEvent(event)
            }
        }
    }

    private func handleIncomingAccountEvent(_ event: AccountSyncEvent) {
        print("[MqttSyncEngine] Received incoming event: \(event.eventType) for project: \(event.projectId ?? "") from: \(event.senderDeviceId)")

        switch event.eventType {
        case "PROJECT_UPSERT":
            guard let projectJson = event.projectJson,
                  let pData = projectJson.data(using: .utf8),
                  let incomingProject = try? JSONDecoder().decode(Project.self, from: pData) else { return }

            ProjectRepository.shared.mergeIncomingProject(incomingProject)

        case "PROJECT_DELETE":
            guard let pId = event.projectId else { return }
            ProjectRepository.shared.deleteProjectLocally(id: pId)

        case "STATE_SYNC", "REFRESH":
            Task {
                await ProjectRepository.shared.syncWithCloud()
            }

        default:
            break
        }
    }
}
