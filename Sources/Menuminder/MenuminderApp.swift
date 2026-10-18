import AppKit
import SwiftUI

@main
struct MenuminderApp: App {
    @NSApplicationDelegateAdaptor(MenuminderAppDelegate.self) private var appDelegate

    var body: some Scene { Settings { EmptyView() } }
}

@MainActor
final class MenuminderAppDelegate: NSObject, NSApplicationDelegate {
    private let store = TodoStore()
    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var eventMonitors: [Any] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = JianshiBrand.menuImage
        statusItem.button?.imageScaling = .scaleProportionallyDown
        statusItem.button?.toolTip = "笺事"
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel(_:))

        let hosting = NSHostingView(rootView: TodoPanel().environmentObject(store).padding(DeskSurface.windowOutset))
        panel = TodoWindow(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 600 + DeskSurface.windowOutset * 2))
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.contentView = PanelBackgroundView(contentView: hosting,
                                                surfaceInset: DeskSurface.windowOutset,
                                                cornerRadius: DeskSurface.cornerRadius,
                                                fillColor: NSColor(PanelStyle.canvas))
        hosting.wantsLayer = true
        hosting.layer?.masksToBounds = false
        installOutsideClickMonitors()
        DispatchQueue.main.async { self.showPanel() }
    }

    func applicationDidResignActive(_ notification: Notification) {
        // Let the status button's action handle its own click without closing twice.
        guard !statusItemButtonContainsMouse else { return }
        panel?.orderOut(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return false
    }

    private func installOutsideClickMonitors() {
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        eventMonitors.append(NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            guard let self else { return }
            if self.statusItemButtonContainsMouse { return }
            self.closePanelIfOutside()
        } as Any)
        eventMonitors.append(NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            if self?.statusItemButtonContainsMouse == true { return event }
            self?.closePanelIfOutside()
            return event
        } as Any)
    }

    private var statusItemButtonContainsMouse: Bool {
        guard let button = statusItem.button, let window = button.window else { return false }
        let rect = button.convert(button.bounds, to: nil)
        return window.convertToScreen(rect).contains(NSEvent.mouseLocation)
    }

    private func closePanelIfOutside() {
        guard panel.isVisible else { return }
        if !panel.frame.contains(NSEvent.mouseLocation) { panel.orderOut(nil) }
    }

    private var panelWidth: CGFloat {
        let available = (NSScreen.main?.visibleFrame.width ?? 1440) - 80
        return min(available, min(1060, max(420, CGFloat(store.groups.count) * 340 + 40))) + DeskSurface.windowOutset * 2
    }

    @objc private func togglePanel(_ sender: Any? = nil) {
        performTogglePanel()
    }

    private func performTogglePanel() {
        if panel.isVisible { panel.orderOut(nil); return }
        showPanel()
    }

    private func showPanel() {
        guard let button = statusItem?.button, let buttonWindow = button.window else { return }
        let width = panelWidth
        var frame = panel.frame
        frame.size = NSSize(width: width, height: 600 + DeskSurface.windowOutset * 2)
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        frame.origin.x = anchor.midX - width / 2
        frame.origin.y = anchor.minY - frame.height - 8
        if let screen = buttonWindow.screen {
            frame.origin.x = min(max(screen.visibleFrame.minX + 8, frame.origin.x), screen.visibleFrame.maxX - width - 8)
        }
        panel.setFrame(frame, display: false)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
