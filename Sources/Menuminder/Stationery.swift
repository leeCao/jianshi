import AppKit
import SwiftUI

enum StationeryAssets {
    static let bundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Menuminder_Menuminder", withExtension: "bundle"),
           let bundle = Bundle(url: url) { return bundle }
        return Bundle.module
    }()


}

struct DeskSurface: View {
    @Environment(\.colorScheme) private var colorScheme
    static let cornerRadius: CGFloat = 16
    static let windowOutset: CGFloat = 12

    private static let coating: NSImage = {
        guard let url = StationeryAssets.bundle.url(forResource: "coating", withExtension: "png", subdirectory: "Assets/Desk"),
              let image = NSImage(contentsOf: url) else { preconditionFailure("Missing desk coating") }
        return image
    }()

    private static let rim: NSImage = {
        guard let url = StationeryAssets.bundle.url(forResource: "soft-rim", withExtension: "png", subdirectory: "Assets/Desk"),
              let image = NSImage(contentsOf: url) else { preconditionFailure("Missing desk rim") }
        image.size = NSSize(width: 48, height: 48)
        return image
    }()

    var body: some View {
        let outline = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .circular)
        let dark = colorScheme == .dark

        ZStack {
            outline.fill(LinearGradient(stops: [
                .init(color: PanelStyle.canvas, location: 0),
                .init(color: PanelStyle.canvas, location: 0.12),
                .init(color: PanelStyle.canvasMiddle, location: 0.58),
                .init(color: PanelStyle.canvasBottom, location: 1)
            ], startPoint: .top, endPoint: .bottom))

            Image(nsImage: Self.coating)
                .resizable()
                .blendMode(.softLight)
                .opacity(dark ? 0.13 : 0.24)

            GeometryReader { geometry in
                let reach = max(geometry.size.width, geometry.size.height)
                RadialGradient(stops: [
                    .init(color: .white.opacity(dark ? 0.035 : 0.24), location: 0),
                    .init(color: .white.opacity(dark ? 0.029 : 0.20), location: 0.20),
                    .init(color: .white.opacity(dark ? 0.017 : 0.12), location: 0.45),
                    .init(color: .white.opacity(dark ? 0.005 : 0.035), location: 0.72),
                    .init(color: .clear, location: 1)
                ], center: UnitPoint(x: 0.46, y: 0.18), startRadius: 0,
                   endRadius: reach * 0.60)
                .overlay {
                    RadialGradient(stops: [
                        .init(color: .white.opacity(dark ? 0.015 : 0.14), location: 0),
                        .init(color: .white.opacity(dark ? 0.008 : 0.07), location: 0.40),
                        .init(color: .clear, location: 1)
                    ], center: UnitPoint(x: 0.57, y: 0.94), startRadius: 0, endRadius: reach * 0.56)
                }
            }

            DeskWindowShadows()
                .opacity(dark ? 0.20 : 1)

            // Fixed-size caps preserve one smooth edge profile through straight sides and corners.
            Image(nsImage: Self.rim)
                .resizable(capInsets: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20), resizingMode: .stretch)
                .mask(LinearGradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white.opacity(0.72), location: 0.45),
                    .init(color: .white.opacity(0.34), location: 1)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .opacity(dark ? 0.16 : 1)
        }
        .clipShape(outline)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct DeskWindowShadows: View {
    var body: some View {
        Canvas { context, size in
            // Parallel occluders project across the desk; papers above receive no overlay.
            context.addFilter(.blur(radius: 12))
            let slope: CGFloat = 0.38
            let left: CGFloat = -64
            let right = size.width + 64
            let bands: [(CGFloat, CGFloat)] = [
                (-0.34, 0.070), (-0.02, 0.050), (0.30, 0.065), (0.63, 0.055), (0.96, 0.060)
            ]
            for (position, width) in bands {
                let y = position * size.height
                let thickness = width * size.height
                var shadow = Path()
                shadow.move(to: CGPoint(x: left, y: y + left * slope))
                shadow.addLine(to: CGPoint(x: right, y: y + right * slope))
                shadow.addLine(to: CGPoint(x: right, y: y + right * slope + thickness))
                shadow.addLine(to: CGPoint(x: left, y: y + left * slope + thickness))
                shadow.closeSubpath()
                context.fill(shadow, with: .color(Color(red: 0.36, green: 0.32, blue: 0.26).opacity(0.07)))
            }
        }
    }
}

// Kept for the existing standalone component previews.
struct PaperSurface: View {
    var body: some View { PaperSheetSurface(fold: 18) }
}

struct BrushHighlight: View {
    @Environment(\.colorScheme) private var colorScheme

    private var pigment: Color {
        PanelStyle.adaptive(light: 0xB3986C, dark: 0xC4AC82)
    }

    var body: some View {
        Canvas { context, size in
            let outline = PaperBrushContour().path(in: CGRect(origin: .zero, size: size))
            context.fill(outline, with: .linearGradient(Gradient(stops: [
                .init(color: pigment.opacity(0.17), location: 0),
                .init(color: pigment.opacity(0.23), location: 0.12),
                .init(color: pigment.opacity(0.21), location: 0.78),
                .init(color: pigment.opacity(0.15), location: 1)
            ]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)))

            // Separate bristles carry pigment beyond the body, especially at the lifting end.
            for index in 0..<max(1, Int(size.height / 0.65)) {
                let y = 3 + CGFloat(index) * 0.65
                guard y < size.height - 3 else { continue }
                let grain = brushGrain(index, seed: 7)
                for trailing in [false, true] {
                    let start = trailing ? size.width - 12 - brushGrain(index, seed: 43) * 13 : 2 + grain * 4
                    let end = trailing ? size.width - 3 - grain * 9 : 10 + grain * 8
                    var bristle = Path()
                    bristle.move(to: CGPoint(x: start, y: y))
                    bristle.addLine(to: CGPoint(x: end, y: y - 0.25 + grain * 0.5))
                    context.stroke(bristle, with: .color(pigment.opacity(0.07 + grain * 0.10)),
                                   lineWidth: 0.3 + brushGrain(index, seed: 19) * 0.5)
                }
            }

            // Small dry gaps break the perimeter without blurring the paper underneath.
            context.blendMode = .destinationOut
            for index in 0..<max(1, Int(size.width / 2)) {
                let x = CGFloat(index) * 2 + brushGrain(index, seed: 2)
                for bottom in [false, true] {
                    let seed = bottom ? 31 : 13
                    let depth = 0.7 + brushGrain(index, seed: seed) * 5.2
                    let y = bottom ? size.height - depth - 1 : depth + 1
                    var gap = Path()
                    gap.move(to: CGPoint(x: x, y: y))
                    gap.addLine(to: CGPoint(x: x + 2 + brushGrain(index, seed: 17) * 8, y: y - 0.15))
                    context.stroke(gap, with: .color(.black.opacity(0.35 + brushGrain(index, seed: 5) * 0.6)),
                                   lineWidth: 0.4 + brushGrain(index, seed: 23) * 1.0)
                }
            }
            for index in 0..<max(12, Int(size.height / 2.2)) {
                let y = 4 + brushGrain(index, seed: 41) * max(0, size.height - 8)
                for trailing in [false, true] {
                    var gap = Path()
                    let reach = 7 + brushGrain(index, seed: trailing ? 47 : 53) * (trailing ? 11 : 6)
                    gap.move(to: CGPoint(x: trailing ? size.width - reach : 0, y: y))
                    gap.addLine(to: CGPoint(x: trailing ? size.width : reach, y: y + 0.15))
                    context.stroke(gap, with: .color(.black.opacity(0.50)),
                                   lineWidth: 0.3 + brushGrain(index, seed: 59) * 0.4)
                }
            }
        }
        .opacity(colorScheme == .dark ? 0.64 : 0.86)
        .padding(.vertical, 3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private func brushGrain(_ index: Int, seed: Int) -> CGFloat {
    let value = sin(Double(index * 127 + seed * 311)) * 43758.5453
    return CGFloat(value - floor(value))
}

private struct PaperBrushContour: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x, y: rect.minY + y)
        }
        let width = rect.width
        let height = rect.height
        let steps = max(1, Int(ceil(width / 0.7)))
        func edge(_ index: Int, phase: Int) -> CGFloat {
            let x = CGFloat(index) * 0.7
            return 1.3 + 0.7 * sin(x * 0.055 + CGFloat(phase))
                + pow(brushGrain(index, seed: phase), 2) * 3.3
        }
        path.move(to: point(6, edge(0, phase: 3)))
        for step in 1...steps {
            let x = 6 + (width - 20) * CGFloat(step) / CGFloat(steps)
            path.addLine(to: point(x, edge(step, phase: 3)))
        }
        let bristles = max(2, Int(ceil(height / 0.65)))
        for step in 0...bristles {
            let y = 3 + (height - 6) * CGFloat(step) / CGFloat(bristles)
            path.addLine(to: point(width - 7 - brushGrain(step, seed: 11) * 9, y))
        }
        for step in 0...steps {
            let x = width - 14 - (width - 20) * CGFloat(step) / CGFloat(steps)
            path.addLine(to: point(x, height - edge(step, phase: 29)))
        }
        for step in 0...bristles {
            let y = height - 3 - (height - 6) * CGFloat(step) / CGFloat(bristles)
            path.addLine(to: point(4 + brushGrain(step, seed: 37) * 5, y))
        }
        path.closeSubpath()
        return path
    }
}

private struct InkWashContour: Shape {
    var variation: CGFloat

    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            let edgeDepth = min(rect.height, 36)
            let vertical: CGFloat
            if y < 0.4 { vertical = y * edgeDepth }
            else if y > 0.6 { vertical = rect.height - (1 - y) * edgeDepth }
            else { vertical = y * rect.height }
            return CGPoint(x: rect.minX + x * rect.width, y: rect.minY + vertical)
        }
        let drift = variation * 0.035
        var path = Path()
        path.move(to: point(0.02, 0.50))
        path.addCurve(to: point(0.12, 0.24), control1: point(0.01, 0.32), control2: point(0.07, 0.25))
        path.addCurve(to: point(0.36, 0.19 + drift), control1: point(0.20, 0.13), control2: point(0.28, 0.24))
        path.addCurve(to: point(0.68, 0.21), control1: point(0.49, 0.13), control2: point(0.57, 0.25))
        path.addCurve(to: point(0.98, 0.46), control1: point(0.88, 0.13), control2: point(0.97, 0.32))
        path.addCurve(to: point(0.88, 0.74), control1: point(1.0, 0.64), control2: point(0.95, 0.72))
        path.addCurve(to: point(0.58, 0.81 - drift), control1: point(0.78, 0.82), control2: point(0.68, 0.75))
        path.addCurve(to: point(0.28, 0.76), control1: point(0.45, 0.85), control2: point(0.38, 0.70))
        path.addCurve(to: point(0.02, 0.50), control1: point(0.07, 0.88), control2: point(0.01, 0.69))
        path.closeSubpath()
        return path
    }
}

struct PencilCircle: Shape {
    func path(in rect: CGRect) -> Path {
        let steps = 80
        var outer: [CGPoint] = []
        var inner: [CGPoint] = []
        for index in 0...steps {
            let fraction = CGFloat(index) / CGFloat(steps)
            let angle = (-86 + fraction * 352) * .pi / 180
            let radius = 0.432 + 0.006 * sin(angle * 3 + 0.7) + 0.004 * cos(angle * 5)
            let pressure = 0.027 + 0.007 * sin(angle + 0.4) + 0.004 * cos(angle * 3 - 0.5)
            let taper = min(1, min(fraction, 1 - fraction) * 14 + 0.55)
            let halfWidth = pressure * taper
            outer.append(CGPoint(x: rect.midX + cos(angle) * (radius + halfWidth) * rect.width,
                                 y: rect.midY + sin(angle) * (radius + halfWidth) * rect.height))
            inner.append(CGPoint(x: rect.midX + cos(angle) * (radius - halfWidth) * rect.width,
                                 y: rect.midY + sin(angle) * (radius - halfWidth) * rect.height))
        }
        var path = Path()
        path.move(to: outer[0])
        for point in outer.dropFirst() { path.addLine(to: point) }
        for point in inner.reversed() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }
}

struct PencilCheck: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        var path = Path()
        path.move(to: point(0.145, 0.51))
        path.addCurve(to: point(0.35, 0.765), control1: point(0.20, 0.58), control2: point(0.28, 0.73))
        path.addQuadCurve(to: point(0.43, 0.74), control: point(0.395, 0.80))
        path.addCurve(to: point(0.905, 0.12), control1: point(0.59, 0.49), control2: point(0.79, 0.24))
        path.addCurve(to: point(0.865, 0.14), control1: point(0.90, 0.12), control2: point(0.88, 0.13))
        path.addCurve(to: point(0.37, 0.65), control1: point(0.68, 0.28), control2: point(0.50, 0.48))
        path.addQuadCurve(to: point(0.19, 0.47), control: point(0.27, 0.53))
        path.addQuadCurve(to: point(0.145, 0.51), control: point(0.155, 0.45))
        path.closeSubpath()
        return path
    }
}

struct PencilCheckTrace: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.53))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.39, y: rect.height * 0.71),
                         control: CGPoint(x: rect.width * 0.28, y: rect.height * 0.67))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.905, y: rect.height * 0.12),
                         control: CGPoint(x: rect.width * 0.65, y: rect.height * 0.34))
        return path
    }
}
