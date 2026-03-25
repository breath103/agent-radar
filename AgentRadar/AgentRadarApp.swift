import SwiftUI
import AppKit
import Carbon

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
    private var hotKeyRefs: [EventHotKeyRef?] = []

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
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow
        panel.isOpaque = false
        panel.backgroundColor = .clear

        let w = NotificationWatcher(store: store) { [weak self] in
            self?.showPanel()
        }
        w.start()
        watcher = w

        installGlobalHotkeys()

        NotificationCenter.default.addObserver(forName: .hidePanel, object: nil, queue: .main) { [weak self] _ in
            self?.hidePanel()
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
    }

    private func installGlobalHotkeys() {
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        var handlerRef: EventHandlerRef?
        var eventSpec = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        ]
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID), nil,
                                  MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
                switch hotKeyID.id {
                case 1:
                    DispatchQueue.main.async { delegate.togglePanel() }
                case 2:
                    DispatchQueue.main.async { delegate.goToLastNotifiedTerminal() }
                default:
                    break
                }
                return noErr
            },
            eventSpec.count, &eventSpec, refcon, &handlerRef
        )

        // Cmd+Shift+R (keycode 15)
        var hotKeyID1 = EventHotKeyID(signature: OSType(0x4147_5244), id: 1) // "AGRD"
        var hotKeyRef1: EventHotKeyRef?
        RegisterEventHotKey(UInt32(kVK_ANSI_R), UInt32(cmdKey | shiftKey),
                            hotKeyID1, GetApplicationEventTarget(), 0, &hotKeyRef1)
        hotKeyRefs.append(hotKeyRef1)

        // Cmd+Shift+L (keycode 37)
        var hotKeyID2 = EventHotKeyID(signature: OSType(0x4147_5244), id: 2) // "AGRD"
        var hotKeyRef2: EventHotKeyRef?
        RegisterEventHotKey(UInt32(kVK_ANSI_L), UInt32(cmdKey | shiftKey),
                            hotKeyID2, GetApplicationEventTarget(), 0, &hotKeyRef2)
        hotKeyRefs.append(hotKeyRef2)
    }

    private func goToLastNotifiedTerminal() {
        guard let project = store.projects.max(by: { $0.lastActivity < $1.lastActivity }) else { return }
        GhosttyFocuser.focusTerminal(pwd: project.id)
        store.clearNotifications(for: project.id)
        hidePanel()
    }
}
