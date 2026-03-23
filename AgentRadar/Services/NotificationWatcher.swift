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
            // Special test command: move window to a specific screen index
            if payload.hook_event == "_move_to_screen" {
                let screenIndex = payload.shell_pid ?? 1
                if screenIndex < NSScreen.screens.count {
                    let screen = NSScreen.screens[screenIndex]
                    if let window = NSApplication.shared.windows.first(where: { $0.isVisible || $0.canBecomeMain }) {
                        let sf = screen.visibleFrame
                        let ws = window.frame.size
                        window.setFrame(NSRect(x: sf.midX - ws.width/2, y: sf.midY - ws.height/2, width: ws.width, height: ws.height), display: true)
                    }
                }
                try? fm.removeItem(at: file)
                continue
            }

            store.handleNotification(payload)
            try? fm.removeItem(at: file)
            hadNew = true
        }

        if hadNew {
            showWindow()
        }
    }

    private func showWindow() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible || $0.canBecomeMain }) else { return }

        let mouseLocation = NSEvent.mouseLocation
        let mouseScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
        let onCurrentScreen = (mouseScreen == window.screen)

        if onCurrentScreen {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else if let target = mouseScreen {
            let screenFrame = target.visibleFrame
            let windowSize = window.frame.size
            let x = screenFrame.midX - windowSize.width / 2
            let y = screenFrame.midY - windowSize.height / 2
            window.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true, animate: false)
        }
    }
}
