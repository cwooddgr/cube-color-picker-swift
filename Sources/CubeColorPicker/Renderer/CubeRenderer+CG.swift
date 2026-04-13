import SwiftUI
import CoreGraphics
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Color helpers

/// Convert a SwiftUI Color to a platform CGColor.
private func platformCGColor(_ color: Color) -> CGColor {
    #if canImport(UIKit)
    return UIColor(color).cgColor
    #elseif canImport(AppKit)
    return NSColor(color).cgColor
    #else
    return CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    #endif
}

// MARK: - Debug face colors (used when CubeColorPickerDebug.solidFaces == true)

private let DEBUG_FACE_COLORS: [CGColor] = [
    CGColor(srgbRed: 1.0, green: 0.2, blue: 0.2, alpha: 0.85), // top
    CGColor(srgbRed: 0.2, green: 1.0, blue: 0.2, alpha: 0.85), // right
    CGColor(srgbRed: 0.2, green: 0.4, blue: 1.0, alpha: 0.85), // left
]

// MARK: - Path helpers

private func quadPath(_ corners: [Vec2]) -> CGPath {
    let path = CGMutablePath()
    guard let first = corners.first else { return path }
    path.move(to: CGPoint(x: first.x, y: first.y))
    for i in 1..<corners.count {
        path.addLine(to: CGPoint(x: corners[i].x, y: corners[i].y))
    }
    path.closeSubpath()
    return path
}

private func ellipsePath(centerX: Double, centerY: Double, radius: Double) -> CGPath {
    let rect = CGRect(
        x: centerX - radius,
        y: centerY - radius,
        width: radius * 2,
        height: radius * 2
    )
    return CGPath(ellipseIn: rect, transform: nil)
}

// MARK: - Axis Lines

private func drawAxisLines(
    cg: CGContext,
    scale: Double,
    center: Vec2,
    mode: ColorMode
) {
    let origin = project(Vec3(x: 0, y: 0, z: 0), scale: scale, center: center)
    let tips = [
        project(Vec3(x: 1, y: 0, z: 0), scale: scale, center: center),
        project(Vec3(x: 0, y: 1, z: 0), scale: scale, center: center),
        project(Vec3(x: 0, y: 0, z: 1), scale: scale, center: center),
    ]
    let colors = AXIS_COLORS[modeIndex(mode)]

    cg.setLineWidth(1.5)
    cg.setLineCap(.butt)
    for i in 0..<tips.count {
        cg.setStrokeColor(platformCGColor(colors[i]))
        cg.beginPath()
        cg.move(to: CGPoint(x: origin.x, y: origin.y))
        cg.addLine(to: CGPoint(x: tips[i].x, y: tips[i].y))
        cg.strokePath()
    }
}

// MARK: - Face Rendering

private func renderFaceGradient(
    cg: CGContext,
    corners: [Vec2],
    faceIndex: Int,
    fixedAxis: Int,
    fixedVal: Double,
    uMax: Double,
    vMax: Double,
    mode: ColorMode,
    textureCache: FaceTextureCache?
) {
    // Solid debug fallback: bypass the texture entirely.
    if CubeColorPickerDebug.solidFaces {
        cg.saveGState()
        cg.addPath(quadPath(corners))
        cg.setFillColor(DEBUG_FACE_COLORS[faceIndex % DEBUG_FACE_COLORS.count])
        cg.fillPath()
        cg.restoreGState()
        return
    }

    let cgImageOpt: CGImage?
    if let textureCache = textureCache {
        cgImageOpt = textureCache.texture(
            faceIndex: faceIndex,
            fixedAxis: fixedAxis,
            fixedVal: fixedVal,
            uMax: uMax,
            vMax: vMax,
            mode: mode
        )
    } else {
        cgImageOpt = generateFaceTexture(
            fixedAxis: fixedAxis,
            fixedVal: fixedVal,
            uMax: uMax,
            vMax: vMax,
            mode: mode
        )
    }
    guard let cgImage = cgImageOpt else { return }

    let res = Double(FACE_RES)
    let p00 = corners[0]
    let p10 = corners[1]
    let p01 = corners[3]

    let ax = p10.x - p00.x
    let ay = p10.y - p00.y
    let bx = p01.x - p00.x
    let by = p01.y - p00.y

    // Slight extension so adjacent face seams don't show subpixel cracks.
    let extend = 2.0 / res
    let ox = p00.x - ax * extend - bx * extend
    let oy = p00.y - ay * extend - by * extend
    let sx = 1 + 2 * extend
    let sy = 1 + 2 * extend

    let transform = CGAffineTransform(
        a: (ax * sx) / res,
        b: (ay * sx) / res,
        c: (bx * sy) / res,
        d: (by * sy) / res,
        tx: ox,
        ty: oy
    )

    cg.saveGState()
    cg.addPath(quadPath(corners))
    cg.clip()
    cg.concatenate(transform)
    // UIView (iOS) and NSView with isFlipped=true (macOS) give us a y-down
    // user coord system. `cg.draw(cgImage, in:)` follows CG's y-up image
    // convention, which renders the texture upside-down relative to what our
    // (u, v) → quad-corner affine expects. Flip the image-local space here so
    // pixel (0, 0) lands at the quad's origin corner.
    cg.translateBy(x: 0, y: res)
    cg.scaleBy(x: 1, y: -1)
    cg.draw(cgImage, in: CGRect(x: 0, y: 0, width: res, height: res))
    cg.restoreGState()
}

// MARK: - Axis Labels

private func drawAxisLabels(
    cg: CGContext,
    mode: ColorMode,
    scale: Double,
    center: Vec2
) {
    let labels = mode.axisLabels
    let positions = [
        project(Vec3(x: 1, y: 0, z: 0), scale: scale, center: center),
        project(Vec3(x: 0, y: 1, z: 0), scale: scale, center: center),
        project(Vec3(x: 0, y: 0, z: 1), scale: scale, center: center),
    ]
    let offsets: [Vec2] = [
        Vec2(x: 14, y: 6),
        Vec2(x: -14, y: 6),
        Vec2(x: 0, y: -14),
    ]

    #if canImport(UIKit)
    let font = UIFont.systemFont(ofSize: 11)
    let color = UIColor.white.withAlphaComponent(0.45)
    #elseif canImport(AppKit)
    let font = NSFont.systemFont(ofSize: 11)
    let color = NSColor.white.withAlphaComponent(0.45)
    #endif

    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
    ]

    // Push the CGContext so NSAttributedString.draw uses it.
    #if canImport(UIKit)
    UIGraphicsPushContext(cg)
    defer { UIGraphicsPopContext() }
    #elseif canImport(AppKit)
    let nsContext = NSGraphicsContext(cgContext: cg, flipped: true)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsContext
    defer { NSGraphicsContext.restoreGraphicsState() }
    #endif

    for i in 0..<3 {
        let attrStr = NSAttributedString(string: labels[i], attributes: attrs)
        let textSize = attrStr.size()
        let cx = positions[i].x + offsets[i].x
        let cy = positions[i].y + offsets[i].y
        let origin = CGPoint(x: cx - textSize.width / 2.0, y: cy - textSize.height / 2.0)
        attrStr.draw(at: origin)
    }
}

// MARK: - Axis Handles

private func drawAxisHandles(
    cg: CGContext,
    verts2d: [Vec2],
    renderState rs: RenderState,
    mode: ColorMode
) {
    let handleVerts = [1, 2, 3]
    let colors = HANDLE_COLORS[modeIndex(mode)]

    for i in 0..<3 {
        let pos = verts2d[handleVerts[i]]
        let hovered = rs.hoveredAxisHandle == i
        let dragging = rs.draggingAxisHandle == i
        let radius: Double = dragging ? 8 : hovered ? 7 : 5

        if hovered || dragging {
            cg.setStrokeColor(platformCGColor(.white.opacity(0.25)))
            cg.setLineWidth(1.5)
            cg.addPath(ellipsePath(centerX: pos.x, centerY: pos.y, radius: radius + 5))
            cg.strokePath()
        }

        // White background circle.
        cg.setFillColor(platformCGColor(.white))
        cg.addPath(ellipsePath(centerX: pos.x, centerY: pos.y, radius: radius + 2))
        cg.fillPath()

        // Colored inner circle.
        cg.setFillColor(platformCGColor(colors[i]))
        cg.addPath(ellipsePath(centerX: pos.x, centerY: pos.y, radius: radius))
        cg.fillPath()
    }
}

// MARK: - Color Dot

private func drawColorDot(
    cg: CGContext,
    pos: Vec2,
    rgb: RGBColor
) {
    // Outer ring (white).
    cg.setFillColor(platformCGColor(.white))
    cg.addPath(ellipsePath(centerX: pos.x, centerY: pos.y, radius: 8))
    cg.fillPath()

    // Inner color fill.
    let inner = Color(
        red: Double(rgb.r) / 255.0,
        green: Double(rgb.g) / 255.0,
        blue: Double(rgb.b) / 255.0
    )
    cg.setFillColor(platformCGColor(inner))
    cg.addPath(ellipsePath(centerX: pos.x, centerY: pos.y, radius: 6))
    cg.fillPath()
}

// MARK: - Complete Render

/// The main render function that draws the entire cube scene into a CGContext.
///
/// The renderer assumes a top-left origin coordinate system. On macOS, the
/// hosting `NSView` should set `isFlipped = true`. UIKit views are top-left
/// origin natively.
func renderCubeScene(
    into cg: CGContext,
    size: CGSize,
    cubeExtent: Vec3,
    dotValues: Vec3,
    dotFace: Int,
    mode: ColorMode,
    renderState: RenderState,
    textureCache: FaceTextureCache?
) {
    let scale = cubeRenderScale(for: size)
    let center = Vec2(x: size.width / 2, y: size.height / 2)

    let verts3d = cubeVertices(extent: cubeExtent)
    let verts2d = verts3d.map { project($0, scale: scale, center: center) }

    drawAxisLines(cg: cg, scale: scale, center: center, mode: mode)

    for fi in 0..<FACES.count {
        let face = FACES[fi]
        let fixedVal = cubeExtent[face.fixedAxis]
        let uMax = cubeExtent[face.uAxis]
        let vMax = cubeExtent[face.vAxis]

        if uMax < 0.002 && vMax < 0.002 { continue }

        let corners = face.quad.map { verts2d[$0] }
        renderFaceGradient(
            cg: cg,
            corners: corners,
            faceIndex: fi,
            fixedAxis: face.fixedAxis,
            fixedVal: fixedVal,
            uMax: uMax,
            vMax: vMax,
            mode: mode,
            textureCache: textureCache
        )
    }

    drawAxisLabels(cg: cg, mode: mode, scale: scale, center: center)
    drawAxisHandles(cg: cg, verts2d: verts2d, renderState: renderState, mode: mode)

    if dotFace >= 0 {
        let rgb = ColorMath.valuesToRgb(dotValues, mode: mode)
        let dotPos = project(dotValues, scale: scale, center: center)
        drawColorDot(cg: cg, pos: dotPos, rgb: rgb)
    }
}
