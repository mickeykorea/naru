import SwiftUI
import UIKit

// Progressive ("variable") blur like the system status-bar frost in
// Messages: content stays saturated, defocusing toward the edge. There is
// no public API; this taps CAFilter("variableBlur") the way system apps
// do. Every private-structure assumption is checked — if any fails, the
// view hides itself: no frost beats a broken white box.
struct VariableBlurView: UIViewRepresentable {
    var maxBlurRadius: CGFloat = 10

    func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius)
    }

    func updateUIView(_ uiView: VariableBlurUIView, context: Context) {}
}

final class VariableBlurUIView: UIVisualEffectView {

    // the backdrop hosts a CABackdropLayer; on-device iOS 26 does not keep
    // it as subviews.first the way the simulator does, so match by layer
    // class instead of position
    private var backdrop: UIView? {
        subviews.first { String(describing: type(of: $0.layer)).contains("Backdrop") }
    }

    init(maxBlurRadius: CGFloat) {
        super.init(effect: UIBlurEffect(style: .regular))

        guard let backdrop,
              let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let variableBlur = filterClass
                .perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?
                .takeUnretainedValue() as? NSObject,
              let gradient = Self.gradientMask() else {
            isHidden = true
            return
        }

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradient, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")
        backdrop.layer.filters = [variableBlur]

        // remaining effect subviews are tint/dimming layers — they add the
        // milky veil, so drop them
        for subview in subviews where subview !== backdrop {
            subview.alpha = 0
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // keep the filter's coordinate space aligned with the screen scale;
        // without this the blurred sample renders offset/magnified
        guard let window, let backdrop else { return }
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
                var t = CGFloat(y) / CGFloat(height - 1)
                // the device GPU samples the mask bottom-up while the
                // simulator samples top-down; without this the full-radius
                // end of the ramp lands on the header instead of the edge
                #if !targetEnvironment(simulator)
                t = 1 - t
                #endif
                let eased = (1 - t) * (1 - t)
                ctx.cgContext.setFillColor(UIColor.black.withAlphaComponent(eased).cgColor)
                ctx.cgContext.fill(CGRect(x: 0, y: CGFloat(y), width: 1, height: 1))
            }
        }
        return image.cgImage
    }
}
