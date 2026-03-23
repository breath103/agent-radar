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

        if let index = projects.firstIndex(where: { $0.id == pwd }) {
            projects[index].notifications.insert(notification, at: 0)
            projects[index].shellPID = payload.shell_pid ?? projects[index].shellPID
            projects[index].lastActivity = Date()
        } else {
            var project = Project(pwd: pwd)
            project.notifications.append(notification)
            project.shellPID = payload.shell_pid
            projects.append(project)
        }
    }

    func clearNotifications(for projectID: String) {
        if let index = projects.firstIndex(where: { $0.id == projectID }) {
            projects[index].notifications.removeAll()
        }
    }

    func removeProject(_ projectID: String) {
        projects.removeAll { $0.id == projectID }
    }
}
