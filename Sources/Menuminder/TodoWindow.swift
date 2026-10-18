import AppKit

final class TodoWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        // Use orderOut for dismissal so isVisible agrees with what the user sees.
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
    }

    // Borderless panels must opt in to keyboard focus for text editing.
    override var canBecomeKey: Bool { true }
}

final class PanelBackgroundView: NSView {
    private let surfaceInset: CGFloat
    private let cornerRadius: CGFloat
    private let fillColor: NSColor

    init(contentView: NSView, surfaceInset: CGFloat, cornerRadius: CGFloat, fillColor: NSColor) {
        self.surfaceInset = surfaceInset
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        super.init(frame: contentView.frame)
        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentView.frame = bounds
        contentView.autoresizingMask = [.width, .height]
        addSubview(contentView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        // WindowServer needs native backing pixels to hit-test this clear, SwiftUI-layered window.
        fillColor.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: surfaceInset, dy: surfaceInset),
                     xRadius: cornerRadius, yRadius: cornerRadius).fill()
    }
}
