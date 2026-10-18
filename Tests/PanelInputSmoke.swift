import AppKit
import SwiftUI

@main
struct PanelInputSmoke {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = TodoStore(fileURL: directory.appendingPathComponent("todos.json"))
        for index in 0..<40 {
            store.add(title: "滚动测试 \(index)", noteRTFD: nil, groupID: store.groups[0].id)
        }
        let hosting = NSHostingView(rootView: TodoPanel().environmentObject(store).padding(DeskSurface.windowOutset))
        let panel = TodoWindow(contentRect: NSRect(x: 80, y: 100, width: 744, height: 624))
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.contentView = PanelBackgroundView(contentView: hosting,
                                                surfaceInset: DeskSurface.windowOutset,
                                                cornerRadius: DeskSurface.cornerRadius,
                                                fillColor: NSColor(PanelStyle.canvas))
        hosting.wantsLayer = true
        hosting.layer?.masksToBounds = false
        var iteration = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            if iteration > 0 {
                let bounds = hosting.bounds
                precondition(bounds.size == panel.contentView!.bounds.size, "Hosting view must fill the resized panel")
                // NSView.hitTest alone passes even when WindowServer sends clicks and scrolls underneath.
                for point in [NSPoint(x: bounds.midX, y: bounds.midY),
                              NSPoint(x: 40, y: 40),
                              NSPoint(x: bounds.maxX - 40, y: bounds.maxY - 40)] {
                    let screenPoint = panel.convertPoint(toScreen: point)
                    precondition(NSWindow.windowNumber(at: screenPoint, belowWindowWithWindowNumber: 0) == panel.windowNumber,
                                 "Panel interior must receive system mouse and scroll events")
                    precondition(hosting.hitTest(point) != nil, "Panel content must receive native hit testing")
                }
                let margin = panel.convertPoint(toScreen: NSPoint(x: 2, y: 2))
                precondition(NSWindow.windowNumber(at: margin, belowWindowWithWindowNumber: 0) != panel.windowNumber,
                             "Shadow margin must remain transparent")
                panel.orderOut(nil)
                precondition(!panel.isVisible)
            }
            guard iteration < 6 else {
                timer.invalidate()
                print("PASS: system input region, native hits, transparent margins, resizing, and repeated reopening")
                app.stop(nil)
                return
            }
            let width: CGFloat = iteration.isMultiple(of: 2) ? 744 : 1084
            panel.setContentSize(NSSize(width: width, height: 624))
            panel.makeKeyAndOrderFront(nil)
            iteration += 1
        }
        app.run()
        timer.invalidate()
    }
}
