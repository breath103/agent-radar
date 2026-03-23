import Foundation

@MainActor
class NotificationWatcher {
    private let directoryURL: URL
    private let store: ProjectStore
    private var timer: Timer?

    init(store: ProjectStore) {
        self.store = store
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.directoryURL = home.appendingPathComponent(".agent-radar/notifications")
    }

    func start() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        processFiles()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processFiles()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func processFiles() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let payload = try? JSONDecoder().decode(NotificationPayload.self, from: data)
            else {
                try? fm.removeItem(at: file)
                continue
            }
            store.handleNotification(payload)
            try? fm.removeItem(at: file)
        }
    }
}
