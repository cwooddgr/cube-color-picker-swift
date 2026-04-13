import Foundation
import CoreGraphics

/// Constants for isometric projection.
let ISO_ANGLE: Double = .pi / 6.0 // 30 degrees
let COS30: Double = cos(ISO_ANGLE)
let SIN30: Double = sin(ISO_ANGLE)

/// Resolution of face gradient textures (128x128 pixels).
let FACE_RES: Int = 128

/// Fraction of the min viewport dimension used as the isometric projection
/// scale. Shared between the renderer and the gesture handler so hit testing
/// stays aligned with the drawn hex.
let CUBE_RENDER_SCALE_RATIO: Double = 0.43

/// Isometric scale for a given viewport — the distance in points from the
/// hex center to each axis endpoint.
func cubeRenderScale(for size: CGSize) -> Double {
    return min(size.width, size.height) * CUBE_RENDER_SCALE_RATIO
}

/// Project a 3D point to 2D screen coordinates (isometric projection).
func project(_ p: Vec3, scale: Double, center: Vec2) -> Vec2 {
    return Vec2(
        x: center.x + (p.x - p.y) * COS30 * scale,
        y: center.y - p.z * scale + (p.x + p.y) * SIN30 * scale
    )
}

/// Compute the 8 vertices of the cube given extents per axis.
func cubeVertices(extent ext: Vec3) -> [Vec3] {
    let w = ext.x
    let h = ext.y
    let d = ext.z
    return [
        Vec3(x: 0, y: 0, z: 0),     // 0
        Vec3(x: w, y: 0, z: 0),     // 1
        Vec3(x: 0, y: h, z: 0),     // 2
        Vec3(x: 0, y: 0, z: d),     // 3
        Vec3(x: w, y: h, z: 0),     // 4
        Vec3(x: w, y: 0, z: d),     // 5
        Vec3(x: 0, y: h, z: d),     // 6
        Vec3(x: w, y: h, z: d),     // 7
    ]
}

/// Get the 2D position of an axis handle.
func getAxisHandlePos(axisIndex: Int, cubeExtent: Vec3, scale: Double, center: Vec2) -> Vec2 {
    var pos = Vec3(x: 0, y: 0, z: 0)
    pos[axisIndex] = cubeExtent[axisIndex]
    return project(pos, scale: scale, center: center)
}

/// Get normalized direction vectors for each axis in screen space.
func getAxisDirections() -> [Vec2] {
    let origin = Vec2(x: 0, y: 0)
    let tips = [
        project(Vec3(x: 1, y: 0, z: 0), scale: 1, center: origin),
        project(Vec3(x: 0, y: 1, z: 0), scale: 1, center: origin),
        project(Vec3(x: 0, y: 0, z: 1), scale: 1, center: origin),
    ]
    return tips.map { t in
        let len = sqrt(t.x * t.x + t.y * t.y)
        return len > 0 ? Vec2(x: t.x / len, y: t.y / len) : Vec2(x: 0, y: 0)
    }
}

/// Hit-test result for a face.
struct FaceHitResult {
    var s: Double // 0-1 fraction along U axis
    var t: Double // 0-1 fraction along V axis
}

/// Hit-test a point against a face's visible area.
/// Returns (s, t) as fractions 0-1 of the face's current extent, or nil if not hit.
func faceHitTest(
    faceIndex: Int,
    point: Vec2,
    cubeExtent: Vec3,
    scale: Double,
    center: Vec2
) -> FaceHitResult? {
    let face = FACES[faceIndex]
    let uMax = cubeExtent[face.uAxis]
    let vMax = cubeExtent[face.vAxis]

    // Skip degenerate faces
    if uMax < 0.002 || vMax < 0.002 { return nil }

    // Face origin in 3D: the corner where both varying axes are 0
    var faceOrigin = Vec3(x: 0, y: 0, z: 0)
    faceOrigin[face.fixedAxis] = cubeExtent[face.fixedAxis]

    // Basis vectors spanning the face (in 3D, scaled to cubeExtent)
    var uEnd = faceOrigin
    uEnd[face.uAxis] = uMax

    var vEnd = faceOrigin
    vEnd[face.vAxis] = vMax

    let O = project(faceOrigin, scale: scale, center: center)
    let U = project(uEnd, scale: scale, center: center)
    let V = project(vEnd, scale: scale, center: center)

    let ax = U.x - O.x
    let ay = U.y - O.y
    let bx = V.x - O.x
    let by = V.y - O.y

    let det = ax * by - ay * bx
    if abs(det) < 1e-6 { return nil }

    let dx = point.x - O.x
    let dy = point.y - O.y
    let s = (dx * by - dy * bx) / det
    let t = (dy * ax - dx * ay) / det

    // Small tolerance for edge clicks
    if s < -0.05 || s > 1.05 || t < -0.05 || t > 1.05 { return nil }

    return FaceHitResult(
        s: max(0, min(1, s)),
        t: max(0, min(1, t))
    )
}

/// Like faceHitTest but always returns a result (clamped to 0-1),
/// even when the cursor is far outside the face. Used with face-lock drag.
func faceHitTestUnclamped(
    faceIndex: Int,
    point: Vec2,
    cubeExtent: Vec3,
    scale: Double,
    center: Vec2
) -> FaceHitResult? {
    let face = FACES[faceIndex]
    let uMax = cubeExtent[face.uAxis]
    let vMax = cubeExtent[face.vAxis]

    if uMax < 0.002 || vMax < 0.002 { return nil }

    var faceOrigin = Vec3(x: 0, y: 0, z: 0)
    faceOrigin[face.fixedAxis] = cubeExtent[face.fixedAxis]

    var uEnd = faceOrigin
    uEnd[face.uAxis] = uMax

    var vEnd = faceOrigin
    vEnd[face.vAxis] = vMax

    let O = project(faceOrigin, scale: scale, center: center)
    let U = project(uEnd, scale: scale, center: center)
    let V = project(vEnd, scale: scale, center: center)

    let ax = U.x - O.x
    let ay = U.y - O.y
    let bx = V.x - O.x
    let by = V.y - O.y

    let det = ax * by - ay * bx
    if abs(det) < 1e-6 { return nil }

    let dx = point.x - O.x
    let dy = point.y - O.y
    let s = (dx * by - dy * bx) / det
    let t = (dy * ax - dx * ay) / det

    return FaceHitResult(
        s: max(0, min(1, s)),
        t: max(0, min(1, t))
    )
}
