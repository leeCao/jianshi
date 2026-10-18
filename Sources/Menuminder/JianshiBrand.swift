import AppKit
import SwiftUI

enum JianshiBrand {
    static let name = "笺事"

    static let menuImage: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            NSColor.black.setFill()
            let paper = NSBezierPath()
            paper.move(to: NSPoint(x: 6, y: 2))
            paper.line(to: NSPoint(x: 13.2, y: 1.5))
            paper.curve(to: NSPoint(x: 14.5, y: 2.8), controlPoint1: NSPoint(x: 14.1, y: 1.45), controlPoint2: NSPoint(x: 14.5, y: 1.9))
            paper.line(to: NSPoint(x: 15, y: 14.8))
            paper.curve(to: NSPoint(x: 13.8, y: 16), controlPoint1: NSPoint(x: 15, y: 15.6), controlPoint2: NSPoint(x: 14.6, y: 16))
            paper.line(to: NSPoint(x: 4.2, y: 16.5))
            paper.curve(to: NSPoint(x: 3, y: 15.3), controlPoint1: NSPoint(x: 3.4, y: 16.55), controlPoint2: NSPoint(x: 3, y: 16.1))
            paper.line(to: NSPoint(x: 2.75, y: 5.5))
            paper.close()
            paper.fill()

            let context = NSGraphicsContext.current!.cgContext
            context.saveGState()
            context.setBlendMode(.clear)
            context.addPath(JianshiCheck().path(in: CGRect(x: 0, y: 0, width: 11, height: 12))
                .offsetBy(dx: 3.6, dy: 3).cgPath)
            context.fillPath()
            context.restoreGState()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = name
        return image
    }()
}

private struct JianshiCheck: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 23, y: 88))
            p.addCurve(to: CGPoint(x: 36, y: 91), control1: CGPoint(x: 26, y: 82), control2: CGPoint(x: 32, y: 86))
            p.addCurve(to: CGPoint(x: 56, y: 109), control1: CGPoint(x: 43, y: 97), control2: CGPoint(x: 49, y: 105))
            p.addCurve(to: CGPoint(x: 130, y: 43), control1: CGPoint(x: 73, y: 89), control2: CGPoint(x: 111, y: 54))
            p.addQuadCurve(to: CGPoint(x: 140, y: 38), control: CGPoint(x: 136, y: 40))
            p.addCurve(to: CGPoint(x: 107, y: 77), control1: CGPoint(x: 128, y: 51), control2: CGPoint(x: 117, y: 63))
            p.addCurve(to: CGPoint(x: 67, y: 128), control1: CGPoint(x: 91, y: 98), control2: CGPoint(x: 79, y: 119))
            p.addCurve(to: CGPoint(x: 51, y: 128), control1: CGPoint(x: 62, y: 133), control2: CGPoint(x: 56, y: 131))
            p.addCurve(to: CGPoint(x: 23, y: 88), control1: CGPoint(x: 42, y: 120), control2: CGPoint(x: 30, y: 99))
            p.closeSubpath()
        }.applying(CGAffineTransform(scaleX: rect.width / 152, y: rect.height / 168))
    }
}
