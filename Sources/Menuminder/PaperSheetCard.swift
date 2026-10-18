import AppKit
import SwiftUI

struct PaperSheetCard<Content: View>: View {
    private let contentPadding: CGFloat
    private let textureVariant: Int
    private let content: Content

    init(contentPadding: CGFloat = 28, textureVariant: Int = 0, @ViewBuilder content: () -> Content) {
        self.contentPadding = contentPadding
        self.textureVariant = textureVariant
        self.content = content()
    }

    var body: some View {
        content
            .padding(contentPadding)
            .background {
                PaperSheetSurface(fold: 15, textureVariant: textureVariant)
            }
    }
}

struct PaperSheetSurface: View {
    let fold: CGFloat
    var textureVariant = 0
    @Environment(\.colorScheme) private var colorScheme

    private var dark: Bool { colorScheme == .dark }

    var body: some View {
        GeometryReader { geometry in
            let corner = min(fold, min(geometry.size.width, geometry.size.height) / 2)
            let outline = PaperOutline(fold: corner)
            ZStack(alignment: .topLeading) {
                outline.fill(PanelStyle.paper)
                    .overlay {
                        // Let the warm white stock show through the reference texture.
                        PaperFiber(variant: textureVariant).opacity(dark ? 0.085 : 0.32)
                    }
                    .overlay {
                        PaperIllumination(dark: dark)
                    }
                    .overlay {
                        PaperReferenceRim(dark: dark)
                    }
                    .clipShape(outline)
                    .shadow(color: Color.black.opacity(dark ? 0.25 : 0.12),
                            radius: 0.65, x: 0, y: 0.6)
                    .shadow(color: .black.opacity(dark ? 0.16 : 0.055), radius: 1.8, x: 0, y: 1.2)
                    .shadow(color: Color.black.opacity(dark ? 0.08 : 0.07),
                            radius: 6, x: 1, y: 3)

                // The reference contains the curved lip, crease and its local contact shadow.
                Image(nsImage: dark ? PaperReferenceAssets.darkCorner : PaperReferenceAssets.corner)
                    .resizable()
                    .frame(width: corner * 100 / 75, height: corner * 100 / 75)
                    .overlay(alignment: .topLeading) {
                        FoldLighting(dark: dark).frame(width: corner, height: corner)
                    }
                    .mask(LinearGradient(stops: [.init(color: .white, location: 0),
                                                 .init(color: .white, location: 0.82),
                                                 .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
                    .mask(LinearGradient(stops: [.init(color: .white, location: 0),
                                                 .init(color: .white, location: 0.82),
                                                 .init(color: .clear, location: 1)], startPoint: .leading, endPoint: .trailing))
                    .opacity(dark ? 0.36 : 0.56)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipShape(outline)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct PaperFiber: View {
    let variant: Int

    var body: some View {
        // Fixed texel density; resizing the sheet neither stretches fibers nor edges.
        Rectangle().fill(ImagePaint(image: Image(nsImage: PaperReferenceAssets.fiber), scale: 1))
            .overlay {
                Rectangle().fill(ImagePaint(image: Image(nsImage: PaperReferenceAssets.alternateFiber), scale: 1))
                    .mask(RadialGradient(colors: [.white.opacity(0.85), .white.opacity(0.45), .clear],
                                         center: variant == 1 ? .init(x: 0.30, y: 0.58) : (variant == 2 ? .init(x: 0.78, y: 0.36) : .init(x: 0.72, y: 0.63)),
                                         startRadius: variant == 2 ? 28 : 20, endRadius: variant == 1 ? 250 : 280))
            }
    }
}

private struct PaperIllumination: View {
    let dark: Bool

    var body: some View {
        GeometryReader { geometry in
            let reach = max(geometry.size.width, geometry.size.height)
            RadialGradient(colors: [.white.opacity(dark ? 0.025 : 0.06), .clear],
                           center: .init(x: 0.20, y: 0.12), startRadius: 0, endRadius: reach * 0.78)
                .overlay {
                    RadialGradient(colors: [Color(red: 0.58, green: 0.47, blue: 0.32).opacity(dark ? 0.02 : 0.012), .clear],
                                   center: .init(x: 0.90, y: 0.64), startRadius: 0, endRadius: reach * 0.48)
                }
                .overlay {
                    RadialGradient(colors: [.white.opacity(dark ? 0.012 : 0.025), .clear],
                                   center: .init(x: 0.38, y: 0.89), startRadius: 0, endRadius: reach * 0.36)
                }
        }
    }
}

private struct FoldLighting: View {
    let dark: Bool

    var body: some View {
        GeometryReader { geometry in
            let f = geometry.size.width
            let lip = Path { path in
                path.move(to: CGPoint(x: 0, y: f))
                path.addQuadCurve(to: CGPoint(x: f * 0.97, y: f * 0.94),
                                  control: CGPoint(x: f * 0.51, y: f * 0.91))
                path.addQuadCurve(to: CGPoint(x: f, y: 0),
                                  control: CGPoint(x: f * 0.93, y: f * 0.39))
            }
            lip.stroke(Color.brown.opacity(dark ? 0.14 : 0.10), lineWidth: 0.4)
                .blur(radius: 0.35)
            RadialGradient(colors: [.white.opacity(dark ? 0.035 : 0.12), .clear],
                           center: .init(x: 0.62, y: 0.55), startRadius: 0, endRadius: f * 0.48)
                .mask(Path { path in
                    path.move(to: CGPoint(x: 0, y: f))
                    path.addLine(to: CGPoint(x: f, y: 0))
                    path.addQuadCurve(to: CGPoint(x: f * 0.97, y: f * 0.94),
                                      control: CGPoint(x: f * 0.93, y: f * 0.39))
                    path.addQuadCurve(to: CGPoint(x: 0, y: f), control: CGPoint(x: f * 0.51, y: f * 0.91))
                })
        }
    }
}

struct PaperPrintedRule: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(stops: [.init(color: PanelStyle.paperPrint.opacity(0.18), location: 0),
                                         .init(color: PanelStyle.paperPrint.opacity(0.34), location: 0.22),
                                         .init(color: PanelStyle.paperPrint.opacity(0.28), location: 0.76),
                                         .init(color: PanelStyle.paperPrint.opacity(0.16), location: 1)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 0.35)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private enum PaperReferenceAssets {
    // The screenshot's 75px fold corresponds to 24pt. All crops retain that density.
    static let pixelsPerPoint: CGFloat = 75 / 24
    private static let source: CGImage = {
        guard let url = StationeryAssets.bundle.url(forResource: "reference-sheet", withExtension: "png", subdirectory: "Assets/Paper"),
              let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            preconditionFailure("Missing reference paper material")
        }
        return cgImage
    }()

    private static func crop(_ rect: CGRect) -> NSImage {
        guard let image = source.cropping(to: rect) else { preconditionFailure("Invalid paper material region") }
        return NSImage(cgImage: image, size: NSSize(width: rect.width / pixelsPerPoint, height: rect.height / pixelsPerPoint))
    }

    static let fiber = crop(CGRect(x: 140, y: 650, width: 800, height: 800))
    static let alternateFiber = crop(CGRect(x: 180, y: 780, width: 720, height: 700))
    static let corner = crop(CGRect(x: 40, y: 65, width: 100, height: 100))
    private static func darkened(_ image: NSImage) -> NSImage {
        let original = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmap = CGContext(data: nil, width: original.width, height: original.height, bitsPerComponent: 8, bytesPerRow: 0,
                               space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let rect = CGRect(x: 0, y: 0, width: original.width, height: original.height)
        bitmap.draw(original, in: rect)
        bitmap.setBlendMode(.multiply)
        bitmap.setFillColor(CGColor(gray: 0.27, alpha: 1))
        bitmap.fill(rect)
        return NSImage(cgImage: bitmap.makeImage()!, size: image.size)
    }
    static let top = crop(CGRect(x: 140, y: 65, width: 840, height: 28))
    static let left = crop(CGRect(x: 40, y: 620, width: 28, height: 800))
    static let right = crop(CGRect(x: 1013, y: 620, width: 28, height: 800))
    static let bottom = crop(CGRect(x: 100, y: 1511, width: 880, height: 28))
    static let topRight = crop(CGRect(x: 997, y: 65, width: 44, height: 44))
    static let bottomRight = crop(CGRect(x: 997, y: 1495, width: 44, height: 44))
    static let bottomLeft = crop(CGRect(x: 40, y: 1495, width: 44, height: 44))
    static let darkCorner = darkened(corner)
    static let darkTop = darkened(top)
    static let darkLeft = darkened(left)
    static let darkRight = darkened(right)
    static let darkBottom = darkened(bottom)
    static let darkTopRight = darkened(topRight)
    static let darkBottomRight = darkened(bottomRight)
    static let darkBottomLeft = darkened(bottomLeft)
}

private struct PaperReferenceRim: View {
    let dark: Bool
    private let band: CGFloat = 28 / PaperReferenceAssets.pixelsPerPoint
    private let radius: CGFloat = 44 / PaperReferenceAssets.pixelsPerPoint

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                strip(dark ? PaperReferenceAssets.darkTop : PaperReferenceAssets.top, start: .top, end: .bottom).frame(height: band)
                    .mask(wearMask(start: .leading, end: .trailing)).opacity(0.48)
            }
            .overlay(alignment: .leading) {
                strip(dark ? PaperReferenceAssets.darkLeft : PaperReferenceAssets.left, start: .leading, end: .trailing).frame(width: band)
                    .mask(wearMask(start: .top, end: .bottom)).opacity(0.55)
            }
            .overlay(alignment: .trailing) {
                strip(dark ? PaperReferenceAssets.darkRight : PaperReferenceAssets.right, start: .trailing, end: .leading).frame(width: band)
                    .mask(wearMask(start: .bottom, end: .top)).opacity(0.48)
            }
            .overlay(alignment: .bottom) {
                strip(dark ? PaperReferenceAssets.darkBottom : PaperReferenceAssets.bottom, start: .bottom, end: .top).frame(height: band)
                    .mask(wearMask(start: .trailing, end: .leading)).opacity(0.18)
            }
            .overlay(alignment: .topTrailing) {
                corner(dark ? PaperReferenceAssets.darkTopRight : PaperReferenceAssets.topRight, start: .topTrailing, end: .bottomLeading)
            }
            .overlay(alignment: .bottomTrailing) {
                corner(dark ? PaperReferenceAssets.darkBottomRight : PaperReferenceAssets.bottomRight, start: .bottomTrailing, end: .topLeading)
            }
            .overlay(alignment: .bottomLeading) {
                corner(dark ? PaperReferenceAssets.darkBottomLeft : PaperReferenceAssets.bottomLeft, start: .bottomLeading, end: .topTrailing)
            }
    }

    private func wearMask(start: UnitPoint, end: UnitPoint) -> some View {
        LinearGradient(stops: [.init(color: .clear, location: 0),
                               .init(color: .clear, location: 0.13),
                               .init(color: .white, location: 0.17),
                               .init(color: .clear, location: 0.22),
                               .init(color: .clear, location: 0.46),
                               .init(color: .white.opacity(0.7), location: 0.49),
                               .init(color: .clear, location: 0.52),
                               .init(color: .clear, location: 0.81),
                               .init(color: .white.opacity(0.8), location: 0.84),
                               .init(color: .clear, location: 0.89),
                               .init(color: .clear, location: 1)], startPoint: start, endPoint: end)
    }

    private func strip(_ image: NSImage, start: UnitPoint, end: UnitPoint) -> some View {
        Image(nsImage: image).resizable(resizingMode: .tile)
            .mask(LinearGradient(stops: [.init(color: .white, location: 0),
                                         .init(color: .white, location: 0.40),
                                         .init(color: .clear, location: 1)], startPoint: start, endPoint: end))
    }

    private func corner(_ image: NSImage, start: UnitPoint, end: UnitPoint) -> some View {
        Image(nsImage: image).resizable().frame(width: radius, height: radius)
            .mask(LinearGradient(stops: [.init(color: .white, location: 0),
                                         .init(color: .white.opacity(0.5), location: 0.22),
                                         .init(color: .clear, location: 0.65)], startPoint: start, endPoint: end))
            .opacity(0.4)
    }
}

struct PaperOutline: Shape {
    var fold: CGFloat

    func path(in rect: CGRect) -> Path {
        let f = min(fold, min(rect.width, rect.height) / 2)
            let r: CGFloat = min(3, min(rect.width, rect.height) / 8)
        var path = Path()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x, y: rect.minY + y)
        }
        // The missing triangle has no fill, texture, or backing rectangle.
        path.move(to: point(0, f))
        path.addQuadCurve(to: point(f, 0), control: point(f * 0.52, f * 0.52))
        func edge(from start: CGPoint, to end: CGPoint, inward: CGVector, phase: CGFloat, strength: CGFloat = 1) {
            let length = hypot(end.x - start.x, end.y - start.y)
            let steps = max(1, Int(ceil(length / 1.5)))
            for step in 1...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let distance = t * length
                let taper = min(1, min(distance, length - distance) / 6)
                var localWear: CGFloat = 0
                for (center, spread, depth) in [(CGFloat(47) + phase * 9, CGFloat(2.3), CGFloat(0.48)),
                                                (CGFloat(163) + phase * 11, CGFloat(3.6), CGFloat(0.62)),
                                                (CGFloat(337) + phase * 7, CGFloat(2.8), CGFloat(0.40))] {
                    let offset = (distance - center) / spread
                    localWear += depth * exp(-offset * offset)
                }
                let wear = (0.035 + localWear * (0.85 + 0.15 * sin(distance * 1.7))) * taper * strength
                path.addLine(to: CGPoint(x: start.x + (end.x - start.x) * t + inward.dx * wear,
                                        y: start.y + (end.y - start.y) * t + inward.dy * wear))
            }
        }
        edge(from: point(f, 0), to: point(rect.width - r, 0), inward: CGVector(dx: 0, dy: 1), phase: 0)
        path.addQuadCurve(to: point(rect.width, r), control: point(rect.width, 0))
        edge(from: point(rect.width, r), to: point(rect.width, rect.height - r), inward: CGVector(dx: -1, dy: 0), phase: 1.7)
        path.addQuadCurve(to: point(rect.width - r, rect.height), control: point(rect.width, rect.height))
        edge(from: point(rect.width - r, rect.height), to: point(r, rect.height), inward: CGVector(dx: 0, dy: -1), phase: 3.2, strength: 0.28)
        path.addQuadCurve(to: point(0, rect.height - r), control: point(0, rect.height))
        edge(from: point(0, rect.height - r), to: point(0, f), inward: CGVector(dx: 1, dy: 0), phase: 4.6)
        path.closeSubpath()
        return path
    }
}

struct PaperSheetCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaperSheetCard { Color.clear.frame(width: 254, height: 364) }
                .previewDisplayName("空白纸张 · 18pt 折角")
            PaperSheetTaskPreview()
                .previewDisplayName("原生任务内容")
            HStack(alignment: .top, spacing: 28) {
                PaperSheetCard { Color.clear }.frame(width: 160, height: 220)
                PaperSheetCard { Color.clear }.frame(width: 310, height: 440)
                PaperSheetCard { Color.clear }.frame(width: 450, height: 180)
            }
            .previewDisplayName("不同尺寸 · 固定折角与纤维比例")
        }
        .padding(32)
        .background { DeskSurface() }
        .previewLayout(.sizeThatFits)
    }
}

struct PaperSheetTaskPreview: View {
    var body: some View {
        PaperSheetCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 8) {
                    Circle().fill(PanelStyle.groupTint("blue")).frame(width: 8, height: 8)
                    Text("当日待办").font(PanelTypography.heading)
                    Spacer()
                    LucideIcon(glyph: .plus, size: 18)
                }
                PaperPrintedRule()
                ForEach(["公众号文章", "Harness"], id: \.self) { title in
                    HStack(spacing: 12) {
                        TodoCheckbox(isCompleted: true, action: {})
                        Text(title).font(PanelTypography.body).foregroundStyle(PanelStyle.taskInk)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(PanelStyle.ink)
        .frame(width: 310, height: 440)
    }
}
