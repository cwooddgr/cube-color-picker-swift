import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Bridges the `CubeSceneView` platform view into SwiftUI. Pulls the
/// `CubePickerState` from the SwiftUI environment exactly the same way the
/// previous `CubeCanvasView` did, so the swap inside `CubePickerView` is a
/// single-token change.
struct CubeSceneRepresentable: PlatformViewRepresentable {

    @EnvironmentObject private var state: CubePickerState

    init() {}

    #if canImport(UIKit)

    func makeUIView(context: Context) -> CubeSceneView {
        let view = CubeSceneView(frame: .zero)
        view.state = state
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: CubeSceneView, context: Context) {
        // Re-link state in case SwiftUI swapped the environment object instance
        // (rare but possible across recompositions). Idempotent when unchanged.
        if view.state !== state {
            view.state = state
        }
        view.setNeedsDisplay()
    }

    #elseif canImport(AppKit)

    func makeNSView(context: Context) -> CubeSceneView {
        let view = CubeSceneView(frame: .zero)
        view.state = state
        return view
    }

    func updateNSView(_ view: CubeSceneView, context: Context) {
        if view.state !== state {
            view.state = state
        }
        view.needsDisplay = true
    }

    #endif
}
