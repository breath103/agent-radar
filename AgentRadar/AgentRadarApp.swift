import SwiftUI

@main
struct AgentRadarApp: App {
    @State private var store = ProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }
}
