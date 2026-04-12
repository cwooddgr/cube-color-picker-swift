// CubeColorPicker - Public re-exports
//
// This file provides a convenient namespace and re-exports all public types.
// Users can import CubeColorPicker to access everything.

import SwiftUI

// All public types are already accessible via the module.
// This file exists as the module's entry point and documents the public API.

// MARK: - Public Types (from Models/ColorTypes.swift)
// - RGBColor
// - HSBColor
// - OKLCHColor
// - ColorMode
// - Vec2
// - Vec3
// - ColorOutput
// - FaceDef
// - FACES
// - RenderState

// MARK: - Color Math (from Models/ColorMath.swift)
// - ColorMath.rgbToHsb(_:)
// - ColorMath.hsbToRgb(_:)
// - ColorMath.rgbToOklch(_:)
// - ColorMath.oklchToRgb(_:)
// - ColorMath.rgbToHex(_:)
// - ColorMath.hexToRgb(_:)
// - ColorMath.valuesToRgb(_:mode:)
// - ColorMath.rgbToValues(_:mode:)
// - ColorMath.valuesToChannels(_:mode:)
// - ColorMath.faceColor(faceAxis:u:v:fixedValue:mode:)

// MARK: - State (from State/CubePickerState.swift)
// - CubePickerState

// MARK: - Views (from Views/)
// - CubePickerView (convenience wrapper)
// - CubeCanvasView (3D cube viewport)
// - ColorSwatchView
// - HexFieldView
// - CopyButton
// - ModeToggleView
// - ChannelInputsView
// - CubePickerConfiguration
