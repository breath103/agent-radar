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
    private var hotKeyRefR: EventHotKeyRef?
    private var hotKeyRefL: EventHotKeyRef?
    private var blinkTimer: Timer?
    private var blinkState = false

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
            self?.startBlinking()
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
            stopBlinking()
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

    private func startBlinking() {
        registerJumpHotkey()
        guard blinkTimer == nil else { return }
        blinkState = false
        let timer = Timer(timeInterval: 0.6, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.blinkState.toggle()
                self.updateStatusIcon()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        blinkTimer = timer
        // Immediately show first blink state
        blinkState = true
        updateStatusIcon()
    }

    private func stopBlinking() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        blinkState = false
        updateStatusIcon()
        unregisterJumpHotkey()
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        let symbolName = "antenna.radiowaves.left.and.right"
        if blinkTimer != nil {
            let config = NSImage.SymbolConfiguration(paletteColors: [blinkState ? .systemGreen : .white])
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "AgentRadar")?.withSymbolConfiguration(config)
        } else {
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "AgentRadar")
        }
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

        // Cmd+Shift+R — always registered
        let hotKeyID1 = EventHotKeyID(signature: OSType(0x4147_5244), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_R), UInt32(cmdKey | shiftKey),
                            hotKeyID1, GetApplicationEventTarget(), 0, &hotKeyRefR)
    }

    func registerJumpHotkey() {
        guard hotKeyRefL == nil else { return }
        let hotKeyID2 = EventHotKeyID(signature: OSType(0x4147_5244), id: 2)
        RegisterEventHotKey(UInt32(kVK_ANSI_L), UInt32(cmdKey | shiftKey),
                            hotKeyID2, GetApplicationEventTarget(), 0, &hotKeyRefL)
    }

    func unregisterJumpHotkey() {
        guard let ref = hotKeyRefL else { return }
        UnregisterEventHotKey(ref)
        hotKeyRefL = nil
    }

    private func goToLastNotifiedTerminal() {
        guard let project = store.projects.filter({ !$0.notifications.isEmpty }).max(by: { $0.lastActivity < $1.lastActivity }) else { return }
        stopBlinking()
        GhosttyFocuser.focusTerminal(pwd: project.id)
        store.clearNotifications(for: project.id)
        hidePanel()
    }
}
