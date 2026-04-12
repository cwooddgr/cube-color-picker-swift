import XCTest
@testable import CubeColorPicker

final class ColorMathTests: XCTestCase {

    // MARK: - RGB <-> HSB

    func testRgbToHsb_red() {
        let hsb = ColorMath.rgbToHsb(CubeColorPicker.RGBColor(r: 255, g: 0, b: 0))
        XCTAssertEqual(hsb.h, 0, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.s, 100, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.b, 100, accuracy: 0.5 as Double)
    }

    func testRgbToHsb_green() {
        let hsb = ColorMath.rgbToHsb(CubeColorPicker.RGBColor(r: 0, g: 255, b: 0))
        XCTAssertEqual(hsb.h, 120, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.s, 100, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.b, 100, accuracy: 0.5 as Double)
    }

    func testRgbToHsb_blue() {
        let hsb = ColorMath.rgbToHsb(CubeColorPicker.RGBColor(r: 0, g: 0, b: 255))
        XCTAssertEqual(hsb.h, 240, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.s, 100, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.b, 100, accuracy: 0.5 as Double)
    }

    func testRgbToHsb_white() {
        let hsb = ColorMath.rgbToHsb(CubeColorPicker.RGBColor(r: 255, g: 255, b: 255))
        XCTAssertEqual(hsb.h, 0, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.s, 0, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.b, 100, accuracy: 0.5 as Double)
    }

    func testRgbToHsb_black() {
        let hsb = ColorMath.rgbToHsb(CubeColorPicker.RGBColor(r: 0, g: 0, b: 0))
        XCTAssertEqual(hsb.h, 0, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.s, 0, accuracy: 0.5 as Double)
        XCTAssertEqual(hsb.b, 0, accuracy: 0.5 as Double)
    }

    func testHsbToRgb_red() {
        let rgb = ColorMath.hsbToRgb(HSBColor(h: 0, s: 100, b: 100))
        XCTAssertEqual(rgb.r, 255)
        XCTAssertEqual(rgb.g, 0)
        XCTAssertEqual(rgb.b, 0)
    }

    func testHsbToRgb_green() {
        let rgb = ColorMath.hsbToRgb(HSBColor(h: 120, s: 100, b: 100))
        XCTAssertEqual(rgb.r, 0)
        XCTAssertEqual(rgb.g, 255)
        XCTAssertEqual(rgb.b, 0)
    }

    func testHsbToRgb_blue() {
        let rgb = ColorMath.hsbToRgb(HSBColor(h: 240, s: 100, b: 100))
        XCTAssertEqual(rgb.r, 0)
        XCTAssertEqual(rgb.g, 0)
        XCTAssertEqual(rgb.b, 255)
    }

    func testHsbRoundTrip() {
        let original = CubeColorPicker.RGBColor(r: 128, g: 64, b: 200)
        let hsb = ColorMath.rgbToHsb(original)
        let result = ColorMath.hsbToRgb(hsb)
        assertRGBClose(result, original, accuracy: 1)
    }

    // MARK: - RGB <-> OKLCH

    func testRgbToOklch_red() {
        let oklch = ColorMath.rgbToOklch(CubeColorPicker.RGBColor(r: 255, g: 0, b: 0))
        XCTAssertGreaterThan(oklch.l, 0.5)
        XCTAssertGreaterThan(oklch.c, 0.2)
        XCTAssertEqual(oklch.h, 29.0, accuracy: 2.0)
    }

    func testOklchRoundTrip() {
        let original = CubeColorPicker.RGBColor(r: 100, g: 150, b: 200)
        let oklch = ColorMath.rgbToOklch(original)
        let result = ColorMath.oklchToRgb(oklch)
        assertRGBClose(result, original, accuracy: 2)
    }

    func testOklchBlackRoundTrip() {
        let original = CubeColorPicker.RGBColor(r: 0, g: 0, b: 0)
        let oklch = ColorMath.rgbToOklch(original)
        XCTAssertEqual(oklch.l, 0.0, accuracy: 0.01)
        XCTAssertEqual(oklch.c, 0.0, accuracy: 0.001)
    }

    // MARK: - Hex

    func testRgbToHex() {
        XCTAssertEqual(ColorMath.rgbToHex(CubeColorPicker.RGBColor(r: 255, g: 0, b: 0)), "#ff0000")
        XCTAssertEqual(ColorMath.rgbToHex(CubeColorPicker.RGBColor(r: 0, g: 255, b: 0)), "#00ff00")
        XCTAssertEqual(ColorMath.rgbToHex(CubeColorPicker.RGBColor(r: 0, g: 0, b: 255)), "#0000ff")
        XCTAssertEqual(ColorMath.rgbToHex(CubeColorPicker.RGBColor(r: 18, g: 52, b: 86)), "#123456")
    }

    func testHexToRgb_valid() {
        let rgb1 = ColorMath.hexToRgb("#ff0000")
        XCTAssertEqual(rgb1?.r, 255)
        XCTAssertEqual(rgb1?.g, 0)
        XCTAssertEqual(rgb1?.b, 0)

        let rgb2 = ColorMath.hexToRgb("00ff00")
        XCTAssertEqual(rgb2?.r, 0)
        XCTAssertEqual(rgb2?.g, 255)
        XCTAssertEqual(rgb2?.b, 0)

        let rgb3 = ColorMath.hexToRgb("#AABBCC")
        XCTAssertEqual(rgb3?.r, 170)
        XCTAssertEqual(rgb3?.g, 187)
        XCTAssertEqual(rgb3?.b, 204)
    }

    func testHexToRgb_invalid() {
        XCTAssertNil(ColorMath.hexToRgb("xyz"))
        XCTAssertNil(ColorMath.hexToRgb("#12345"))
        XCTAssertNil(ColorMath.hexToRgb(""))
    }

    func testHexRoundTrip() {
        let original = CubeColorPicker.RGBColor(r: 42, g: 128, b: 200)
        let hex = ColorMath.rgbToHex(original)
        let result = ColorMath.hexToRgb(hex)
        XCTAssertEqual(result?.r, original.r)
        XCTAssertEqual(result?.g, original.g)
        XCTAssertEqual(result?.b, original.b)
    }

    // MARK: - Values <-> RGB

    func testValuesToRgb_rgbMode() {
        let rgb = ColorMath.valuesToRgb(Vec3(x: 1, y: 0, z: 0.5), mode: .rgb)
        XCTAssertEqual(rgb.r, 255)
        XCTAssertEqual(rgb.g, 0)
        XCTAssertEqual(rgb.b, 128)
    }

    func testRgbToValues_rgbMode() {
        let values = ColorMath.rgbToValues(CubeColorPicker.RGBColor(r: 255, g: 0, b: 128), mode: .rgb)
        XCTAssertEqual(values.x, 1.0, accuracy: 0.01)
        XCTAssertEqual(values.y, 0.0, accuracy: 0.01)
        XCTAssertEqual(values.z, 128.0 / 255.0, accuracy: 0.01)
    }

    func testValuesRoundTrip_hsbMode() {
        let original = CubeColorPicker.RGBColor(r: 200, g: 100, b: 50)
        let values = ColorMath.rgbToValues(original, mode: .hsb)
        let result = ColorMath.valuesToRgb(values, mode: .hsb)
        assertRGBClose(result, original, accuracy: 2)
    }

    func testValuesRoundTrip_oklchMode() {
        let original = CubeColorPicker.RGBColor(r: 100, g: 150, b: 200)
        let values = ColorMath.rgbToValues(original, mode: .oklch)
        let result = ColorMath.valuesToRgb(values, mode: .oklch)
        // OKLCH round-trip can have slightly more error due to gamut clamping
        assertRGBClose(result, original, accuracy: 5)
    }

    // MARK: - Channels

    func testValuesToChannels_rgb() {
        let channels = ColorMath.valuesToChannels(Vec3(x: 1, y: 0.5, z: 0), mode: .rgb)
        XCTAssertEqual(channels[0], 255.0, accuracy: 0.5)
        XCTAssertEqual(channels[1], 128.0, accuracy: 0.5)
        XCTAssertEqual(channels[2], 0.0, accuracy: 0.5)
    }

    func testValuesToChannels_hsb() {
        let channels = ColorMath.valuesToChannels(Vec3(x: 0.5, y: 0.5, z: 0.5), mode: .hsb)
        XCTAssertEqual(channels[0], 180.0, accuracy: 0.5) // h: 0.5 * 359 = 179.5 -> 180
        XCTAssertEqual(channels[1], 50.0, accuracy: 0.5)  // s: 0.5 * 100
        XCTAssertEqual(channels[2], 50.0, accuracy: 0.5)  // b: 0.5 * 100
    }

    // MARK: - Face Color

    func testFaceColor_rgbMode() {
        // Fixed axis 0 (x=R), u=G, v=B
        let rgb = ColorMath.faceColor(faceAxis: 0, u: 1, v: 1, fixedValue: 1, mode: .rgb)
        XCTAssertEqual(rgb.r, 255)
        XCTAssertEqual(rgb.g, 255)
        XCTAssertEqual(rgb.b, 255)
    }

    func testFaceColor_rgbMode_origin() {
        // Fixed axis 2 (z=B), u=R, v=G -- all zero
        let rgb = ColorMath.faceColor(faceAxis: 2, u: 0, v: 0, fixedValue: 0, mode: .rgb)
        XCTAssertEqual(rgb.r, 0)
        XCTAssertEqual(rgb.g, 0)
        XCTAssertEqual(rgb.b, 0)
    }

    // MARK: - Gamut Clamp (indirect via valuesToRgb oklch mode)

    func testGamutClamp_inGamutPreserved() {
        // Low chroma point that's safely in the sRGB gamut: mid lightness, low chroma, any hue.
        let l = 0.6
        let cNorm = 0.1 // -> 0.04 chroma
        let hNorm = 30.0 / 359.0
        let values = Vec3(x: l, y: cNorm, z: hNorm)
        let rgb = ColorMath.valuesToRgb(values, mode: .oklch)

        // Round-trip should preserve L, C, h closely because clamp was a no-op.
        let oklch = ColorMath.rgbToOklch(rgb)
        XCTAssertEqual(oklch.l, l, accuracy: 0.02)
        XCTAssertEqual(oklch.c, cNorm * ColorMath.OKLCH_C_MAX, accuracy: 0.01)
        XCTAssertEqual(oklch.h, hNorm * 359.0, accuracy: 2.0)
    }

    func testGamutClamp_outOfGamutReducesChroma() {
        // Very high chroma at mid lightness is out of gamut; chroma should be reduced.
        let l = 0.6
        let inputC = ColorMath.OKLCH_C_MAX // max normalized chroma, definitely out of gamut for most hues
        let h = 30.0
        let values = Vec3(x: l, y: 1.0, z: h / 359.0)
        let rgb = ColorMath.valuesToRgb(values, mode: .oklch)

        // Result must be within valid RGB gamut.
        XCTAssertTrue(rgb.r >= 0 && rgb.r <= 255)
        XCTAssertTrue(rgb.g >= 0 && rgb.g <= 255)
        XCTAssertTrue(rgb.b >= 0 && rgb.b <= 255)

        // The resulting OKLCH chroma should be less than the requested chroma.
        let resultOklch = ColorMath.rgbToOklch(rgb)
        XCTAssertLessThan(resultOklch.c, inputC)

        // Lightness and hue should be preserved (within tolerance — allow for small
        // error introduced by RGB integer rounding and binary-search termination).
        XCTAssertEqual(resultOklch.l, l, accuracy: 0.05)
        XCTAssertEqual(resultOklch.h, h, accuracy: 5.0)
    }

    // MARK: - Face Color (additional)

    func testFaceColor_hsbMode() {
        // HSB face: faceAxis=0 means fixed axis x (H).
        // With fixedValue=1.0, u=0.5, v=0.5:
        //   H = 1.0 * 359 = 359 (red-ish)
        //   S = 0.5 * 100 = 50
        //   B = 0.5 * 100 = 50
        let rgb = ColorMath.faceColor(faceAxis: 0, u: 0.5, v: 0.5, fixedValue: 1.0, mode: .hsb)

        // Convert expected HSB to RGB for comparison.
        let expected = ColorMath.hsbToRgb(HSBColor(h: 359, s: 50, b: 50))
        XCTAssertEqual(rgb.r, expected.r)
        XCTAssertEqual(rgb.g, expected.g)
        XCTAssertEqual(rgb.b, expected.b)
    }

    func testFaceColor_oklchMode_lowChromaInGamut() {
        // OKLCH face: faceAxis=0 means fixed axis x (L).
        // With fixedValue=0.7, u=0.1 (low chroma), v=0.5 (hue midpoint):
        //   L = 0.7, C = 0.1 * 0.4 = 0.04, H = 0.5 * 359 ~= 179.5
        // Low chroma should be safely in gamut.
        let rgb = ColorMath.faceColor(faceAxis: 0, u: 0.1, v: 0.5, fixedValue: 0.7, mode: .oklch)

        XCTAssertTrue(rgb.r >= 0 && rgb.r <= 255)
        XCTAssertTrue(rgb.g >= 0 && rgb.g <= 255)
        XCTAssertTrue(rgb.b >= 0 && rgb.b <= 255)

        // Round-trip through OKLCH should preserve inputs closely (no clamping needed).
        let oklch = ColorMath.rgbToOklch(rgb)
        XCTAssertEqual(oklch.l, 0.7, accuracy: 0.02)
        XCTAssertEqual(oklch.c, 0.04, accuracy: 0.01)
        XCTAssertEqual(oklch.h, 179.5, accuracy: 3.0)
    }

    // MARK: - Vec3 Subscript

    func testVec3Subscript_get() {
        let v = Vec3(x: 1, y: 2, z: 3)
        XCTAssertEqual(v[0], 1.0)
        XCTAssertEqual(v[1], 2.0)
        XCTAssertEqual(v[2], 3.0)
    }

    func testVec3Subscript_set() {
        var v = Vec3(x: 0, y: 0, z: 0)
        v[0] = 10
        v[1] = 20
        v[2] = 30
        XCTAssertEqual(v.x, 10.0)
        XCTAssertEqual(v.y, 20.0)
        XCTAssertEqual(v.z, 30.0)
    }

    // MARK: - Helper

    private func assertRGBClose(_ a: CubeColorPicker.RGBColor, _ b: CubeColorPicker.RGBColor, accuracy: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(abs(a.r - b.r) <= accuracy, "r: \(a.r) != \(b.r) (accuracy: \(accuracy))", file: file, line: line)
        XCTAssertTrue(abs(a.g - b.g) <= accuracy, "g: \(a.g) != \(b.g) (accuracy: \(accuracy))", file: file, line: line)
        XCTAssertTrue(abs(a.b - b.b) <= accuracy, "b: \(a.b) != \(b.b) (accuracy: \(accuracy))", file: file, line: line)
    }
}
