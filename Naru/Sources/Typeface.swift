import SwiftUI
import CoreText

// EB Garamond (Google Fonts, OFL) is the accent voice — text-only tiles
// and summary body copy. Registered at runtime so no Info.plist plumbing;
// SF Pro remains the UI font everywhere else.
enum Typeface {
    private static let files = [
        "EBGaramond-Regular", "EBGaramond-Medium", "EBGaramond-SemiBold",
    ]

    static func register() {
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    // Garamond runs small on the body — size up ~2pt vs the SF equivalent
    static func garamond(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name = switch weight {
        case .semibold, .bold: "EBGaramond-SemiBold"
        case .medium: "EBGaramond-Medium"
        default: "EBGaramond-Regular"
        }
        return .custom(name, size: size)
    }
}
