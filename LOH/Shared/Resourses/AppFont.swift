import SwiftUI
import UIKit

/// Customer-app typography shared by SwiftUI and UIKit.
enum AppFont {
    enum Weight: String, CaseIterable {
        case extraLight = "ExtraLight", light = "Light", regular = "Regular", medium = "Medium"
        case bold = "Bold", extraBold = "ExtraBold", black = "Black"
        var postScriptName: String { "Tajawal-\(rawValue)" }
    }
    static func font(_ weight: Weight, size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.postScriptName, size: size, relativeTo: style)
    }
    static func black(size: CGFloat) -> Font { font(.black, size: size) }
    static func extraBold(size: CGFloat) -> Font { font(.extraBold, size: size) }
    static func bold(size: CGFloat) -> Font { font(.bold, size: size) }
    // Tajawal has no SemiBold face; use the design's Bold weight for legacy callers.
    static func semiBold(size: CGFloat) -> Font { font(.bold, size: size) }
    static func medium(size: CGFloat) -> Font { font(.medium, size: size) }
    static func regular(size: CGFloat) -> Font { font(.regular, size: size) }
    static func light(size: CGFloat) -> Font { font(.light, size: size) }
    static func uiFont(_ weight: Weight = .regular, size: CGFloat = 15,
                       relativeTo style: UIFont.TextStyle = .body) -> UIFont {
        let font = UIFont(name: weight.postScriptName, size: size) ?? .systemFont(ofSize: size)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }
    static let caption = font(.regular, size: 12, relativeTo: .caption)
    static let body = font(.regular, size: 14)
    static let fieldLabel = font(.medium, size: 15)
    static let button = font(.bold, size: 16, relativeTo: .body)
    static let mediumButton = font(.medium, size: 16, relativeTo: .body)
    static let navigationTitle = font(.bold, size: 17, relativeTo: .headline)
    static let heading = font(.extraBold, size: 24, relativeTo: .title2)
    static let brandTagline = Font.custom("Inter18pt-Regular", fixedSize: 12)
}
