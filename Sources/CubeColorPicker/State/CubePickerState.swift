import SwiftUI
import Combine

/// The shared observable state for the cube color picker.
/// Owned internally by `CubePickerView` and injected into its sub-views.
final class CubePickerState: ObservableObject {

    /// The cube dimensions per axis (0-1), controlled by axis handles.
    @Published var cubeExtent: Vec3 = Vec3(x: 1, y: 1, z: 1)

    /// The selected color as normalized axis values (0-1 per axis).
    @Published var dotValues: Vec3 = Vec3(x: 0.7, y: 0.4, z: 0.85)

    /// Which face the dot is placed on (0=top, 1=right, 2=left), or -1 for none.
    @Published var dotFace: Int = 0

    /// The active color mode.
    @Published var mode: ColorMode = .rgb

    /// When true, face drags are constrained to one axis (like Shift on web).
    @Published var axisConstrainEnabled: Bool = false

    /// When true, face drags are locked to the current face (like Option on web).
    @Published var faceLockEnabled: Bool = false

    /// Internal render state for hover/drag visual feedback.
    @Published var renderState: RenderState = .default

    /// Animation timer for mode transitions.
    private var animationTimer: Timer?
    private var animationStartTime: Date?
    private var animationDuration: TimeInterval = 0
    private var animFromDot: Vec3 = Vec3(x: 0, y: 0, z: 0)
    private var animToDot: Vec3 = Vec3(x: 0, y: 0, z: 0)
    private var animFromExt: Vec3 = Vec3(x: 0, y: 0, z: 0)
    private var animToExt: Vec3 = Vec3(x: 0, y: 0, z: 0)

    init() {}

    init(initialColor: RGBColor, mode: ColorMode = .rgb) {
        self.mode = mode
        self.dotValues = ColorMath.rgbToValues(initialColor, mode: mode)
    }

    // MARK: - Computed Properties

    /// The current color output in all representations.
    var currentColor: ColorOutput {
        let rgb = ColorMath.valuesToRgb(dotValues, mode: mode)
        return ColorOutput(
            rgb: rgb,
            hsb: ColorMath.rgbToHsb(rgb),
            oklch: ColorMath.rgbToOklch(rgb),
            hex: ColorMath.rgbToHex(rgb)
        )
    }

    // MARK: - Methods

    /// Set the color from an RGB value.
    func setColor(_ rgb: RGBColor) {
        dotValues = ColorMath.rgbToValues(rgb, mode: mode)
        cubeExtent = Vec3(
            x: max(cubeExtent.x, dotValues.x),
            y: max(cubeExtent.y, dotValues.y),
            z: max(cubeExtent.z, dotValues.z)
        )
    }

    /// Switch to a new color mode, optionally with animation.
    func setMode(_ newMode: ColorMode, animated: Bool = true) {
        guard newMode != mode else { return }
        let rgb = ColorMath.valuesToRgb(dotValues, mode: mode)
        let oldDot = dotValues
        let oldExt = cubeExtent

        mode = newMode

        let newDot = ColorMath.rgbToValues(rgb, mode: newMode)
        let newExt = Vec3(x: 1, y: 1, z: 1)

        if animated {
            animateTransition(fromDot: oldDot, toDot: newDot, fromExt: oldExt, toExt: newExt, durationMs: 300)
        } else {
            dotValues = newDot
            cubeExtent = newExt
        }
    }

    // MARK: - Animation

    private func animateTransition(
        fromDot: Vec3, toDot: Vec3,
        fromExt: Vec3, toExt: Vec3,
        durationMs: Int
    ) {
        // Cancel any in-progress animation
        animationTimer?.invalidate()

        animFromDot = fromDot
        animToDot = toDot
        animFromExt = fromExt
        animToExt = toExt
        animationDuration = Double(durationMs) / 1000.0
        animationStartTime = Date()

        // Use a display-link-rate timer (~60fps)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.animationTick(timer: timer)
        }
    }

    private func animationTick(timer: Timer) {
        guard let startTime = animationStartTime else {
            timer.invalidate()
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let t = min(1.0, elapsed / animationDuration)
        // Ease-out cubic: 1 - (1 - t)^3
        let ease = 1.0 - pow(1.0 - t, 3.0)

        dotValues = Vec3(
            x: animFromDot.x + (animToDot.x - animFromDot.x) * ease,
            y: animFromDot.y + (animToDot.y - animFromDot.y) * ease,
            z: animFromDot.z + (animToDot.z - animFromDot.z) * ease
        )
        cubeExtent = Vec3(
            x: animFromExt.x + (animToExt.x - animFromExt.x) * ease,
            y: animFromExt.y + (animToExt.y - animFromExt.y) * ease,
            z: animFromExt.z + (animToExt.z - animFromExt.z) * ease
        )

        if t >= 1.0 {
            timer.invalidate()
            animationTimer = nil
            animationStartTime = nil
        }
    }
}
