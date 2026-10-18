import AppKit
import SwiftUI

private enum ArchivePaperAssets {
    static let sheet: NSImage = {
        guard let url = StationeryAssets.bundle.url(forResource: "archive-cotton-sheet-v2", withExtension: "png", subdirectory: "Assets/Paper"),
              let image = NSImage(contentsOf: url) else {
            preconditionFailure("Missing archive cotton paper material")
        }
        image.size = NSSize(width: 240, height: 360)
        return image
    }()

}

struct ArchivePrintedRule: View {
    var body: some View {
        Image(nsImage: ArchivePaperAssets.sheet)
            .resizable()
            .colorMultiply(PanelStyle.paperPrint)
            .opacity(0.28)
            .frame(height: 0.35)
            .shadow(color: .white.opacity(0.55), radius: 0, x: 0, y: 0.4)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct ArchiveCompletionMark: ViewModifier {
    let text: String
    let size: CGFloat
    let lineSpacing: CGFloat
    let lineLimit: Int
    let enabled: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if enabled {
                Canvas { context, bounds in
                    let font = NSFontManager.shared.convert(PanelTypography.noteFont, toSize: size)
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.lineSpacing = lineSpacing
                    let storage = NSTextStorage(string: text, attributes: [.font: font, .paragraphStyle: paragraph])
                    let layout = NSLayoutManager()
                    let container = NSTextContainer(size: NSSize(width: bounds.width, height: .greatestFiniteMagnitude))
                    container.lineFragmentPadding = 0
                    container.maximumNumberOfLines = lineLimit
                    container.lineBreakMode = .byTruncatingTail
                    layout.addTextContainer(container)
                    storage.addLayoutManager(layout)
                    layout.ensureLayout(for: container)
                    let measured = layout.usedRect(for: container)
                    var strokes = Path()
                    layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(for: container)) { _, used, _, _, _ in
                        let y = (used.midY - measured.minY) * bounds.height / measured.height
                        strokes.move(to: CGPoint(x: used.minX, y: y))
                        strokes.addLine(to: CGPoint(x: used.maxX, y: y))
                    }
                    context.stroke(strokes, with: .color(PanelStyle.muted.opacity(0.24)), lineWidth: 0.28)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}
