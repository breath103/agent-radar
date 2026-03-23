import Foundation
import Observation

@MainActor
@Observable
class ProjectStore {
    var projects: [Project] = []

    func handleNotification(_ payload: NotificationPayload) {
        let pwd = payload.pwd
        let notification = AgentNotification(
            hookEvent: payload.hook_event,
            timestamp: Date(timeIntervalSince1970: payload.timestamp)
        )

        if let project = projects.first(where: { $0.id == pwd }) {
            project.notifications.insert(notification, at: 0)
            project.shellPID = payload.shell_pid ?? project.shellPID
            project.lastActivity = Date()
        } else {
            let project = Project(pwd: pwd)
            project.notifications.append(notification)
            project.shellPID = payload.shell_pid
            projects.append(project)
        }
    }

    func clearNotifications(for projectID: String) {
        if let project = projects.first(where: { $0.id == projectID }) {
            project.notifications.removeAll()
        }
    }

    func removeProject(_ projectID: String) {
        projects.removeAll { $0.id == projectID }
    }
}
