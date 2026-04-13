import SwiftUI

/// Hit radius for axis handles (increased from web's 22 for iOS touch targets).
let HANDLE_HIT_RADIUS: Double = 30

/// Manages all drag interaction on the cube canvas.
/// Ports the state machine from interaction.ts.
class CubeGestureHandler {

    private weak var state: CubePickerState?

    // Axis drag state
    private var dragAxis: Int = -1
    private var dragStartMouse: Vec2 = Vec2(x: 0, y: 0)
    private var dragStartValue: Double = 0

    // Face drag state
    private var dragFace: Int = -1
    private var faceShiftLock: ShiftLock? = nil
    private var faceShiftStart: FaceHitResult? = nil
    private var faceShiftPending: Bool = false

    private enum ShiftLock {
        case u
        case v
    }

    init(state: CubePickerState) {
        self.state = state
    }

    // MARK: - Scale/Center from viewport size

    func scale(for size: CGSize) -> Double {
        return min(size.width, size.height) * 0.32
    }

    func center(for size: CGSize) -> Vec2 {
        return Vec2(x: size.width / 2, y: size.height / 2)
    }

    // MARK: - Hit Testing

    func hitTestAxisHandle(pt: Vec2, size: CGSize) -> Int {
        guard let state = state else { return -1 }
        let s = scale(for: size)
        let c = center(for: size)
        for i in 0..<3 {
            let pos = getAxisHandlePos(axisIndex: i, cubeExtent: state.cubeExtent, scale: s, center: c)
            let dx = pt.x - pos.x
            let dy = pt.y - pos.y
            if dx * dx + dy * dy <= HANDLE_HIT_RADIUS * HANDLE_HIT_RADIUS {
                return i
            }
        }
        return -1
    }

    func hitTestFace(pt: Vec2, size: CGSize) -> (faceIndex: Int, s: Double, t: Double)? {
        guard let state = state else { return nil }
        let s = scale(for: size)
        let c = center(for: size)
        // Test in reverse order (frontmost first)
        for fi in stride(from: FACES.count - 1, through: 0, by: -1) {
            if let hit = faceHitTest(faceIndex: fi, point: pt, cubeExtent: state.cubeExtent, scale: s, center: c) {
                return (faceIndex: fi, s: hit.s, t: hit.t)
            }
        }
        return nil
    }

    // MARK: - Gesture Handlers

    /// Called when a drag gesture begins.
    func onDragStart(location: CGPoint, size: CGSize) {
        let pt = Vec2(x: location.x, y: location.y)

        // Test axis handles first
        let axisHit = hitTestAxisHandle(pt: pt, size: size)
        if axisHit >= 0 {
            startAxisDrag(axisIndex: axisHit, pt: pt)
            return
        }

        // Then test faces
        if let faceHit = hitTestFace(pt: pt, size: size) {
            startFaceDrag(
                faceIndex: faceHit.faceIndex,
                s: faceHit.s,
                t: faceHit.t,
                constrain: state?.axisConstrainEnabled ?? false
            )
        }
    }

    /// Called during drag gesture updates.
    func onDragChanged(location: CGPoint, size: CGSize) {
        let pt = Vec2(x: location.x, y: location.y)

        if dragAxis >= 0 {
            applyAxisDrag(pt: pt, size: size)
            return
        }

        if dragFace >= 0 {
            applyFaceDrag(
                pt: pt,
                constrain: state?.axisConstrainEnabled ?? false,
                lockToFace: state?.faceLockEnabled ?? false,
                size: size
            )
        }
    }

    /// Called when drag gesture ends.
    func onDragEnded() {
        let wasDragging = dragAxis >= 0 || dragFace >= 0
        endAxisDrag()
        endFaceDrag()
        if wasDragging {
            state?.renderState.hoveredAxisHandle = -1
            state?.renderState.hoveredFace = -1
        }
    }

    // MARK: - Axis Handle Dragging

    private func startAxisDrag(axisIndex: Int, pt: Vec2) {
        guard let state = state else { return }
        dragAxis = axisIndex
        dragStartMouse = pt
        dragStartValue = state.cubeExtent[axisIndex]
        state.renderState.draggingAxisHandle = axisIndex
    }

    private func applyAxisDrag(pt: Vec2, size: CGSize) {
        guard let state = state, dragAxis >= 0 else { return }

        let dx = pt.x - dragStartMouse.x
        let dy = pt.y - dragStartMouse.y
        let dirs = getAxisDirections()
        let dir = dirs[dragAxis]
        let scaleVal = scale(for: size)

        let dot = dx * dir.x + dy * dir.y
        let delta = dot / scaleVal
        let newVal = max(0, min(1, dragStartValue + delta))

        var newExtent = state.cubeExtent
        newExtent[dragAxis] = newVal
        state.cubeExtent = newExtent

        // Clamp dotValues to stay within the new cube extent
        let dotFace = state.dotFace
        let face = dotFace >= 0 ? FACES[dotFace] : nil
        var newDot = state.dotValues

        if let face = face, dragAxis == face.fixedAxis {
            // Fixed axis of the dot's face changed -- dot tracks it
            newDot[dragAxis] = newVal
        } else {
            // Varying axis or no face -- clamp
            newDot[dragAxis] = min(state.dotValues[dragAxis], newVal)
        }
        state.dotValues = newDot
    }

    private func endAxisDrag() {
        dragAxis = -1
        state?.renderState.draggingAxisHandle = -1
    }

    // MARK: - Face Click/Drag

    private func startFaceDrag(faceIndex: Int, s: Double, t: Double, constrain: Bool) {
        dragFace = faceIndex
        state?.renderState.draggingFace = faceIndex
        faceShiftLock = nil
        faceShiftStart = nil
        faceShiftPending = false

        if constrain {
            // Record starting position, wait for movement to determine lock axis
            faceShiftPending = true
            faceShiftStart = FaceHitResult(s: s, t: t)
        }

        applyFaceValues(faceIndex: faceIndex, s: s, t: t)
    }

    private func applyFaceDrag(pt: Vec2, constrain: Bool, lockToFace: Bool, size: CGSize) {
        guard let state = state, dragFace >= 0 else { return }

        let scaleVal = scale(for: size)
        let centerVal = center(for: size)

        // Try current face first
        var hit = faceHitTest(faceIndex: dragFace, point: pt, cubeExtent: state.cubeExtent, scale: scaleVal, center: centerVal)
        var targetFace = dragFace

        // If cursor left the current face, try adjacent faces (unless face-lock)
        if hit == nil && !lockToFace {
            for fi in stride(from: FACES.count - 1, through: 0, by: -1) {
                if fi == dragFace { continue }
                hit = faceHitTest(faceIndex: fi, point: pt, cubeExtent: state.cubeExtent, scale: scaleVal, center: centerVal)
                if hit != nil {
                    targetFace = fi
                    break
                }
            }
        }

        // Face-lock: clamp to current face even if cursor is outside
        if hit == nil && lockToFace {
            hit = faceHitTestUnclamped(faceIndex: dragFace, point: pt, cubeExtent: state.cubeExtent, scale: scaleVal, center: centerVal)
            targetFace = dragFace
        }

        guard let hitResult = hit else { return }

        // If we switched faces, reset shift lock
        if targetFace != dragFace {
            dragFace = targetFace
            state.renderState.draggingFace = targetFace
            faceShiftLock = nil
            faceShiftPending = false
            faceShiftStart = nil
        }

        var s = hitResult.s
        var t = hitResult.t

        // Shift-drag axis locking (constrain mode)
        if constrain, let start = faceShiftStart {
            if faceShiftPending {
                // Determine lock direction once movement exceeds threshold
                let ds = abs(s - start.s)
                let dt = abs(t - start.t)
                let threshold: Double = 0.02
                if ds > threshold || dt > threshold {
                    faceShiftLock = ds >= dt ? .u : .v
                    faceShiftPending = false
                }
            }

            switch faceShiftLock {
            case .u:
                t = start.t // lock v-axis
            case .v:
                s = start.s // lock u-axis
            case nil:
                break
            }
        } else if !constrain {
            // Constrain released mid-drag: clear lock
            faceShiftLock = nil
            faceShiftPending = false
            faceShiftStart = nil
        }

        applyFaceValues(faceIndex: targetFace, s: s, t: t)
    }

    private func applyFaceValues(faceIndex: Int, s: Double, t: Double) {
        guard let state = state else { return }
        let face = FACES[faceIndex]

        var newDot = state.dotValues
        newDot[face.uAxis] = s * state.cubeExtent[face.uAxis]
        newDot[face.vAxis] = t * state.cubeExtent[face.vAxis]
        newDot[face.fixedAxis] = state.cubeExtent[face.fixedAxis]

        state.dotValues = newDot
        state.dotFace = faceIndex
    }

    private func endFaceDrag() {
        dragFace = -1
        state?.renderState.draggingFace = -1
        faceShiftLock = nil
        faceShiftPending = false
        faceShiftStart = nil
    }
}
