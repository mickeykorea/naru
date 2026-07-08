import SwiftUI
import UIKit

// Progressive ("variable") blur like the system status-bar frost in
// Messages: content stays saturated, defocusing toward the edge. There is
// no public API; this taps CAFilter("variableBlur") the way system apps
// do.
//
// CRITICAL: UIKit rebuilds UIVisualEffectView's internal layers on scene
// activation / trait changes and WIPES custom layer.filters — the frost
// then degrades to a uniform blur with a hard bottom edge (reproduced in
// the simulator by backgrounding and re-foregrounding twice). The filter
// must be re-asserted whenever the system clobbers it, not applied once.
struct VariableBlurView: UIViewRepresentable {
    var maxBlurRadius: CGFloat = 10

    func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius)
    }

    func updateUIView(_ uiView: VariableBlurUIView, context: Context) {}
}

final class VariableBlurUIView: UIVisualEffectView {

    private let maxBlurRadius: CGFloat
    private var variableBlur: NSObject?
    private var activationObserver: NSObjectProtocol?

    // the backdrop hosts a CABackdropLayer; on-device iOS 26 does not keep
    // it as subviews.first the way the simulator does, so match by layer
    // class instead of position
    private var backdrop: UIView? {
        subviews.first { String(describing: type(of: $0.layer)).contains("Backdrop") }
    }

    init(maxBlurRadius: CGFloat) {
        self.maxBlurRadius = maxBlurRadius
        super.init(effect: UIBlurEffect(style: .regular))
        applyFilter()
        activationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.applyFilter()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
    }

    // UIKit calls this on every effect rebuild, so it doubles as our hook
    // to win the last word; the identity check makes repeated calls free
    override func layoutSubviews() {
        super.layoutSubviews()
        applyFilter()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyFilter()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyFilter()
    }

    private func applyFilter() {
        guard let backdrop else { isHidden = true; return }

        if variableBlur == nil {
            variableBlur = Self.makeVariableBlur(radius: maxBlurRadius)
        }
        guard let variableBlur else { isHidden = true; return }
        isHidden = false

        let installed = (backdrop.layer.filters ?? [])
            .contains { ($0 as AnyObject) === variableBlur }
        if !installed {
            backdrop.layer.filters = [variableBlur]
        }

        if let window {
            backdrop.layer.setValue(window.screen.scale, forKey: "scale")
        }
        // tint/dimming layers add the milky veil; rebuilds restore them
        for subview in subviews where subview !== backdrop {
            subview.alpha = 0
        }
    }

    private static func makeVariableBlur(radius: CGFloat) -> NSObject? {
        guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let filter = filterClass
                .perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?
                .takeUnretainedValue() as? NSObject,
              let gradient = gradientMask() else {
            return nil
        }
        filter.setValue(radius, forKey: "inputRadius")
        filter.setValue(gradient, forKey: "inputMaskImage")
        filter.setValue(true, forKey: "inputNormalizeEdges")
        return filter
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
