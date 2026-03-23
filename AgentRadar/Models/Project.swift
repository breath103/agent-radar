import Foundation

struct Project: Identifiable, Hashable {
    let id: String
    var displayName: String
    var notifications: [AgentNotification]
    var shellPID: Int?
    var lastActivity: Date

    init(pwd: String) {
        self.id = pwd
        self.displayName = (pwd as NSString).lastPathComponent
        self.notifications = []
        self.lastActivity = Date()
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
