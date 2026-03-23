import SwiftUI

struct NotificationRowView: View {
    let notification: AgentNotification

    private var icon: String {
        switch notification.hookEvent.lowercased() {
        case "stop": return "stop.circle.fill"
        case "notification": return "bell.fill"
        default: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch notification.hookEvent.lowercased() {
        case "stop": return .orange
        case "notification": return .blue
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.hookEvent)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(notification.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .opacity(notification.isRead ? 0.5 : 1.0)
    }
}
