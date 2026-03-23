import Foundation

struct AgentNotification: Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let hookEvent: String
    var isRead: Bool

    init(hookEvent: String, timestamp: Date) {
        self.id = UUID()
        self.timestamp = timestamp
        self.hookEvent = hookEvent
        self.isRead = false
    }
}

struct NotificationPayload: Codable {
    let pwd: String
    let hook_event: String
    let shell_pid: Int?
    let timestamp: TimeInterval
}
