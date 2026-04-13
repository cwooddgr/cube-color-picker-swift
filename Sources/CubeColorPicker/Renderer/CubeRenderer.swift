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
