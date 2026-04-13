import SwiftUI
import Combine
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A platform-native view (UIView/NSView) that renders the cube scene with
/// Core Graphics. Replaces the previous SwiftUI `Canvas`-based implementation.
///
/// The view subscribes to a `CubePickerState` and triggers a redraw whenever
/// any rendering-relevant @Published property changes.
final class CubeSceneView: PlatformView {

    /// Per-face texture cache, reused across frames (mirrors prior @State cache).
    private let textureCache = FaceTextureCache()

    /// Active drag-gesture handler (set when `state` is assigned).
    private(set) var gestureHandler: CubeGestureHandler?

    /// Tracks whether the current pan has fired its initial onDragStart.
    private var didStartCurrentDrag = false

    /// Combine subscriptions to state changes; cancelled in deinit.
    private var cancellables: Set<AnyCancellable> = []

    /// Weak reference to the picker state. Setting this re-wires Combine subs
    /// and constructs a fresh `CubeGestureHandler`.
    weak var state: CubePickerState? {
        didSet {
            wireStateObservation()
        }
    }

    // MARK: - Init

    #if canImport(UIKit)
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    #elseif canImport(AppKit)
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    #endif

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        #if canImport(UIKit)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        #elseif canImport(AppKit)
        wantsLayer = false
        #endif
        installPanRecognizer()
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: - macOS coord-system

    #if canImport(AppKit)
    override var isFlipped: Bool { true }

    /// We render directly in `draw(_:)` rather than via a backing layer.
    override var wantsUpdateLayer: Bool { false }
    #endif

    // MARK: - State observation

    private func wireStateObservation() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        guard let state = state else {
            gestureHandler = nil
            return
        }

        gestureHandler = CubeGestureHandler(state: state)

        // Single subscription on objectWillChange covers every @Published
        // property the renderer reads. Coalesced to the next runloop tick.
        state.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.requestRedraw()
            }
            .store(in: &cancellables)

        // Also redraw when any debug flag (e.g. `solidFaces`) is flipped at
        // runtime, so an already-presented picker reflects the change without
        // waiting for the next gesture.
        NotificationCenter.default
            .publisher(for: .cubeColorPickerDebugDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.requestRedraw()
            }
            .store(in: &cancellables)
    }

    private func requestRedraw() {
        #if canImport(UIKit)
        setNeedsDisplay()
        #elseif canImport(AppKit)
        needsDisplay = true
        #endif
    }

    // MARK: - Drawing

    #if canImport(UIKit)
    override func draw(_ rect: CGRect) {
        guard let cg = UIGraphicsGetCurrentContext() else { return }
        renderScene(into: cg)
    }
    #elseif canImport(AppKit)
    override func draw(_ dirtyRect: NSRect) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        renderScene(into: cg)
    }
    #endif

    private func renderScene(into cg: CGContext) {
        guard let state = state else { return }
        renderCubeScene(
            into: cg,
            size: bounds.size,
            cubeExtent: state.cubeExtent,
            dotValues: state.dotValues,
            dotFace: state.dotFace,
            mode: state.mode,
            renderState: state.renderState,
            textureCache: textureCache
        )
    }

    // MARK: - Gesture recognizer

    private func installPanRecognizer() {
        let recognizer = PlatformPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        #if canImport(UIKit)
        recognizer.minimumNumberOfTouches = 1
        recognizer.maximumNumberOfTouches = 1
        recognizer.cancelsTouchesInView = true
        recognizer.delegate = self
        #endif
        addGestureRecognizer(recognizer)
    }

    #if canImport(UIKit)
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            didStartCurrentDrag = true
            gestureHandler?.onDragStart(location: location, size: bounds.size)
        case .changed:
            if !didStartCurrentDrag {
                didStartCurrentDrag = true
                gestureHandler?.onDragStart(location: location, size: bounds.size)
            } else {
                gestureHandler?.onDragChanged(location: location, size: bounds.size)
            }
        case .ended, .cancelled, .failed:
            gestureHandler?.onDragEnded()
            didStartCurrentDrag = false
        default:
            break
        }
    }
    #elseif canImport(AppKit)
    @objc private func handlePan(_ recognizer: NSPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            didStartCurrentDrag = true
            gestureHandler?.onDragStart(location: location, size: bounds.size)
        case .changed:
            if !didStartCurrentDrag {
                didStartCurrentDrag = true
                gestureHandler?.onDragStart(location: location, size: bounds.size)
            } else {
                gestureHandler?.onDragChanged(location: location, size: bounds.size)
            }
        case .ended, .cancelled, .failed:
            gestureHandler?.onDragEnded()
            didStartCurrentDrag = false
        default:
            break
        }
    }
    #endif
}

#if canImport(UIKit)
extension CubeSceneView: UIGestureRecognizerDelegate {
    /// Don't let scroll-style gestures recognize alongside our pan; we want
    /// the cube to win cleanly inside scrollable hosts. Matches the previous
    /// `.highPriorityGesture` semantics — a touch starting on the cube belongs
    /// to the cube.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}
#endif
