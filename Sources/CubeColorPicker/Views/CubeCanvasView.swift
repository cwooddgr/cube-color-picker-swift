import SwiftUI

/// The 3D cube viewport rendered via SwiftUI Canvas with drag gesture support.
public struct CubeCanvasView: View {
    @EnvironmentObject private var state: CubePickerState

    /// The gesture handler; lazily created per state instance.
    @State private var gestureHandler: CubeGestureHandler?

    /// Tracks whether onDragStart has fired for the current gesture.
    @State private var didStart: Bool = false

    /// Per-face texture cache, reused across frames.
    @State private var textureCache = FaceTextureCache()

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                renderCubeScene(
                    context: &context,
                    size: size,
                    cubeExtent: state.cubeExtent,
                    dotValues: state.dotValues,
                    dotFace: state.dotFace,
                    mode: state.mode,
                    renderState: state.renderState,
                    textureCache: textureCache
                )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        ensureGestureHandler()
                        if !didStart {
                            didStart = true
                            gestureHandler?.onDragStart(value: value, size: geometry.size)
                        } else {
                            gestureHandler?.onDragChanged(value: value, size: geometry.size)
                        }
                    }
                    .onEnded { _ in
                        gestureHandler?.onDragEnded()
                        didStart = false
                    }
            )
            .onAppear {
                ensureGestureHandler()
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func ensureGestureHandler() {
        if gestureHandler == nil {
            gestureHandler = CubeGestureHandler(state: state)
        }
    }
}
