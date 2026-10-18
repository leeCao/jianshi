import AppKit
import SwiftUI

enum PanelStyle {
    static let canvas = adaptive(light: 0xE8E4DE, dark: 0x2B2B29)
    static let canvasMiddle = adaptive(light: 0xE6E1D9, dark: 0x282826)
    static let canvasBottom = adaptive(light: 0xE0D9CF, dark: 0x252523)
    static let ink = adaptive(light: 0x342F29, dark: 0xECEAE3)
    static let taskInk = adaptive(light: 0x342F29, dark: 0xDBD9D2)
    static let muted = adaptive(light: 0x756C60, dark: 0xAAA79F)
    static let paper = adaptive(light: 0xFFF9EF, dark: 0x34332F)
    static let border = adaptive(light: 0xE5DED3, dark: 0x514F49)
    static let rule = border
    static let paperPrint = adaptive(light: 0xA89C8A, dark: 0xAAA393)
    static let field = paper
    static let accent = adaptive(light: 0xB0523E, dark: 0xD59580)
    static let toolbarAccent = adaptive(light: 0xAA3727, dark: 0xD59580)
    static let buttonHover = accent.opacity(0.055)
    static let buttonPressed = accent.opacity(0.10)
    static let inkWash = adaptive(light: 0xB07C6B, dark: 0xB98A79)

    private static let groupPalette: [String: (UInt32, UInt32)] = [
        "red": (0xA66B5C, 0xC89D91), "orange": (0xA18A70, 0xBAAA94),
        "yellow": (0xA39978, 0xBCB497), "green": (0x7B8876, 0xA1AD98),
        "blue": (0x70838D, 0x9BACB5), "purple": (0x887E8C, 0xADA3B2),
        "pink": (0xAA9090, 0xBFA9A9), "gray": (0x89877F, 0xADA99F)
    ]

    static func groupTint(_ name: String) -> Color {
        let pair = groupPalette[name] ?? groupPalette["blue"]!
        return adaptive(light: pair.0, dark: pair.1)
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let value = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
}

private struct NotebookRules: View {
    var body: some View {
        Canvas { context, size in
            var lines = Path()
            for y in stride(from: CGFloat(28), through: size.height, by: 28) {
                lines.move(to: CGPoint(x: 44, y: y))
                lines.addLine(to: CGPoint(x: max(44, size.width - 16), y: y))
            }
            context.stroke(lines, with: .color(PanelStyle.rule.opacity(0.12)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct WorkbenchButtonStyle: ButtonStyle {
    var primary = false
    var iconOnly = false
    var accent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PanelTypography.body)
            .padding(.horizontal, iconOnly ? 0 : 14)
            .frame(minHeight: iconOnly ? PanelMetrics.actionHitSize : 36)
            .modifier(OperationFeedback(primary: primary, accent: accent, isPressed: configuration.isPressed, iconOnly: iconOnly))
    }
}

private struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PanelTypography.toolbar)
            .padding(.horizontal, 8)
            .frame(minHeight: PanelMetrics.toolbarHitSize)
            .modifier(ToolbarControlFeedback(isPressed: configuration.isPressed))
    }
}

private struct ToolbarControlFeedback: ViewModifier {
    var isPressed = false
    @State private var hovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .foregroundStyle(PanelStyle.toolbarAccent)
            .background {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(PanelStyle.toolbarAccent.opacity(isPressed ? 0.14 : 0.08))
                    .opacity(hovered || isPressed ? 1 : 0)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(PanelStyle.toolbarAccent.opacity(0.16), lineWidth: 0.5)
                    .opacity(hovered || isPressed ? 1 : 0)
            }
            .scaleEffect(isPressed ? 0.96 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .onHover { hovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: hovered)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.10), value: isPressed)
    }
}

private struct OperationFeedback: ViewModifier {
    var primary = false
    var accent = false
    var isPressed = false
    var iconOnly = false
    @State private var hovered = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .foregroundStyle(primary || accent || (iconOnly && hovered && enabled)
                             ? PanelStyle.accent.opacity(0.80)
                             : PanelStyle.muted.opacity(0.86))
            .background(iconOnly ? .clear : (isPressed ? PanelStyle.buttonPressed : (hovered && enabled ? PanelStyle.buttonHover : .clear)),
                        in: RoundedRectangle(cornerRadius: 2))
            .contentShape(Rectangle())
            .opacity(enabled ? 1 : 0.45)
            .onHover { hovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isPressed)
    }
}

private struct IconButton: View {
    let glyph: LucideGlyph
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LucideIcon(glyph: glyph, size: PanelMetrics.actionIconSize)
                .frame(width: PanelMetrics.actionHitSize, height: PanelMetrics.actionHitSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(WorkbenchButtonStyle(iconOnly: true)).help(label).accessibilityLabel(label)
    }
}

private struct PageHeader: View {
    let title: String
    let back: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            IconButton(glyph: .chevronLeft, label: "返回", action: back)
            Text(title).font(PanelTypography.appTitle).foregroundStyle(PanelStyle.ink)
            Spacer()
        }
        .padding(.horizontal, 18).frame(height: 64)
    }
}

private struct MoreMenuButton: NSViewRepresentable {
    var label = "更多"
    var actionTitle = "退出笺事"
    var keyEquivalent = "q"
    var action: () -> Void = { NSApplication.shared.terminate(nil) }
    var tint = PanelStyle.muted

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: true)
        button.isBordered = false
        (button.cell as? NSPopUpButtonCell)?.arrowPosition = .noArrow
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleNone
        button.toolTip = self.label
        button.setAccessibilityLabel(self.label)
        let menu = NSMenu()
        let label = NSMenuItem()
        label.image = LucideIcon.nativeImage(.ellipsis, size: PanelMetrics.actionIconSize)
        menu.addItem(label)
        let operation = NSMenuItem(title: actionTitle, action: #selector(Coordinator.performAction), keyEquivalent: keyEquivalent)
        operation.target = context.coordinator
        menu.addItem(operation)
        button.menu = menu
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        button.contentTintColor = NSColor(tint)
        context.coordinator.action = action
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func performAction() { action() }
    }
}

private struct FieldSurface: ViewModifier {
    var focused = false
    func body(content: Content) -> some View {
        content
            .background(PanelStyle.field, in: RoundedRectangle(cornerRadius: 1))
            .overlay {
                RoundedRectangle(cornerRadius: 1)
                    .strokeBorder(focused ? PanelStyle.accent : PanelStyle.border, lineWidth: 1)
            }
    }
}

struct TodoPanel: View {
    @EnvironmentObject private var store: TodoStore
    @State private var editor: EditorState?
    @State private var detailID: UUID?
    @AppStorage("showCompletedItems") private var showingCompleted = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var managingGroups = false
    @State private var initialGroup: TodoGroup?
    @State private var createGroup = false
    @State private var hoveredGroupID: UUID?

    var body: some View {
        Group {
            if managingGroups {
                GroupManager(initialGroup: initialGroup, createInitially: createGroup) {
                    managingGroups = false
                }
            } else if let state = editor {
                TodoEditorPage(state: state, onCancel: { editor = nil }) { title, note, groupID in
                    if let id = state.itemID {
                        store.update(id: id, title: title, noteRTFD: note, groupID: groupID)
                    } else {
                        store.add(title: title, noteRTFD: note, groupID: groupID)
                    }
                    editor = nil
                }.id(state.id)
            } else if let id = detailID, let item = store.items.first(where: { $0.id == id }) {
                TodoDetailPage(item: item, onBack: { detailID = nil })
                    .id(id)
            } else {
                listPage
            }
        }
        .font(PanelTypography.control)
        .foregroundStyle(PanelStyle.ink)
        .tint(PanelStyle.accent)
        .background {
            DeskSurface()
        }
        .clipShape(RoundedRectangle(cornerRadius: DeskSurface.cornerRadius, style: .circular))
        .shadow(color: .black.opacity(0.065), radius: 4, x: 0, y: 3.5)
        .overlay(alignment: .bottom) {
            if let error = store.lastSaveError {
                Text(error).font(PanelTypography.caption).foregroundStyle(.red)
                    .padding(10).background(.regularMaterial).padding(8)
            }
        }
    }

    private func showGroups(_ group: TodoGroup? = nil, create: Bool = false) {
        initialGroup = group
        createGroup = create
        managingGroups = true
    }

    private var listPage: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let compact = geometry.size.width < PanelMetrics.expandedToolbarWidth
                HStack(spacing: compact ? 8 : 12) {
                    Text(JianshiBrand.name).font(PanelTypography.appTitle).tracking(2).lineLimit(1).fixedSize()
                        .padding(.leading, 8)
                    Spacer(minLength: 8)
                    toolbar
                }
                .padding(.horizontal, compact ? 20 : 24).frame(height: PanelMetrics.headerHeight)
            }
            .frame(height: PanelMetrics.headerHeight)

            GeometryReader { geometry in
                let count = CGFloat(max(store.groups.count, 1))
                let fittingWidth = (geometry.size.width - PanelMetrics.pageInset * 2 - (count - 1) * PanelMetrics.columnGap) / count
                let columnWidth = fittingWidth >= 280 ? fittingWidth : 310
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: PanelMetrics.columnGap) {
                        ForEach(store.groups) { group in
                            groupColumn(group)
                                .padding(.top, PanelMetrics.paperTopInset)
                                .frame(width: columnWidth,
                                       height: max(100, geometry.size.height - 26))
                        }
                    }
                    .padding(.horizontal, PanelMetrics.pageInset)
                    .padding(.top, 2).padding(.bottom, 16)
                }
                .scrollIndicators(.automatic)
            }

        }
        .padding(.top, PanelMetrics.canvasTopInset)
    }

    private var toolbar: some View {
        HStack(spacing: 4) {
            if !store.completedItems.isEmpty {
                Button { showingCompleted.toggle() } label: {
                    toolbarLabel(showingCompleted ? "隐藏已完成 · \(store.completedItems.count)" : "显示已完成 · \(store.completedItems.count)",
                                 glyph: showingCompleted ? .circleCheck : .circle)
                }
                .buttonStyle(ToolbarButtonStyle())
                .help(showingCompleted ? "隐藏已完成" : "显示已完成")
                .accessibilityLabel(showingCompleted ? "隐藏已完成" : "显示已完成")
                .accessibilityValue("\(store.completedItems.count) 项已完成")
            }
            Button { showGroups() } label: {
                toolbarLabel("管理分组", glyph: .folders)
            }
            .buttonStyle(ToolbarButtonStyle())
            .help("管理分组")
            .accessibilityLabel("管理分组")
            MoreMenuButton(tint: PanelStyle.toolbarAccent)
                .frame(width: PanelMetrics.toolbarHitSize, height: PanelMetrics.toolbarHitSize)
                .modifier(ToolbarControlFeedback())
        }
        .fixedSize()
    }

    private func toolbarLabel(_ title: String, glyph: LucideGlyph) -> some View {
        HStack(spacing: 6) {
            LucideIcon(glyph: glyph, size: PanelMetrics.actionIconSize)
            Text(title)
        }
        .frame(minHeight: PanelMetrics.toolbarHitSize)
        .contentShape(Rectangle())
    }

    private func groupColumn(_ group: TodoGroup) -> some View {
        let textureVariant = (store.groups.firstIndex(where: { $0.id == group.id }) ?? 0) % 3
        let tasks = store.items
            .filter { $0.groupID == group.id && (showingCompleted || !$0.isCompleted) }
            .sorted { $0.createdAt > $1.createdAt }
        return PaperSheetCard(contentPadding: 0, textureVariant: textureVariant) {
            VStack(spacing: 0) {
                groupHeader(group)
                ArchivePrintedRule().padding(.horizontal, 18)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if tasks.isEmpty {
                            Text(store.items.contains(where: { $0.groupID == group.id }) ? "本组待办已全部完成" : "还没有待办")
                                .font(PanelTypography.secondary).foregroundStyle(PanelStyle.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                        }
                        ForEach(tasks) { item in
                            row(item).transition(.opacity)
                        }
                    }
                    .padding(.top, 6).padding(.bottom, 16)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: showingCompleted)
                }
                .scrollIndicators(.automatic)
                .background { NotebookRules() }
            }
            .padding(.top, 8).padding(.horizontal, 4).padding(.bottom, 8)
        }
        .contentShape(Rectangle())
        .onHover { hovered in
            if hovered { hoveredGroupID = group.id }
            else if hoveredGroupID == group.id { hoveredGroupID = nil }
        }
    }

    private func row(_ item: TodoItem) -> some View {
        TodoRow(item: item, toggle: { store.toggle(item) },
                openDetail: { detailID = item.id }, delete: { store.delete(item) })
    }

    private func groupHeader(_ group: TodoGroup) -> some View {
        HStack(spacing: 8) {
            Circle().fill(group.tint.opacity(0.75)).frame(width: 8, height: 8)
            Text(group.name).font(PanelTypography.heading).lineLimit(1).help(group.name)
            Text("\(store.activeItems.filter { $0.groupID == group.id }.count)")
                .font(PanelTypography.caption).monospacedDigit().foregroundStyle(PanelStyle.muted)
                .padding(.leading, 3)
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                IconButton(glyph: .plus, label: "添加到\(group.name)") { editor = EditorState(groupID: group.id) }
            }
            .opacity(hoveredGroupID == group.id ? 1 : 0.75)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hoveredGroupID == group.id)
        }
        .padding(.leading, 18).padding(.trailing, 10).frame(height: PanelMetrics.groupHeaderHeight)
    }

}

struct TodoCheckbox: View {
    let isCompleted: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                PencilCircle().fill(PanelStyle.muted.opacity(0.8))
                PencilCheck().fill(PanelStyle.accent)
                    .mask {
                        PencilCheckTrace().trim(from: 0, to: isCompleted ? 1 : 0)
                            .stroke(.white, style: StrokeStyle(lineWidth: 4.4, lineCap: .round, lineJoin: .round))
                            .animation(reduceMotion ? nil : .easeOut(duration: isCompleted ? 0.18 : 0.12), value: isCompleted)
                    }
                    .scaleEffect(isCompleted ? 1 : 0.88, anchor: .center)
                    .animation(reduceMotion ? nil : (isCompleted
                        ? .spring(response: 0.22, dampingFraction: 0.65)
                        : .easeOut(duration: 0.12)), value: isCompleted)
            }
            .frame(width: PanelMetrics.checkboxSize, height: PanelMetrics.checkboxSize)
            .frame(width: PanelMetrics.checkboxHitSize, height: PanelMetrics.checkboxHitSize)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "标记未完成" : "完成待办")
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let toggle: () -> Void
    let openDetail: () -> Void
    let delete: () -> Void
    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TodoCheckbox(isCompleted: item.isCompleted, action: toggle)
            Button(action: openDetail) {
            VStack(alignment: .leading, spacing: PanelMetrics.titleNoteGap) {
                Text(item.title).font(PanelTypography.body)
                    .modifier(ArchiveCompletionMark(text: item.title, size: 17, lineSpacing: PanelMetrics.titleLineSpacing, lineLimit: 3, enabled: item.isCompleted))
                    .foregroundStyle(PanelStyle.taskInk.opacity(item.isCompleted ? 0.94 : 1)).lineLimit(3)
                    .lineSpacing(PanelMetrics.titleLineSpacing)
                if !preview.isEmpty {
                    Text(preview).font(PanelTypography.secondary).lineSpacing(PanelMetrics.noteLineSpacing)
                        .modifier(ArchiveCompletionMark(text: preview, size: 14.5, lineSpacing: PanelMetrics.noteLineSpacing, lineLimit: 2, enabled: item.isCompleted))
                        .foregroundStyle(PanelStyle.muted.opacity(item.isCompleted ? 0.92 : 1)).lineLimit(2)
                }
                if attachments > 0 {
                    HStack(spacing: 4) {
                        LucideIcon(glyph: .image, size: 13)
                        Text("\(attachments) 张图片").font(PanelTypography.caption)
                    }.foregroundStyle(PanelStyle.muted).padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, PanelMetrics.rowTextTopInset)
            .contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityHint("打开待办详情")
        }
        .padding(.horizontal, 8).padding(.vertical, PanelMetrics.rowVerticalPadding)
        .frame(minHeight: PanelMetrics.rowMinimumHeight, alignment: .top)
        .background {
            BrushHighlight()
                .opacity(hovering ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: hovering)
        }
        .padding(.horizontal, 8).contentShape(Rectangle())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: item.isCompleted)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("查看详情", action: openDetail)
            Button(item.isCompleted ? "标记为未完成" : "标记为已完成", action: toggle)
            Divider()
            Button("删除", role: .destructive, action: delete)
        }
    }
    private var note: NSAttributedString? {
        guard let data = item.noteRTFD else { return nil }
        return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
    }
    private var preview: String {
        note?.string.replacingOccurrences(of: "\u{FFFC}", with: "").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    private var attachments: Int {
        guard let note else { return 0 }
        var count = 0
        note.enumerateAttribute(.attachment, in: NSRange(location: 0, length: note.length)) { value, _, _ in
            if value != nil { count += 1 }
        }
        return count
    }
}

struct EditorState: Identifiable {
    let id = UUID()
    let itemID: UUID?
    let initialTitle: String
    let initialNote: Data?
    let groupID: UUID?
    init(item: TodoItem? = nil, groupID: UUID? = nil) {
        itemID = item?.id
        initialTitle = item?.title ?? ""
        initialNote = item?.noteRTFD
        self.groupID = item?.groupID ?? groupID
    }
}

private struct TodoDetailPage: View {
    @EnvironmentObject private var store: TodoStore
    let item: TodoItem
    let onBack: () -> Void
    @State private var title: String
    @State private var note: Data?

    init(item: TodoItem, onBack: @escaping () -> Void) {
        self.item = item
        self.onBack = onBack
        _title = State(initialValue: item.title)
        _note = State(initialValue: item.noteRTFD)
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "待办详情", back: onBack)
            Divider()
            ScrollView {
                PaperSheetCard(contentPadding: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            if let group = store.groups.first(where: { $0.id == item.groupID }) {
                                Circle().fill(group.tint).frame(width: 8, height: 8)
                                Text(group.name).lineLimit(1)
                            }
                            Spacer()
                            MoreMenuButton(label: "待办更多操作", actionTitle: "删除待办", keyEquivalent: "") {
                                store.delete(item)
                                onBack()
                            }
                            .frame(width: PanelMetrics.actionHitSize, height: PanelMetrics.actionHitSize)
                        }
                        .font(PanelTypography.body).foregroundStyle(PanelStyle.muted)

                        HStack(alignment: .top, spacing: 10) {
                            TodoCheckbox(isCompleted: item.isCompleted) { store.toggle(item) }
                            TextField("待办标题", text: $title, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(PanelTypography.detailTitle)
                                .accessibilityLabel("待办标题")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        PaperPrintedRule()
                        RichTextEditor(rtfdData: $note, inline: true)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .accessibilityLabel("待办描述与图片")
                            .overlay(alignment: .topLeading) {
                                if note == nil {
                                    Text("添加描述…")
                                        .font(PanelTypography.secondary).foregroundStyle(PanelStyle.muted)
                                        .allowsHitTesting(false)
                                        .accessibilityHidden(true)
                                }
                            }
                    }.padding(24).frame(maxWidth: 608)
                }
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
        }
        .onExitCommand(perform: onBack)
        .onChange(of: title) { _ in saveChanges() }
        .onChange(of: note) { _ in saveChanges() }
    }

    private func saveChanges() {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Keep the last valid title while a replacement is being typed.
        let savedTitle = cleaned.isEmpty ? item.title : cleaned
        guard savedTitle != item.title || note != item.noteRTFD else { return }
        store.update(id: item.id, title: savedTitle, noteRTFD: note, groupID: item.groupID)
    }
}

private struct TodoEditorPage: View {
    @EnvironmentObject private var store: TodoStore
    let state: EditorState
    let onCancel: () -> Void
    let onSave: (String, Data?, UUID?) -> Void
    @State private var groupID: UUID?
    @State private var title: String
    @State private var note: Data?
    @FocusState private var titleFocused: Bool

    init(state: EditorState, onCancel: @escaping () -> Void, onSave: @escaping (String, Data?, UUID?) -> Void) {
        self.state = state; self.onCancel = onCancel; self.onSave = onSave
        _title = State(initialValue: state.initialTitle)
        _note = State(initialValue: state.initialNote)
        _groupID = State(initialValue: state.groupID)
    }
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: state.itemID == nil ? "新建待办" : "编辑待办", back: onCancel)
            Divider()
            PaperSheetCard(contentPadding: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题").fontWeight(.medium)
                        TextField("要做什么？", text: $title)
                            .textFieldStyle(.plain).font(PanelTypography.body)
                            .padding(.horizontal, 12).frame(height: 44)
                            .modifier(FieldSurface(focused: titleFocused))
                            .focused($titleFocused)
                    }
                    HStack {
                        Text("分组").foregroundStyle(PanelStyle.muted)
                        Spacer()
                        Menu {
                            ForEach(store.groups) { group in
                                Button(group.name) { groupID = group.id }
                            }
                        } label: {
                            HStack(spacing: 7) {
                                if let group = store.groups.first(where: { $0.id == groupID }) {
                                    Circle().fill(group.tint).frame(width: 7, height: 7)
                                    Text(group.name).lineLimit(1)
                                }
                                LucideIcon(glyph: .chevronDown, size: 12)
                            }
                        }.menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("描述").fontWeight(.medium)
                            Text("可选").foregroundStyle(PanelStyle.muted).font(PanelTypography.caption)
                        }
                        RichTextEditor(rtfdData: $note)
                            .frame(maxHeight: .infinity)
                            .modifier(FieldSurface())
                        HStack(spacing: 5) {
                            LucideIcon(glyph: .image, size: 13)
                            Text("粘贴或拖入图片").font(PanelTypography.caption)
                        }.foregroundStyle(PanelStyle.muted)
                    }
                }.padding(24).frame(maxWidth: 568)
            }
                .padding(.horizontal, 20).padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            Divider()
            HStack {
                Button("取消", action: onCancel).buttonStyle(WorkbenchButtonStyle()).keyboardShortcut(.cancelAction)
                Spacer()
                Button("保存") { onSave(title, note, groupID) }
                    .buttonStyle(WorkbenchButtonStyle(primary: true)).keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.controlSize(.regular).padding(.horizontal, 24).frame(height: 66)
        }
        .onAppear {
            if groupID == nil { groupID = store.groups.first?.id }
            titleFocused = true
        }
    }
}

private struct GroupManager: View {
    @EnvironmentObject private var store: TodoStore
    let initialGroup: TodoGroup?
    let createInitially: Bool
    let onBack: () -> Void
    @State private var drafts: [TodoGroup] = []
    @State private var deletingID: UUID?
    @State private var invalidNames: Set<UUID> = []
    @FocusState private var focusedGroupID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "管理分组", back: finish)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach($drafts) { $group in
                            groupRow($group)
                                .id(group.id)
                            if group.id != drafts.last?.id {
                                Divider().padding(.vertical, 20)
                            }
                        }
                    }
                    .padding(24).frame(maxWidth: 568).frame(maxWidth: .infinity)
                }
                .onChange(of: focusedGroupID) { id in
                    if let id { proxy.scrollTo(id, anchor: .center) }
                }
            }
            Divider()
            HStack {
                Button(action: create) {
                    HStack(spacing: 6) { LucideIcon(glyph: .folderPlus); Text("新建分组") }
                }.buttonStyle(WorkbenchButtonStyle())
                Spacer()
                Button("完成", action: finish)
                    .buttonStyle(WorkbenchButtonStyle(primary: true)).keyboardShortcut(.cancelAction)
            }.padding(.horizontal, 24).frame(height: 66)
        }
        .onAppear {
            drafts = store.groups
            if createInitially { create() }
            else { focusedGroupID = initialGroup?.id }
        }
        .onChange(of: focusedGroupID) { id in
            for group in drafts where group.id != id { persist(group) }
        }
        .onDisappear {
            for group in drafts where !group.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                persist(group)
            }
        }
    }

    private func groupRow(_ group: Binding<TodoGroup>) -> some View {
        let id = group.wrappedValue.id
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Circle().fill(group.wrappedValue.tint).frame(width: 9, height: 9)
                TextField("分组名称", text: group.name)
                    .textFieldStyle(.plain).font(PanelTypography.body)
                    .padding(.horizontal, 10).frame(height: 40)
                    .modifier(FieldSurface(focused: focusedGroupID == id))
                    .focused($focusedGroupID, equals: id)
                    .accessibilityLabel("分组名称")
                    .onSubmit { persist(group.wrappedValue) }
                    .onChange(of: group.wrappedValue.name) { name in
                        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            invalidNames.remove(id)
                        }
                    }
                Text("\(store.items.filter { $0.groupID == id }.count) 项")
                    .foregroundStyle(PanelStyle.muted).font(PanelTypography.caption)
                    .fixedSize()
                IconButton(glyph: .trash, label: "删除\(group.wrappedValue.name)分组") {
                    focusedGroupID = nil
                    deletingID = id
                }
                .disabled(drafts.count == 1)
                .help(drafts.count == 1 ? "至少保留一个分组" : "删除分组")
            }
            if invalidNames.contains(id) {
                Text("请输入分组名称").font(PanelTypography.caption).foregroundStyle(.red)
                    .padding(.leading, 19)
            }
            HStack(spacing: 8) {
                ForEach(TodoGroup.colors, id: \.self) { value in
                    Button {
                        group.wrappedValue.color = value
                        persist(group.wrappedValue)
                    } label: {
                        Circle().fill(TodoGroup.tint(value)).frame(width: 20, height: 20)
                            .overlay {
                                if group.wrappedValue.color == value {
                                    LucideIcon(glyph: .check, size: 12).foregroundStyle(.white)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .overlay {
                                Circle().strokeBorder(group.wrappedValue.color == value
                                    ? TodoGroup.tint(value).opacity(0.6) : .clear, lineWidth: 1)
                            }
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).help(TodoGroup.colorName(value))
                        .accessibilityLabel("\(group.wrappedValue.name)，\(TodoGroup.colorName(value))")
                        .accessibilityAddTraits(group.wrappedValue.color == value ? .isSelected : [])
                }
            }
            .padding(.leading, 19)
            if deletingID == id {
                VStack(alignment: .leading, spacing: 12) {
                    Text("组内待办会移到「\(drafts.first(where: { $0.id != id })?.name ?? "")」，包括已完成事项。")
                        .font(PanelTypography.control).foregroundStyle(PanelStyle.muted)
                    HStack {
                        Button("取消") { deletingID = nil }
                            .buttonStyle(WorkbenchButtonStyle())
                        Spacer()
                        Button("确认删除", role: .destructive) { delete(id) }
                            .buttonStyle(.plain).foregroundStyle(.red)
                            .padding(.horizontal, 14).frame(minHeight: 36)
                    }
                }.padding(.leading, 19)
            }
        }
    }

    private func persist(_ group: TodoGroup) {
        let name = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            invalidNames.insert(group.id)
            return
        }
        invalidNames.remove(group.id)
        if let saved = store.groups.first(where: { $0.id == group.id }),
           saved.name != name || saved.color != group.color {
            store.saveGroup(id: group.id, name: name, color: group.color)
        }
    }

    private func finish() {
        for group in drafts { persist(group) }
        if let invalid = drafts.first(where: { invalidNames.contains($0.id) }) {
            focusedGroupID = invalid.id
        } else {
            onBack()
        }
    }

    private func create() {
        var name = "新分组"
        var number = 2
        while drafts.contains(where: { $0.name == name }) {
            name = "新分组 \(number)"
            number += 1
        }
        store.saveGroup(id: nil, name: name, color: "blue")
        if let group = store.groups.last {
            drafts.append(group)
            focusedGroupID = group.id
        }
    }

    private func delete(_ id: UUID) {
        for group in drafts { persist(group) }
        guard let group = store.groups.first(where: { $0.id == id }) else { return }
        store.deleteGroup(group)
        drafts.removeAll { $0.id == id }
        invalidNames.remove(id)
        deletingID = nil
    }
}
