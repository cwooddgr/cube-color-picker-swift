import Foundation

/// Debug knobs for the cube color picker. Not intended for production use.
public enum CubeColorPickerDebug {
    private static var _solidFaces: Bool = false

    /// When true, face quads are filled with a per-face flat debug color instead
    /// of the gradient bitmap. Useful for diagnosing image-draw failures in
    /// unusual host hierarchies.
    ///
    /// Mutating this posts `Notification.Name.cubeColorPickerDebugDidChange` so
    /// any live `CubePickerView` instances redraw immediately, even when the
    /// host is not otherwise observing the flag.
    public static var solidFaces: Bool {
        get { _solidFaces }
        set {
            _solidFaces = newValue
            NotificationCenter.default.post(name: .cubeColorPickerDebugDidChange, object: nil)
        }
    }
}

public extension Notification.Name {
    /// Posted whenever a `CubeColorPickerDebug` flag changes. Subscribers (e.g.
    /// the cube scene view) should treat this as a signal to redraw.
    static let cubeColorPickerDebugDidChange = Notification.Name("com.cubecolorpicker.debugDidChange")
}
