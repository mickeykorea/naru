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

    // vertical alpha ramp: opaque (full blur) at top -> clear at bottom.
    // A linear ramp leaves residual radius at the band's bottom edge, which
    // renders as a visible seam where the frame ends; ease the decay so the
    // radius genuinely hits zero before the edge and the blur just dissolves.
    private static func gradientMask() -> CGImage? {
        let height = 128
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: CGFloat(height)))
        let image = renderer.image { ctx in
            for y in 0..<height {
                let t = CGFloat(y) / CGFloat(height - 1)
                let eased = (1 - t) * (1 - t)
                ctx.cgContext.setFillColor(UIColor.black.withAlphaComponent(eased).cgColor)
                ctx.cgContext.fill(CGRect(x: 0, y: CGFloat(y), width: 1, height: 1))
            }
        }
        return image.cgImage
    }
}
