import AppKit
import SwiftUI

struct RichTextEditor: NSViewRepresentable {
    @Binding var rtfdData: Data?
    var isEditable = true
    var inline = false

    func makeCoordinator() -> Coordinator {
        Coordinator(data: $rtfdData)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = !inline
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let textView = ImageTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.importsGraphics = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = inline ? .zero : NSSize(width: 10, height: 10)
        if inline { textView.textContainer?.lineFragmentPadding = 0 }
        textView.font = PanelTypography.noteFont
        textView.textColor = .labelColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.registerForDraggedTypes([.fileURL, .tiff, .png])
        context.coordinator.load(rtfdData, into: textView)

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.isEditable = isEditable
        if context.coordinator.lastWrittenData != rtfdData {
            context.coordinator.load(rtfdData, into: textView)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        guard inline, let width = proposal.width, width.isFinite, width > 0,
              let textView = nsView.documentView as? NSTextView,
              let container = textView.textContainer,
              let layout = textView.layoutManager else { return nil }
        container.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        layout.ensureLayout(for: container)
        let height = max(80, ceil(layout.usedRect(for: container).maxY))
        textView.setFrameSize(NSSize(width: width, height: height))
        return CGSize(width: width, height: height)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var data: Binding<Data?>
        var lastWrittenData: Data?

        init(data: Binding<Data?>) {
            self.data = data
        }

        func load(_ data: Data?, into textView: NSTextView) {
            defer {
                textView.typingAttributes = [.font: PanelTypography.noteFont, .foregroundColor: NSColor.labelColor]
            }
            lastWrittenData = data
            guard let data,
                  let attributed = try? NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtfd],
                    documentAttributes: nil
                  ) else {
                textView.string = ""
                return
            }
            let readable = NSMutableAttributedString(attributedString: attributed)
            attributed.enumerateAttribute(.font, in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
                let font = value as? NSFont ?? PanelTypography.noteFont
                let base = NSFontManager.shared.convert(PanelTypography.noteFont, toSize: max(16, font.pointSize))
                let traits = NSFontManager.shared.traits(of: font).intersection([.boldFontMask, .italicFontMask])
                let displayFont = NSFontManager.shared.convert(base, toHaveTrait: traits)
                readable.addAttribute(.font, value: displayFont, range: range)
            }
            textView.textStorage?.setAttributedString(readable)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let storage = textView.textStorage else { return }

            if storage.string.isEmpty && !storage.containsAttachments(in: NSRange(location: 0, length: storage.length)) {
                lastWrittenData = nil
                data.wrappedValue = nil
                return
            }

            let range = NSRange(location: 0, length: storage.length)
            let saved = try? storage.data(
                from: range,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
            )
            lastWrittenData = saved
            data.wrappedValue = saved
        }
    }
}

private final class ImageTextView: NSTextView {
    override func paste(_ sender: Any?) {
        guard isEditable else { return }
        if insertImages(from: NSPasteboard.general) { return }
        super.paste(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard isEditable else { return false }
        if insertImages(from: sender.draggingPasteboard) { return true }
        return super.performDragOperation(sender)
    }

    private func insertImages(from pasteboard: NSPasteboard) -> Bool {
        var images: [NSImage] = []

        if let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] {
            images.append(contentsOf: urls.compactMap(NSImage.init(contentsOf:)))
        }

        if images.isEmpty, let image = NSImage(pasteboard: pasteboard) {
            images.append(image)
        }

        guard !images.isEmpty else { return false }
        for image in images {
            let displayImage = resized(image, maxWidth: 310)
            let attachment: NSTextAttachment
            if let tiff = displayImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let png = bitmap.representation(using: .png, properties: [:]) {
                attachment = NSTextAttachment(data: png, ofType: "public.png")
                attachment.image = displayImage
            } else {
                attachment = NSTextAttachment()
                attachment.image = displayImage
            }
            let value = NSMutableAttributedString(attachment: attachment)
            value.append(NSAttributedString(string: "\n"))
            insertText(value, replacementRange: selectedRange())
        }
        return true
    }

    private func resized(_ image: NSImage, maxWidth: CGFloat) -> NSImage {
        guard image.size.width > maxWidth else { return image }
        let ratio = maxWidth / image.size.width
        let size = NSSize(width: maxWidth, height: image.size.height * ratio)
        let output = NSImage(size: size)
        output.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        output.unlockFocus()
        return output
    }
}

private extension NSAttributedString {
    func containsAttachments(in range: NSRange) -> Bool {
        var found = false
        enumerateAttribute(.attachment, in: range) { value, _, stop in
            if value != nil {
                found = true
                stop.pointee = true
            }
        }
        return found
    }
}
