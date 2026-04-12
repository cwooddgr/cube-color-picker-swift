import Foundation

/// Port of color-math.ts -- all color conversion functions.
public enum ColorMath {

    // MARK: - OKLCH Max Chroma

    /// OKLCH max chroma for normalized axis mapping (covers sRGB gamut).
    static let OKLCH_C_MAX: Double = 0.4

    // MARK: - RGB <-> HSB

    public static func rgbToHsb(_ rgb: RGBColor) -> HSBColor {
        let r = Double(rgb.r) / 255.0
        let g = Double(rgb.g) / 255.0
        let b = Double(rgb.b) / 255.0

        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let d = maxVal - minVal

        var h: Double = 0
        if d != 0 {
            if maxVal == r {
                h = ((g - b) / d + 6).truncatingRemainder(dividingBy: 6)
            } else if maxVal == g {
                h = (b - r) / d + 2
            } else {
                h = (r - g) / d + 4
            }
            h *= 60
        }

        let s = maxVal == 0 ? 0 : (d / maxVal) * 100
        let brightness = maxVal * 100

        return HSBColor(h: h, s: s, b: brightness)
    }

    public static func hsbToRgb(_ hsb: HSBColor) -> RGBColor {
        let h = hsb.h
        let s = hsb.s / 100.0
        let v = hsb.b / 100.0

        let c = v * s
        let x = c * (1 - abs(((h / 60).truncatingRemainder(dividingBy: 2)) - 1))
        let m = v - c

        let r1: Double, g1: Double, b1: Double
        if h < 60 { r1 = c; g1 = x; b1 = 0 }
        else if h < 120 { r1 = x; g1 = c; b1 = 0 }
        else if h < 180 { r1 = 0; g1 = c; b1 = x }
        else if h < 240 { r1 = 0; g1 = x; b1 = c }
        else if h < 300 { r1 = x; g1 = 0; b1 = c }
        else { r1 = c; g1 = 0; b1 = x }

        return RGBColor(
            r: Int(floor((r1 + m) * 255.0 + 0.5)),
            g: Int(floor((g1 + m) * 255.0 + 0.5)),
            b: Int(floor((b1 + m) * 255.0 + 0.5))
        )
    }

    // MARK: - sRGB <-> Linear

    static func srgbToLinear(_ c: Double) -> Double {
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    static func linearToSrgb(_ c: Double) -> Double {
        return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1.0 / 2.4) - 0.055
    }

    // MARK: - RGB <-> OKLab

    static func rgbToOklab(_ rgb: RGBColor) -> (L: Double, a: Double, b: Double) {
        let r = srgbToLinear(Double(rgb.r) / 255.0)
        let g = srgbToLinear(Double(rgb.g) / 255.0)
        let b = srgbToLinear(Double(rgb.b) / 255.0)

        let l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
        let m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
        let s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

        let l_ = cbrt(l)
        let m_ = cbrt(m)
        let s_ = cbrt(s)

        return (
            L: 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
            a: 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
            b: 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
        )
    }

    static func oklabToRgb(L: Double, a: Double, b: Double) -> RGBColor {
        let l_ = L + 0.3963377774 * a + 0.2158037573 * b
        let m_ = L - 0.1055613458 * a - 0.0638541728 * b
        let s_ = L - 0.0894841775 * a - 1.2914855480 * b

        let l = l_ * l_ * l_
        let m = m_ * m_ * m_
        let s = s_ * s_ * s_

        let r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

        return RGBColor(
            r: Int(floor(max(0, min(1, linearToSrgb(r))) * 255.0 + 0.5)),
            g: Int(floor(max(0, min(1, linearToSrgb(g))) * 255.0 + 0.5)),
            b: Int(floor(max(0, min(1, linearToSrgb(bl))) * 255.0 + 0.5))
        )
    }

    // MARK: - RGB <-> OKLCH

    public static func rgbToOklch(_ rgb: RGBColor) -> OKLCHColor {
        let lab = rgbToOklab(rgb)
        let c = sqrt(lab.a * lab.a + lab.b * lab.b)
        var h = atan2(lab.b, lab.a) * (180.0 / .pi)
        if h < 0 { h += 360 }
        return OKLCHColor(l: lab.L, c: c, h: c < 0.0001 ? 0 : h)
    }

    public static func oklchToRgb(_ oklch: OKLCHColor) -> RGBColor {
        let hRad = oklch.h * (.pi / 180.0)
        let a = oklch.c * cos(hRad)
        let b = oklch.c * sin(hRad)
        return oklabToRgb(L: oklch.l, a: a, b: b)
    }

    // MARK: - Gamut Clamping

    /// Clamp an OKLCH color into sRGB gamut by reducing chroma,
    /// preserving lightness and hue.
    static func gamutClampOklch(l: Double, c: Double, h: Double) -> OKLCHColor {
        // Quick check: if already in gamut, return as-is
        var rgb = oklchToRgb(OKLCHColor(l: l, c: c, h: h))
        if isInGamut(rgb) { return OKLCHColor(l: l, c: c, h: h) }

        // Binary search: reduce chroma until in gamut
        var lo: Double = 0
        var hi: Double = c
        for _ in 0..<20 {
            let mid = (lo + hi) / 2.0
            rgb = oklchToRgb(OKLCHColor(l: l, c: mid, h: h))
            if isInGamut(rgb) {
                lo = mid
            } else {
                hi = mid
            }
        }
        return OKLCHColor(l: l, c: lo, h: h)
    }

    static func isInGamut(_ rgb: RGBColor) -> Bool {
        return rgb.r >= 0 && rgb.r <= 255 &&
               rgb.g >= 0 && rgb.g <= 255 &&
               rgb.b >= 0 && rgb.b <= 255
    }

    // MARK: - Hex

    public static func rgbToHex(_ rgb: RGBColor) -> String {
        let r = max(0, min(255, rgb.r))
        let g = max(0, min(255, rgb.g))
        let b = max(0, min(255, rgb.b))
        return String(format: "#%02x%02x%02x", r, g, b)
    }

    public static func hexToRgb(_ hex: String) -> RGBColor? {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6,
              let value = UInt32(cleaned, radix: 16) else {
            return nil
        }
        return RGBColor(
            r: Int((value >> 16) & 0xFF),
            g: Int((value >> 8) & 0xFF),
            b: Int(value & 0xFF)
        )
    }

    // MARK: - Normalized Values <-> RGB

    /// Convert normalized 0-1 axis values to an RGB color based on current mode.
    static func valuesToRgb(_ values: Vec3, mode: ColorMode) -> RGBColor {
        switch mode {
        case .rgb:
            return RGBColor(
                r: Int(floor(values.x * 255.0 + 0.5)),
                g: Int(floor(values.y * 255.0 + 0.5)),
                b: Int(floor(values.z * 255.0 + 0.5))
            )
        case .hsb:
            return hsbToRgb(HSBColor(
                h: values.x * 359.0,
                s: values.y * 100.0,
                b: values.z * 100.0
            ))
        case .oklch:
            // x=L (0-1), y=C (0-OKLCH_C_MAX), z=H (0-359)
            let l = values.x
            let c = values.y * OKLCH_C_MAX
            let h = values.z * 359.0
            let clamped = gamutClampOklch(l: l, c: c, h: h)
            return oklchToRgb(clamped)
        }
    }

    /// Convert an RGB color to normalized 0-1 axis values for the given mode.
    static func rgbToValues(_ rgb: RGBColor, mode: ColorMode) -> Vec3 {
        switch mode {
        case .rgb:
            return Vec3(
                x: Double(rgb.r) / 255.0,
                y: Double(rgb.g) / 255.0,
                z: Double(rgb.b) / 255.0
            )
        case .hsb:
            let hsb = rgbToHsb(rgb)
            return Vec3(
                x: hsb.h / 359.0,
                y: hsb.s / 100.0,
                z: hsb.b / 100.0
            )
        case .oklch:
            let oklch = rgbToOklch(rgb)
            return Vec3(
                x: oklch.l,
                y: min(oklch.c / OKLCH_C_MAX, 1.0),
                z: oklch.h / 359.0
            )
        }
    }

    /// Get raw channel values from normalized values.
    static func valuesToChannels(_ values: Vec3, mode: ColorMode) -> [Double] {
        let maxVals = mode.axisMax
        return [
            floor(values.x * maxVals[0] + 0.5),
            floor(values.y * maxVals[1] + 0.5),
            floor(values.z * maxVals[2] + 0.5),
        ]
    }

    /// Compute the RGB color for a point on a cube face.
    static func faceColor(
        faceAxis: Int,
        u: Double,
        v: Double,
        fixedValue: Double,
        mode: ColorMode
    ) -> RGBColor {
        let values: Vec3
        switch faceAxis {
        case 0:
            values = Vec3(x: fixedValue, y: u, z: v)
        case 1:
            values = Vec3(x: u, y: fixedValue, z: v)
        default:
            values = Vec3(x: u, y: v, z: fixedValue)
        }
        return valuesToRgb(values, mode: mode)
    }
}
