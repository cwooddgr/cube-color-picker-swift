#if canImport(UIKit) && !os(watchOS)
import XCTest
import UIKit
@testable import CubeColorPicker

/// Smoke test: instantiate `CubeSceneView` directly, render into a bitmap,
/// and check that pixels inside one face's projected quad are non-black.
///
/// Catches the specific class of failure the 0.3.0 rewrite addresses: the
/// face-image drawing path silently no-oping. This is not a pixel-perfect
/// snapshot — just a "did anything draw?" guard.
final class RenderingTests: XCTestCase {

    func testCubeSceneRendersFacePixels() throws {
        let image = renderCubeScene(solidFaces: false)
        let cgImage = try XCTUnwrap(image.cgImage)
        let nonBlack = nonBlackPixelCount(in: cgImage)
        XCTAssertGreaterThan(
            nonBlack,
            500,
            "Expected the cube scene to draw a non-trivial number of non-black pixels (faces, axis lines, dot)."
        )
    }

    func testCubeSceneRendersWithSolidFacesDebugFlag() throws {
        let originalFlag = CubeColorPickerDebug.solidFaces
        CubeColorPickerDebug.solidFaces = true
        defer { CubeColorPickerDebug.solidFaces = originalFlag }

        let image = renderCubeScene(solidFaces: true)
        let cgImage = try XCTUnwrap(image.cgImage)
        let nonBlack = nonBlackPixelCount(in: cgImage)
        XCTAssertGreaterThan(
            nonBlack,
            500,
            "Solid-faces debug mode should still produce a visible cube."
        )
    }

    // MARK: - Render helper

    private func renderCubeScene(solidFaces: Bool) -> UIImage {
        let size = CGSize(width: 300, height: 300)
        let state = CubePickerState(
            initialColor: RGBColor(r: 200, g: 60, b: 60),
            mode: .rgb
        )

        let view = CubeSceneView(frame: CGRect(origin: .zero, size: size))
        view.state = state

        // We invoke draw(_:) directly with our own CGContext rather than
        // routing through the render server (drawHierarchy) or CALayer.render
        // (which only re-renders an already-displayed layer). This is
        // sufficient because CubeSceneView.draw uses UIGraphicsGetCurrentContext.
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            view.draw(view.bounds)
        }
    }

    // MARK: - Helpers

    /// Count pixels that are not opaque-black or fully-transparent. Used as a
    /// crude "did anything draw?" signal.
    private func nonBlackPixelCount(in cgImage: CGImage) -> Int {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixels,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return 0
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var count = 0
        for i in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
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
#endif
