import AppKit

@main
struct WindowEditingSmoke {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let panel = TodoWindow(contentRect: NSRect(x: 80, y: 100, width: 400, height: 300))
        precondition(panel.canBecomeKey, "The todo panel must accept keyboard focus")
        precondition(!panel.hidesOnDeactivate, "System auto-hiding must not bypass explicit dismissal")
        precondition(!panel.becomesKeyOnlyIfNeeded, "SwiftUI fields must be able to acquire keyboard focus")
        let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        let groupName = NSTextField(frame: NSRect(x: 20, y: 220, width: 300, height: 30))
        let note = NSTextView(frame: NSRect(x: 20, y: 20, width: 300, height: 180))
        content.addSubview(groupName)
        content.addSubview(note)
        panel.contentView = content
        for _ in 0..<20 {
            panel.makeKeyAndOrderFront(nil)
            precondition(panel.isVisible, "Opening must set visible state")
            panel.orderOut(nil)
            precondition(!panel.isVisible, "Dismissal must clear visible state")
        }
        precondition(panel.makeFirstResponder(groupName))
        guard let fieldEditor = groupName.currentEditor() else {
            fatalError("The group name must receive an editor")
        }
        fieldEditor.insertText("分组编辑测试")
        precondition(panel.makeFirstResponder(note))
        precondition(groupName.stringValue == "分组编辑测试", "Group name typing must commit")
        note.insertText("待办描述编辑测试", replacementRange: note.selectedRange())
        precondition(note.string == "待办描述编辑测试", "Note typing must work")
        panel.orderOut(nil)
        print("PASS: 20 panel open/close cycles, explicit visibility, group name editing, and note editing")
    }
}
