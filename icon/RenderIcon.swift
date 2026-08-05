// Draws the USAirQMinder app icon and writes a 1024×1024 PNG.
//
//   swiftc icon/RenderIcon.swift -o /tmp/rendericon
//   /tmp/rendericon USAirQMinder/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// This exists because the icon arrived as a flat PNG with no editable source.
// Keeping the drawing as code means the next change — a colour, a thicker
// wave — is an edit here rather than a trip through a design tool.
//
// The design is AirQMinder's, in indigo rather than teal: a dial arc reading
// clockwise from the top, a green tip at its end, and three air waves. The
// waves use the same curve as the widget background in AQIWidget.swift.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024

// Indigo. Deliberately clear of all six EPA AQI band colours — an icon in
// green, yellow, orange, red or purple reads as a permanent air-quality
// state — and far enough from AirQMinder's teal to tell them apart on a
// home screen holding both.
let gradientTop = CGColor(red: 0.106, green: 0.165, blue: 0.420, alpha: 1) // #1B2A6B
let gradientBottom = CGColor(red: 0.239, green: 0.435, blue: 0.851, alpha: 1) // #3D6FD9
let arcColor = CGColor(red: 0.620, green: 0.894, blue: 0.969, alpha: 1) // #9EE4F7
let tipColor = CGColor(red: 0.714, green: 0.910, blue: 0.627, alpha: 1) // #B6E8A0

guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("could not create context") }

// Geometry is written in screen coordinates (y down, as in the design) and
// converted on the way out, which keeps the numbers readable.
func y(_ screenY: CGFloat) -> CGFloat { size - screenY }

// MARK: Background

let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [gradientTop, gradientBottom] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: y(0)),
    end: CGPoint(x: 0, y: y(size)),
    options: []
)

// MARK: Dial

let center = CGPoint(x: 512, y: y(452))
let radius: CGFloat = 276
let ringWidth: CGFloat = 88

// The full ring sits faintly behind, so the arc reads as progress along it.
context.setStrokeColor(CGColor(gray: 1, alpha: 0.22))
context.setLineWidth(ringWidth)
context.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
context.strokePath()

let sweep: CGFloat = 285 * .pi / 180
let startAngle: CGFloat = .pi / 2          // top of the circle
let endAngle = startAngle - sweep          // clockwise on screen

context.setStrokeColor(arcColor)
context.setLineWidth(ringWidth)
context.setLineCap(.round)
context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
context.strokePath()

// The tip rides the dial at roughly five o'clock, as in AirQMinder — a
// marker part-way along the arc rather than its end.
let tipAngle: CGFloat = -61 * .pi / 180
let tip = CGPoint(
    x: center.x + radius * cos(tipAngle),
    y: center.y + radius * sin(tipAngle)
)
context.setFillColor(tipColor)
context.addArc(center: tip, radius: 47, startAngle: 0, endAngle: .pi * 2, clockwise: false)
context.fillPath()

// MARK: Air waves

func drawWave(atScreenY screenY: CGFloat, opacity: CGFloat) {
    let waveY = y(screenY)
    context.setStrokeColor(CGColor(gray: 1, alpha: opacity))
    context.setLineWidth(36)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: size * 0.08, y: waveY))
    context.addCurve(
        to: CGPoint(x: size * 0.92, y: waveY),
        control1: CGPoint(x: size * 0.36, y: waveY - size * 0.035),
        control2: CGPoint(x: size * 0.64, y: waveY + size * 0.035)
    )
    context.strokePath()
}

drawWave(atScreenY: 712, opacity: 1.00)
drawWave(atScreenY: 794, opacity: 0.55)
drawWave(atScreenY: 876, opacity: 0.35)

// MARK: Write

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
guard let image = context.makeImage() else { fatalError("could not render image") }
let url = URL(fileURLWithPath: outputPath)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("could not create \(outputPath)")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(outputPath)") }
print("Wrote \(outputPath) at \(Int(size))×\(Int(size))")
