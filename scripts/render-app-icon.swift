import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

let S: CGFloat = 1024
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                    bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// white ground
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: S, height: S))

// CoreGraphics origin is bottom-left; design in top-left coords and flip
ctx.translateBy(x: 0, y: S)
ctx.scaleBy(x: 1, y: -1)

ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))

func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

// ------- hull: ferry silhouette, gently sagging deck, upturned ends -------
let hull = CGMutablePath()
hull.move(to: P(216.5, 684.5))
// deck: barely-there sag
hull.addQuadCurve(to: P(808.5, 684.5), control: P(512.5, 698.5))
// right end: upturned stern
hull.addCurve(to: P(748.5, 812.5), control1: P(812.5, 726.5), control2: P(794.5, 788.5))
// belly: shallow arc
hull.addQuadCurve(to: P(276.5, 812.5), control: P(512.5, 836.5))
// left end back up to the bow tip
hull.addCurve(to: P(216.5, 684.5), control1: P(230.5, 788.5), control2: P(212.5, 726.5))
hull.closeSubpath()
ctx.addPath(hull)
ctx.fillPath()

// ------- main sail (right): tall, luff bowed, leech billowed -------
let main = CGMutablePath()
main.move(to: P(539.5, 200.5))                                  // head
// luff: near-vertical, faint bow
main.addCurve(to: P(523.5, 628.5), control1: P(529.5, 342.5), control2: P(519.5, 522.5))
// foot: soft run aft
main.addQuadCurve(to: P(745.5, 628.5), control: P(635.5, 640.5))
// leech: gentle outward billow up to the head
main.addCurve(to: P(539.5, 200.5), control1: P(719.5, 448.5), control2: P(613.5, 264.5))
main.closeSubpath()
ctx.addPath(main)
ctx.fillPath()

// ------- fore sail (left): smaller, mirrored energy -------
let fore = CGMutablePath()
fore.move(to: P(455.5, 360.5))                                  // head
// aft edge: near-vertical, slight bow
fore.addCurve(to: P(463.5, 628.5), control1: P(463.5, 448.5), control2: P(467.5, 552.5))
// foot: short, gentle sag
fore.addQuadCurve(to: P(279.5, 628.5), control: P(371.5, 640.5))
// luff: soft sweep up to the head
fore.addCurve(to: P(455.5, 360.5), control1: P(335.5, 522.5), control2: P(403.5, 412.5))
fore.closeSubpath()
ctx.addPath(fore)
ctx.fillPath()

let img = ctx.makeImage()!
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote", out.path)
