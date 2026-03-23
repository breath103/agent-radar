import Foundation
import AppKit

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
            guard let self else { return }
            Task { @MainActor in
                self.processFiles()
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
            moveWindowToCurrentScreen()
        }
    }

    private func moveWindowToCurrentScreen() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible || $0.canBecomeMain }) else { return }

        let mouseLocation = NSEvent.mouseLocation
        let mouseScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let target = mouseScreen else { return }

        let screenFrame = target.visibleFrame
        let windowSize = window.frame.size
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.midY - windowSize.height / 2
        let newFrame = NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height)

        window.setFrame(newFrame, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
