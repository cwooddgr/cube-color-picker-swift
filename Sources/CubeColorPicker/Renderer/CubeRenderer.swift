import SwiftUI
import CoreGraphics

// MARK: - Color Constants

/// Axis line colors per mode (translucent).
let AXIS_COLORS: [[Color]] = [
    // rgb
    [Color(red: 1.0, green: 0.392, blue: 0.392).opacity(0.4),
     Color(red: 0.392, green: 1.0, blue: 0.392).opacity(0.4),
     Color(red: 0.392, green: 0.588, blue: 1.0).opacity(0.4)],
    // hsb
    [Color(red: 1.0, green: 0.392, blue: 0.392).opacity(0.4),
     Color(red: 0.392, green: 1.0, blue: 0.392).opacity(0.4),
     Color(red: 0.392, green: 0.588, blue: 1.0).opacity(0.4)],
    // oklch
    [Color(red: 0.863, green: 0.863, blue: 0.863).opacity(0.4),
     Color(red: 1.0, green: 0.706, blue: 0.235).opacity(0.4),
     Color(red: 0.706, green: 0.471, blue: 1.0).opacity(0.4)],
]

/// Axis handle fill colors per mode (mostly opaque).
let HANDLE_COLORS: [[Color]] = [
    // rgb
    [Color(red: 1.0, green: 0.392, blue: 0.392).opacity(0.9),
     Color(red: 0.392, green: 1.0, blue: 0.392).opacity(0.9),
     Color(red: 0.392, green: 0.588, blue: 1.0).opacity(0.9)],
    // hsb
    [Color(red: 1.0, green: 0.392, blue: 0.392).opacity(0.9),
     Color(red: 0.392, green: 1.0, blue: 0.392).opacity(0.9),
     Color(red: 0.392, green: 0.588, blue: 1.0).opacity(0.9)],
    // oklch
    [Color(red: 0.863, green: 0.863, blue: 0.863).opacity(0.9),
     Color(red: 1.0, green: 0.706, blue: 0.235).opacity(0.9),
     Color(red: 0.706, green: 0.471, blue: 1.0).opacity(0.9)],
]

/// Maps ColorMode to an index for the color arrays.
func modeIndex(_ mode: ColorMode) -> Int {
    switch mode {
    case .rgb: return 0
    case .hsb: return 1
    case .oklch: return 2
    }
}

// MARK: - Face Texture Cache

/// Key uniquely identifying a face texture's inputs.
struct FaceTextureKey: Hashable {
    let fixedAxis: Int
    let fixedVal: Double
    let uMax: Double
    let vMax: Double
    let mode: ColorMode
}

/// Reference-type cache of face textures keyed by their generation inputs.
/// Held outside the value-type renderer so cached textures persist across redraws.
final class FaceTextureCache {
    /// Cached image per face index (0=top, 1=right, 2=left).
    private var images: [Int: CGImage] = [:]
    /// Cached key per face index.
    private var keys: [Int: FaceTextureKey] = [:]

    init() {}

    /// Return the cached texture for `faceIndex` if its key matches, else regenerate.
    func texture(
        faceIndex: Int,
        fixedAxis: Int,
        fixedVal: Double,
        uMax: Double,
        vMax: Double,
        mode: ColorMode
    ) -> CGImage? {
        let key = FaceTextureKey(
            fixedAxis: fixedAxis,
            fixedVal: fixedVal,
            uMax: uMax,
            vMax: vMax,
            mode: mode
        )
        if let existingKey = keys[faceIndex], existingKey == key,
           let image = images[faceIndex] {
            return image
        }
        guard let image = generateFaceTexture(
            fixedAxis: fixedAxis,
            fixedVal: fixedVal,
            uMax: uMax,
            vMax: vMax,
            mode: mode
        ) else { return nil }
        images[faceIndex] = image
        keys[faceIndex] = key
        return image
    }
}

// MARK: - Face Texture Generation

/// Generate a 128x128 CGImage for one face of the cube.
func generateFaceTexture(
    fixedAxis: Int,
    fixedVal: Double,
    uMax: Double,
    vMax: Double,
    mode: ColorMode
) -> CGImage? {
    let res = FACE_RES
    let bytesPerPixel = 4
    let bytesPerRow = res * bytesPerPixel
    var pixelData = [UInt8](repeating: 0, count: res * res * bytesPerPixel)

    for py in 0..<res {
        for px in 0..<res {
            let u = (Double(px) / Double(res - 1)) * uMax
            let v = (Double(py) / Double(res - 1)) * vMax
            let rgb = ColorMath.faceColor(faceAxis: fixedAxis, u: u, v: v, fixedValue: fixedVal, mode: mode)
            let idx = (py * res + px) * bytesPerPixel
            pixelData[idx] = UInt8(clamping: rgb.r)
            pixelData[idx + 1] = UInt8(clamping: rgb.g)
            pixelData[idx + 2] = UInt8(clamping: rgb.b)
            pixelData[idx + 3] = 255
        }
    }

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
              data: &pixelData,
              width: res,
              height: res,
              bitsPerComponent: 8,
              bytesPerRow: bytesPerRow,
              space: colorSpace,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
        return nil
    }

    return context.makeImage()
}

// MARK: - Axis Lines

func drawAxisLines(context: inout GraphicsContext, scale: Double, center: Vec2, mode: ColorMode) {
    let origin = project(Vec3(x: 0, y: 0, z: 0), scale: scale, center: center)
    let tips = [
        project(Vec3(x: 1, y: 0, z: 0), scale: scale, center: center),
        project(Vec3(x: 0, y: 1, z: 0), scale: scale, center: center),
        project(Vec3(x: 0, y: 0, z: 1), scale: scale, center: center),
    ]
    let colors = AXIS_COLORS[modeIndex(mode)]

    for i in 0..<tips.count {
        var path = Path()
        path.move(to: CGPoint(x: origin.x, y: origin.y))
        path.addLine(to: CGPoint(x: tips[i].x, y: tips[i].y))
        context.stroke(path, with: .color(colors[i]), lineWidth: 1.5)
    }
}

// MARK: - Faces

/// Render a single face gradient using a layer to isolate clip and transform.
func renderFaceGradientInLayer(
    context: inout GraphicsContext,
    corners: [Vec2],
    faceIndex: Int,
    fixedAxis: Int,
    fixedVal: Double,
    uMax: Double,
    vMax: Double,
    mode: ColorMode,
    textureCache: FaceTextureCache?
) {
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

    // Clip path
    var clipPath = Path()
    clipPath.move(to: CGPoint(x: corners[0].x, y: corners[0].y))
    clipPath.addLine(to: CGPoint(x: corners[1].x, y: corners[1].y))
    clipPath.addLine(to: CGPoint(x: corners[2].x, y: corners[2].y))
    clipPath.addLine(to: CGPoint(x: corners[3].x, y: corners[3].y))
    clipPath.closeSubpath()

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

    let image = Image(decorative: cgImage, scale: 1.0)

    context.drawLayer { layerContext in
        let resolved = layerContext.resolve(image)
        layerContext.clip(to: clipPath)
        layerContext.concatenate(transform)
        layerContext.draw(resolved, in: CGRect(x: 0, y: 0, width: res, height: res))
    }
}

// MARK: - Complete Render (using layers for proper isolation)

/// The main render function that draws the entire cube scene using isolated layers.
func renderCubeScene(
    context: inout GraphicsContext,
    size: CGSize,
    cubeExtent: Vec3,
    dotValues: Vec3,
    dotFace: Int,
    mode: ColorMode,
    renderState: RenderState,
    textureCache: FaceTextureCache? = nil
) {
    let scale = min(size.width, size.height) * 0.32
    let center = Vec2(x: size.width / 2, y: size.height / 2)

    let verts3d = cubeVertices(extent: cubeExtent)
    let verts2d = verts3d.map { project($0, scale: scale, center: center) }

    drawAxisLines(context: &context, scale: scale, center: center, mode: mode)

    // Draw faces using layers for clip isolation
    for fi in 0..<FACES.count {
        let face = FACES[fi]
        let fixedVal = cubeExtent[face.fixedAxis]
        let uMax = cubeExtent[face.uAxis]
        let vMax = cubeExtent[face.vAxis]

        if uMax < 0.002 && vMax < 0.002 { continue }

        let corners = face.quad.map { verts2d[$0] }
        renderFaceGradientInLayer(
            context: &context,
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

    drawAxisLabels(context: &context, mode: mode, scale: scale, center: center)
    drawAxisHandles(context: &context, verts2d: verts2d, renderState: renderState, mode: mode)

    // Draw the color dot on the face
    if dotFace >= 0 {
        let rgb = ColorMath.valuesToRgb(dotValues, mode: mode)
        let dotPos = project(dotValues, scale: scale, center: center)
        drawColorDot(context: &context, pos: dotPos, rgb: rgb)
    }
}

// MARK: - Axis Labels

func drawAxisLabels(context: inout GraphicsContext, mode: ColorMode, scale: Double, center: Vec2) {
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

    for i in 0..<3 {
        let text = Text(labels[i])
            .font(.system(size: 11))
            .foregroundColor(Color.white.opacity(0.45))
        let resolved = context.resolve(text)
        context.draw(
            resolved,
            at: CGPoint(
                x: positions[i].x + offsets[i].x,
                y: positions[i].y + offsets[i].y
            ),
            anchor: .center
        )
    }
}

// MARK: - Axis Handles

func drawAxisHandles(
    context: inout GraphicsContext,
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
            let outerPath = Path(ellipseIn: CGRect(
                x: pos.x - (radius + 5), y: pos.y - (radius + 5),
                width: (radius + 5) * 2, height: (radius + 5) * 2
            ))
            context.stroke(outerPath, with: .color(.white.opacity(0.25)), lineWidth: 1.5)
        }

        // White background circle
        let bgPath = Path(ellipseIn: CGRect(
            x: pos.x - (radius + 2), y: pos.y - (radius + 2),
            width: (radius + 2) * 2, height: (radius + 2) * 2
        ))
        context.fill(bgPath, with: .color(.white))

        // Colored inner circle
        let innerPath = Path(ellipseIn: CGRect(
            x: pos.x - radius, y: pos.y - radius,
            width: radius * 2, height: radius * 2
        ))
        context.fill(innerPath, with: .color(colors[i]))
    }
}

// MARK: - Color Dot

func drawColorDot(context: inout GraphicsContext, pos: Vec2, rgb: RGBColor) {
    // Outer ring (white)
    let outerPath = Path(ellipseIn: CGRect(
        x: pos.x - 8, y: pos.y - 8,
        width: 16, height: 16
    ))
    context.fill(outerPath, with: .color(.white))

    // Inner color fill
    let innerPath = Path(ellipseIn: CGRect(
        x: pos.x - 6, y: pos.y - 6,
        width: 12, height: 12
    ))
    let color = Color(
        red: Double(rgb.r) / 255.0,
        green: Double(rgb.g) / 255.0,
        blue: Double(rgb.b) / 255.0
    )
    context.fill(innerPath, with: .color(color))
}
