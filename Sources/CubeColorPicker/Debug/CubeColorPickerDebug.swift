// CubeColorPickerDebug
//
// Diagnostic-only hooks for isolating rendering issues in host-app
// container hierarchies. This type is intentionally minimal and is
// NOT part of the stable public API: properties here may be removed
// or renamed in a future minor version without a semver break.
//
// Consumers should only touch these knobs when explicitly asked to
// by a maintainer as part of a bug-reproduction report.

import Foundation

/// Diagnostic toggles for `CubeColorPicker`.
///
/// - Important: This type is a diagnostic hook, not part of the stable
///   public API. Its members may be removed or renamed in any future
///   minor version. Do not ship production code that depends on it.
public enum CubeColorPickerDebug {
    /// When `true`, `renderFaceGradient` bypasses the CGImage pipeline
    /// and fills each visible cube face with a single flat R / G / B
    /// color keyed by `fixedAxis` (0 -> red, 1 -> green, 2 -> blue) at
    /// 0.85 opacity. Intended to isolate whether face-gradient
    /// disappearance in a given host-app container hierarchy is caused
    /// by the `Image(decorative:) -> resolve -> draw` pipeline, by the
    /// face-quad geometry never reaching the canvas, or by
    /// compositing/transform-stack interactions.
    ///
    /// Defaults to `false`, which preserves the unmodified CGImage
    /// render path byte-for-byte.
    ///
    /// - Warning: Diagnostic only. Do not enable in production builds.
    public static var solidFaces: Bool = false
}
