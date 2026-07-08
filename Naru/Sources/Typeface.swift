import SwiftUI
import CoreText

// Inter, registered at runtime so both the app and the share extension can
// use it without Info.plist UIAppFonts plumbing (both targets generate
// their plists differently).
enum Typeface {
    private static let files = [
        "Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold", "Inter-ExtraBold",
    ]

    static func register() {
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    // BeReal type system in white: Inter with weight doing the hierarchy work
    static func inter(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name = switch weight {
        case .heavy, .black: "Inter-ExtraBold"
        case .bold: "Inter-Bold"
        case .semibold: "Inter-SemiBold"
        case .medium: "Inter-Medium"
        default: "Inter-Regular"
        }
        return .custom(name, size: size)
    }
}
