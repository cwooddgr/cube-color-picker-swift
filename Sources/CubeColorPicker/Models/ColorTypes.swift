import Foundation

// MARK: - Color Structs

/// An RGB color with integer components 0-255.
public struct RGBColor: Equatable, Sendable {
    public var r: Int // 0-255
    public var g: Int // 0-255
    public var b: Int // 0-255

    public init(r: Int, g: Int, b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }
}

/// An HSB color with h: 0-359, s: 0-100, b: 0-100.
public struct HSBColor: Equatable, Sendable {
    public var h: Double // 0-359
    public var s: Double // 0-100
    public var b: Double // 0-100

    public init(h: Double, s: Double, b: Double) {
        self.h = h
        self.s = s
        self.b = b
    }
}

/// An OKLCH color with l: 0-1, c: 0-0.4, h: 0-359.
public struct OKLCHColor: Equatable, Sendable {
    public var l: Double // 0-1
    public var c: Double // 0-0.4
    public var h: Double // 0-359

    public init(l: Double, c: Double, h: Double) {
        self.l = l
        self.c = c
        self.h = h
    }
}

// MARK: - Color Mode

/// The active color space mode for the picker.
public enum ColorMode: String, CaseIterable, Sendable {
    case rgb
    case hsb
    case oklch

    /// Axis labels for each channel in this mode.
    public var axisLabels: [String] {
        switch self {
        case .rgb: return ["R", "G", "B"]
        case .hsb: return ["H", "S", "B"]
        case .oklch: return ["L", "C", "H"]
        }
    }

    /// Maximum raw value per channel for display purposes.
    public var axisMax: [Double] {
        switch self {
        case .rgb: return [255, 255, 255]
        case .hsb: return [359, 100, 100]
        case .oklch: return [100, 40, 359]
        }
    }
}

// MARK: - Vec2

/// A 2D point in screen space.
struct Vec2: Equatable, Sendable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: - Vec3

/// A 3D point with axis values (typically normalized 0-1).
struct Vec3: Equatable, Sendable {
    var x: Double
    var y: Double
    var z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Subscript by axis index: 0=x, 1=y, 2=z.
    subscript(axis: Int) -> Double {
        get {
            switch axis {
            case 0: return x
            case 1: return y
            default: return z
            }
        }
        set {
            switch axis {
            case 0: x = newValue
            case 1: y = newValue
            default: z = newValue
            }
        }
    }
}

// MARK: - Color Output

/// The full color output in all representations.
public struct ColorOutput: Equatable, Sendable {
    public var rgb: RGBColor
    public var hsb: HSBColor
    public var oklch: OKLCHColor
    public var hex: String

    public init(rgb: RGBColor, hsb: HSBColor, oklch: OKLCHColor, hex: String) {
        self.rgb = rgb
        self.hsb = hsb
        self.oklch = oklch
        self.hex = hex
    }
}

// MARK: - Face Definition

/// Defines one of the three visible faces of the isometric cube.
struct FaceDef: Sendable {
    /// Indices into the cube vertex array for this face's quad.
    let quad: [Int]
    /// The axis index (0/1/2) that is fixed for this face.
    let fixedAxis: Int
    /// The axis index for the U direction.
    let uAxis: Int
    /// The axis index for the V direction.
    let vAxis: Int

    init(quad: [Int], fixedAxis: Int, uAxis: Int, vAxis: Int) {
        self.quad = quad
        self.fixedAxis = fixedAxis
        self.uAxis = uAxis
        self.vAxis = vAxis
    }
}

/// The three visible faces: top (z fixed), right (x fixed), left (y fixed).
let FACES: [FaceDef] = [
    // Top face -- z fixed, varying x and y
    FaceDef(quad: [3, 5, 7, 6], fixedAxis: 2, uAxis: 0, vAxis: 1),
    // Right face -- x fixed, varying y and z
    FaceDef(quad: [1, 4, 7, 5], fixedAxis: 0, uAxis: 1, vAxis: 2),
    // Left face -- y fixed, varying x and z
    FaceDef(quad: [2, 4, 7, 6], fixedAxis: 1, uAxis: 0, vAxis: 2),
]

// MARK: - Render State

/// Tracks which elements are hovered or being dragged during interaction.
struct RenderState: Equatable, Sendable {
    var hoveredAxisHandle: Int
    var draggingAxisHandle: Int
    var hoveredFace: Int
    var draggingFace: Int

    init(
        hoveredAxisHandle: Int = -1,
        draggingAxisHandle: Int = -1,
        hoveredFace: Int = -1,
        draggingFace: Int = -1
    ) {
        self.hoveredAxisHandle = hoveredAxisHandle
        self.draggingAxisHandle = draggingAxisHandle
        self.hoveredFace = hoveredFace
        self.draggingFace = draggingFace
    }

    static let `default` = RenderState()
}
