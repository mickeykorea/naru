// Renders the Naru app icon (1024x1024 PNG): night-river gradient with
// three flowing current lines converging toward a landing point.
// Usage: swift scripts/make-icon.swift <output.png>

import AppKit

let size = CGFloat(1024)
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no context") }

let colors = [
    NSColor(srgbRed: 0.03, green: 0.06, blue: 0.11, alpha: 1).cgColor,
    NSColor(srgbRed: 0.07, green: 0.14, blue: 0.21, alpha: 1).cgColor,
]
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: colors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: 0, y: 0),
                       options: [])

let teal = NSColor(srgbRed: 0.45, green: 0.72, blue: 0.75, alpha: 1)

func wave(baseY: CGFloat, amplitude: CGFloat, phase: CGFloat, alpha: CGFloat, width: CGFloat) {
    let path = CGMutablePath()
    var first = true
    for x in stride(from: CGFloat(-40), through: size + 40, by: 4) {
        let progress = x / size
        // currents converge as they approach the right side — the landing
        let damp = 1.0 - progress * 0.55
        let y = baseY + sin(progress * .pi * 2.2 + phase) * amplitude * damp
        if first { path.move(to: CGPoint(x: x, y: y)); first = false }
        else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    ctx.setStrokeColor(teal.withAlphaComponent(alpha).cgColor)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.addPath(path)
    ctx.strokePath()
}

wave(baseY: 380, amplitude: 90, phase: 0.0, alpha: 0.35, width: 22)
wave(baseY: 460, amplitude: 110, phase: 1.1, alpha: 0.65, width: 26)
wave(baseY: 550, amplitude: 95, phase: 2.3, alpha: 1.0, width: 30)

// the landing: a full moon above the currents
let moonRect = CGRect(x: 660, y: 660, width: 180, height: 180)
ctx.setFillColor(NSColor(srgbRed: 0.93, green: 0.95, blue: 0.93, alpha: 1).cgColor)
ctx.fillEllipse(in: moonRect)
ctx.setFillColor(teal.withAlphaComponent(0.15).cgColor)
ctx.fillEllipse(in: moonRect.insetBy(dx: -30, dy: -30))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("failed to encode png")
}
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
