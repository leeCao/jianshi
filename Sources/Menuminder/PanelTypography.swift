import SwiftUI
import AppKit
import CoreText

enum PanelTypography {
    private static let registered: Void = {
        let fonts = [
            ("JianshiTitle-Regular", "ttf"),
            ("LXGWWenKaiScreen", "ttf")
        ]
        for (name, ext) in fonts {
            guard let url = StationeryAssets.bundle.url(forResource: name, withExtension: ext, subdirectory: "Assets/Fonts") else {
                preconditionFailure("Missing bundled font: \(name)")
            }
            if NSFont(name: name, size: 16) == nil {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
            precondition(NSFont(name: name, size: 16) != nil, "Cannot load bundled font: \(name)")
        }
    }()

    private static func font(_ name: String, size: CGFloat) -> Font {
        _ = registered
        return .custom(name, size: size)
    }

    // Subset font: fixed page headings only; user content uses the complete WenKai font.
    static let appTitle = font("JianshiTitle-Regular", size: 24)
    static let heading = font("LXGWWenKaiScreen", size: 22)
    static let detailTitle = font("LXGWWenKaiScreen", size: 25)
    static let body = font("LXGWWenKaiScreen", size: 17).weight(.regular)
    static let toolbar = font("LXGWWenKaiScreen", size: 15).weight(.regular)
    static let secondary = font("LXGWWenKaiScreen", size: 14.5)
    static let control = Font.system(size: 13)
    static let caption = Font.system(size: 12)

    static var noteFont: NSFont {
        _ = registered
        return NSFont(name: "LXGWWenKaiScreen", size: 16)!
    }
}

enum PanelMetrics {
    static let canvasTopInset: CGFloat = 24
    static let headerHeight: CGFloat = 50
    static let expandedToolbarWidth: CGFloat = 760
    static let paperTopInset: CGFloat = 8
    static let pageInset: CGFloat = 20
    static let columnGap: CGFloat = 16
    static let groupHeaderHeight: CGFloat = 50
    static let actionIconSize: CGFloat = 15
    static let actionHitSize: CGFloat = 30
    static let toolbarHitSize: CGFloat = 36
    static let checkboxSize: CGFloat = 23
    static let checkboxHitSize: CGFloat = 32
    static let rowMinimumHeight: CGFloat = 52
    static let rowVerticalPadding: CGFloat = 10
    static let titleNoteGap: CGFloat = 4
    static let titleLineSpacing: CGFloat = 2
    static let noteLineSpacing: CGFloat = 1
    static let rowTextTopInset: CGFloat = 4
}
