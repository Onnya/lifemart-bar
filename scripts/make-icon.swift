// Draws the 1024×1024 app icon: a takeaway bag with speed lines on a
// green macOS-style squircle (greens taken from lifemart.ru styles). Run through scripts/make-icon.sh, which turns
// the PNG into Resources/AppIcon.icns.
import AppKit

let size: CGFloat = 1024
let output = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

// Body: the standard macOS icon grid keeps 100 px of margin for the shadow.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0x000000, 0.3))
ctx.addPath(bodyPath)
ctx.setFillColor(rgb(0x3F9E37))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(bodyPath)
ctx.clip()
let gradient = CGGradient(
    colorsSpace: space, colors: [rgb(0x5CBC54), rgb(0x3F9E37)] as CFArray, locations: [0, 1]
)!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])
ctx.restoreGState()

// Bag and speed lines are drawn around x = 460; shift them so the group is centred.
ctx.translateBy(x: 52, y: 0)

// Bag: a trapezoid with rounded corners.
let white = rgb(0xFFFFFF)
let bagBottom: CGFloat = 250, bagTop: CGFloat = 630
let bag = CGMutablePath()
let corners = [
    CGPoint(x: 370, y: bagBottom), CGPoint(x: 770, y: bagBottom),
    CGPoint(x: 745, y: bagTop), CGPoint(x: 395, y: bagTop),
]
bag.move(to: CGPoint(x: 570, y: bagBottom))
for i in 0..<4 {
    bag.addArc(tangent1End: corners[(i + 1) % 4], tangent2End: corners[(i + 2) % 4], radius: 44)
}
bag.closeSubpath()
ctx.addPath(bag)
ctx.setFillColor(white)
ctx.fillPath()

// Handle.
ctx.setStrokeColor(white)
ctx.setLineWidth(36)
ctx.setLineCap(.round)
ctx.addArc(center: CGPoint(x: 570, y: bagTop), radius: 95, startAngle: 0, endAngle: .pi, clockwise: false)
ctx.strokePath()

// Speed lines to the left of the bag.
for (y, length) in [(500.0, 120.0), (430.0, 170.0), (360.0, 95.0)] {
    let line = CGRect(x: 320 - length, y: y, width: length, height: 32)
    ctx.addPath(CGPath(roundedRect: line, cornerWidth: 16, cornerHeight: 16, transform: nil))
}
ctx.setFillColor(rgb(0xFFFFFF, 0.9))
ctx.fillPath()

let image = ctx.makeImage()!
let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
