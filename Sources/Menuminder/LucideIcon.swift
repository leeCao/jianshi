import SwiftUI
import AppKit

// Lucide 4× PNG templates; license in Resources/Lucide-LICENSE.txt.
enum LucideGlyph: String, CaseIterable {
    case listTodo = "list-todo", settings = "settings-2", plus
    case circlePlus = "circle-plus", circle, circleCheck = "circle-check"
    case chevronRight = "chevron-right", chevronDown = "chevron-down", chevronLeft = "chevron-left"
    case pencil, trash, image, check, x, folderPlus = "folder-plus", folders, ellipsis, power
}

struct LucideIcon: View {
    var glyph: LucideGlyph
    var size: CGFloat = 16

    // Lucide icons share a 24 pt canvas, but their visible paths occupy
    // different areas. Normalize the sparse plus and the edge-to-edge pencil
    // so adjacent toolbar actions have the same perceived size.
    private var opticalScale: CGFloat {
        switch glyph {
        case .plus: return 1.30
        case .pencil: return 0.95
        default: return 1
        }
    }

    var body: some View {
        ZStack {
            Image(nsImage: Self.images[glyph]!)
                .resizable()
                .renderingMode(.template)
                .frame(width: size * opticalScale, height: size * opticalScale)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
    private static let resourceBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Menuminder_Menuminder", withExtension: "bundle"),
           let bundle = Bundle(url: url) { return bundle }
        return Bundle.module
    }()
    private static let images: [LucideGlyph: NSImage] = Dictionary(uniqueKeysWithValues: LucideGlyph.allCases.map { glyph in
        guard let url = resourceBundle.url(forResource: glyph.rawValue, withExtension: "png", subdirectory: "Assets/Lucide"),
              let image = NSImage(contentsOf: url) else { preconditionFailure("Missing Lucide resource") }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return (glyph, image)
    })
    static var menuImage: NSImage { images[.listTodo]! }

    static func nativeImage(_ glyph: LucideGlyph, size: CGFloat) -> NSImage {
        let image = images[glyph]!.copy() as! NSImage
        image.size = NSSize(width: size, height: size)
        return image
    }
}

extension TodoGroup {
    static let colors = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "gray"]
    var tint: Color { Self.tint(color) }
    static func tint(_ name: String) -> Color {
        PanelStyle.groupTint(name)
    }
    static func colorName(_ name: String) -> String {
        ["red": "朱砂", "orange": "赭石", "yellow": "杏黄", "green": "竹青", "blue": "黛蓝", "purple": "紫棠", "pink": "藕荷", "gray": "烟灰"][name] ?? name
    }
}
