import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// Progressive ("variable") blur like the system status-bar frost in
// Messages: content stays saturated, defocusing toward the edge. There is
// no public API; this taps CAFilter("variableBlur") the way system apps
// do. If App Review ever objects, swap for the gradient-masked material.
struct VariableBlurView: UIViewRepresentable {
    var maxBlurRadius: CGFloat = 10

    func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius)
    }

    func updateUIView(_ uiView: VariableBlurUIView, context: Context) {}
}

final class VariableBlurUIView: UIVisualEffectView {

    init(maxBlurRadius: CGFloat) {
        super.init(effect: UIBlurEffect(style: .regular))

        guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let variableBlur = filterClass
                .perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?
                .takeUnretainedValue() as? NSObject,
              let gradient = Self.gradientMask() else {
            return
        }

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradient, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        // first subview is the backdrop (gets the filter); the rest are
        // tint/dimming layers that would add the milky veil — drop them
        if let backdrop = subviews.first {
            backdrop.layer.filters = [variableBlur]
        }
        for extraneous in subviews.dropFirst() {
            extraneous.alpha = 0
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // keep the filter's coordinate space upright regardless of screen scale
        guard let window, let backdrop = subviews.first else { return }
        backdrop.layer.setValue(window.screen.scale, forKey: "scale")
    }

    // vertical alpha ramp: opaque (full blur) at top -> clear at bottom
    private static func gradientMask() -> CGImage? {
        let size = CGSize(width: 1, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors as CFArray,
                                            locations: [0, 1]) else { return }
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: [])
        }
        return image.cgImage
    }
}
