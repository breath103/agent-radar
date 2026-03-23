import Foundation
import AppKit

@MainActor
class NotificationWatcher {
    private let directoryURL: URL
    private let store: ProjectStore
    private var timer: DispatchSourceTimer?
    private let onNotification: () -> Void

    init(store: ProjectStore, onNotification: @escaping () -> Void) {
        self.store = store
        self.onNotification = onNotification
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.directoryURL = home.appendingPathComponent(".agent-radar/notifications")
    }

    func start() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        processFiles()
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now() + 1, repeating: 1.0)
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.processFiles()
            }
        }
        source.resume()
        timer = source
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func processFiles() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else { return }

        var hadNew = false
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let payload = try? JSONDecoder().decode(NotificationPayload.self, from: data)
            else {
                try? fm.removeItem(at: file)
                continue
            }

            store.handleNotification(payload)
            try? fm.removeItem(at: file)
            hadNew = true
        }

        if hadNew {
            onNotification()
        }
    }
}
