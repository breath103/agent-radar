import SwiftUI
import AppKit

@main
struct AgentRadarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private let store = ProjectStore()
    private var watcher: NotificationWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "AgentRadar")
            button.action = #selector(togglePanel)
            button.target = self
        }

        let contentView = ContentView(store: store)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 700, height: 500)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.title = "AgentRadar"
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow

        let w = NotificationWatcher(store: store) { [weak self] in
            self?.showPanel()
        }
        w.start()
        watcher = w

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let key = event.charactersIgnoringModifiers?.lowercased()
            if mods == [.command, .shift] {
                if key == "l" {
                    self?.goToLastNotifiedTerminal()
                    return nil
                }
                if key == "r" {
                    self?.togglePanel()
                    return nil
                }
            }
            return event
        }

        NotificationCenter.default.addObserver(forName: .hidePanel, object: nil, queue: .main) { [weak self] _ in
            self?.hidePanel()
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let key = event.charactersIgnoringModifiers?.lowercased()
            if mods == [.command, .shift] {
                if key == "r" {
                    self?.togglePanel()
                }
                if key == "l" {
                    self?.goToLastNotifiedTerminal()
                }
            }
        }
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            positionPanelBelowStatusItem()
            panel.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private func positionPanelBelowStatusItem() {
        guard let buttonFrame = statusItem.button?.window?.frame else { return }
        let panelWidth = panel.frame.width
        let panelHeight = panel.frame.height
        let x = buttonFrame.midX - panelWidth / 2
        let y = buttonFrame.minY - panelHeight
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
    }

    func hidePanel() {
        panel.orderOut(nil)
    }

    func showPanel() {
        positionPanelBelowStatusItem()
        panel.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func goToLastNotifiedTerminal() {
        guard let project = store.projects.max(by: { $0.lastActivity < $1.lastActivity }) else { return }
        if let pid = project.shellPID {
            GhosttyFocuser.focusTerminal(shellPID: pid)
        }
        store.clearNotifications(for: project.id)
        hidePanel()
    }
}
