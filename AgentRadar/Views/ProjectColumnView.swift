import SwiftUI

struct ProjectColumnView: View {
    let project: Project
    @Bindable var store: ProjectStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.displayName)
                    .font(.headline)
                Text(project.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("Last: \(project.lastActivity.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)

            Divider()

            HStack(spacing: 8) {
                Button {
                    if let pid = project.shellPID {
                        GhosttyFocuser.focusTerminal(shellPID: pid)
                    }
                    store.clearNotifications(for: project.id)
                } label: {
                    Label("Terminal", systemImage: "terminal")
                        .font(.caption)
                }
                .disabled(project.shellPID == nil)

                Button {
                    GhosttyFocuser.openInVSCode(path: project.id)
                } label: {
                    Label("VSCode", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if project.notifications.isEmpty {
                Text("No notifications")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(project.notifications) { notification in
                            NotificationRowView(notification: notification)
                            Divider()
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Divider()
            HStack {
                if !project.notifications.isEmpty {
                    Text("\(project.notifications.count) notifications")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if !project.notifications.isEmpty {
                    Button(role: .destructive) {
                        store.clearNotifications(for: project.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("clear")
                }
                Button(role: .destructive) {
                    store.removeProject(project.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("remove")
            }
            .padding(8)
        }
        .frame(width: 280)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 1)
        )
    }
}
