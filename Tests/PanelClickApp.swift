import AppKit
import SwiftUI

@main
struct PanelClickApp {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let mainMenu = NSMenu()
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu()
        let quit = NSMenuItem(title: "退出点击测试", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = app
        applicationMenu.addItem(quit)
        applicationItem.submenu = applicationMenu
        mainMenu.addItem(applicationItem)
        app.mainMenu = mainMenu
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let store = TodoStore(fileURL: directory.appendingPathComponent("todos.json"))
        if store.items.isEmpty {
            store.saveGroup(id: store.groups[0].id, name: "工作", color: "blue")
            store.saveGroup(id: nil, name: "生活", color: "green")
            store.saveGroup(id: nil, name: "阅读与灵感", color: "orange")
            for group in store.groups {
                store.add(title: "点击圆圈中心测试", noteRTFD: nil, groupID: group.id)
                store.add(title: "打开任务详情测试", noteRTFD: nil, groupID: group.id)
            }
        }
        let host = NSHostingView(rootView: TodoPanel().environmentObject(store).frame(width: 1060, height: 600))
        let window = NSWindow(contentRect: NSRect(x: 80, y: 100, width: 1060, height: 600),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Menuminder · 点击回归（临时数据）"
        window.contentView = host
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        let monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
            if event.window === window {
                let point = host.convert(event.locationInWindow, from: nil)
                let parentPoint = host.superview?.convert(event.locationInWindow, from: nil) ?? event.locationInWindow
                let hit = host.hitTest(parentPoint)
                print("Mouse down \(point), native hit: \(hit.map { String(describing: type(of: $0)) } ?? "nil")")
                fflush(stdout)
            }
            return event
        }
        print("Fixture file: \(directory.appendingPathComponent("todos.json").path)")
        fflush(stdout)
        app.run()
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}
