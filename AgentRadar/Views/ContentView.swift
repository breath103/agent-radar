import SwiftUI

struct ContentView: View {
    @Bindable var store: ProjectStore
    @State private var watcher: NotificationWatcher?

    var body: some View {
        Group {
            if store.projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Waiting for notifications...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Notifications will appear here when Claude Code sessions send hooks.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(store.projects) { project in
                            ProjectColumnView(project: project, store: store)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            let w = NotificationWatcher(store: store)
            w.start()
            watcher = w
        }
    }
}
