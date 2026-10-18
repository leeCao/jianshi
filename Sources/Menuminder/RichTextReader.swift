import AppKit
import SwiftUI

// A non-scrolling text view: the surrounding SwiftUI scroll view owns scrolling.
// TextKit measures both wrapped text and RTFD image attachments at the available width.
struct RichTextReader: NSViewRepresentable {
    let rtfdData: Data

    func makeCoordinator() -> RichTextEditor.Coordinator {
        RichTextEditor.Coordinator(data: .constant(rtfdData))
    }

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView(frame: .zero)
        view.isEditable = false
        view.isSelectable = true
        view.isRichText = true
        view.drawsBackground = false
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        view.textContainer?.widthTracksTextView = true
        context.coordinator.load(rtfdData, into: view)
        return view
    }

    func updateNSView(_ view: NSTextView, context: Context) {
        if context.coordinator.lastWrittenData != rtfdData {
            context.coordinator.load(rtfdData, into: view)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0,
              let container = nsView.textContainer,
              let layout = nsView.layoutManager else { return nil }
        container.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        layout.ensureLayout(for: container)
        let height = ceil(layout.usedRect(for: container).maxY)
        return CGSize(width: width, height: max(1, height))
    }
}
