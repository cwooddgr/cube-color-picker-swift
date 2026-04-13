import XCTest
import CoreGraphics
@testable import CubeColorPicker

#if canImport(AppKit)
import AppKit
#endif

/// Smoke tests for the cube scene renderer. We render straight into a
/// byte-backed `CGContext` (no `UIImage` / `NSImage`), which keeps the test
/// identical across iOS and macOS and exercises the exact renderer entry
/// point that `CubeSceneView.draw(_:)` calls.
///
/// Catches the specific class of failure the 0.3.0 rewrite addresses: the
/// face-image drawing path silently no-oping. This is not a pixel-perfect
/// snapshot — just a "did anything draw?" guard.
final class RenderingTests: XCTestCase {

    func testCubeSceneRendersFacePixels() throws {
        let nonBlack = try renderAndCountNonBlackPixels(solidFaces: false)
        XCTAssertGreaterThan(
            nonBlack,
            500,
            "Expected the cube scene to draw a non-trivial number of non-black pixels (faces, axis lines, dot)."
        )
    }

    func testCubeSceneRendersWithSolidFacesDebugFlag() throws {
        let nonBlack = try renderAndCountNonBlackPixels(solidFaces: true)
        XCTAssertGreaterThan(
            nonBlack,
            500,
            "Solid-faces debug mode should still produce a visible cube."
        )
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// Smoke test: on macOS, constructing a `CubeSceneView` and assigning
    /// `state` should install a pan gesture recognizer without crashing.
    /// Guards against AppKit-side init regressions.
    func testCubeSceneViewInstantiatesOnMac() throws {
        let size = CGSize(width: 300, height: 300)
        let state = CubePickerState(
            initialColor: RGBColor(r: 200, g: 60, b: 60),
            mode: .rgb
        )

        let view = CubeSceneView(frame: CGRect(origin: .zero, size: size))
        view.state = state

        XCTAssertGreaterThan(
            view.gestureRecognizers.count,
            0,
            "CubeSceneView should install at least one gesture recognizer on macOS."
        )
        XCTAssertNotNil(view.gestureHandler)
    }
    #endif

    // MARK: - Render helpers

    /// Build a CGContext backed by a pixel buffer, call `renderCubeScene`
    /// directly (the same entry point `CubeSceneView.draw(_:)` uses), and
    /// return the count of non-black, non-transparent pixels.
    private func renderAndCountNonBlackPixels(solidFaces: Bool) throws -> Int {
        let originalFlag = CubeColorPickerDebug.solidFaces
        CubeColorPickerDebug.solidFaces = solidFaces
        defer { CubeColorPickerDebug.solidFaces = originalFlag }

        let width = 300
        let height = 300
        let size = CGSize(width: width, height: height)

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let byteCount = width * height * bytesPerPixel

        // Allocate the pixel buffer with a stable lifetime so the CGContext's
        // `data:` pointer remains valid for the full renderer invocation.
        // Using a `[UInt8]` + `withUnsafeMutableBytes` closure would let the
        // CGContext escape with a pointer whose validity is only contractual
        // within the closure — technically UB even if it happens to work.
        let pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        pixels.initialize(repeating: 0, count: byteCount)
        defer {
            pixels.deinitialize(count: byteCount)
            pixels.deallocate()
        }

        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(
            CGContext(
                data: pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )

        // Match the hosting-view convention used by both platforms: top-left
        // origin, y-down. The raw `CGContext` created above is y-up by
        // default (pixel row 0 is the bottom of the image), so flip it here
        // so the renderer's top-left assumption lines up with both
        // `UIView.draw` and `NSView.draw` with `isFlipped = true`.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        let state = CubePickerState(
            initialColor: RGBColor(r: 200, g: 60, b: 60),
            mode: .rgb
        )

        renderCubeScene(
            into: context,
            size: size,
            cubeExtent: state.cubeExtent,
            dotValues: state.dotValues,
            dotFace: state.dotFace,
            mode: state.mode,
            renderState: state.renderState,
            textureCache: nil
        )

        var count = 0
        for i in stride(from: 0, to: byteCount, by: bytesPerPixel) {
            let r = pixels[i]
            let g = pixels[i + 1]
            let b = pixels[i + 2]
            let a = pixels[i + 3]
            if a > 0 && (r > 8 || g > 8 || b > 8) {
                count += 1
            }
        }
        return count
    }
}
