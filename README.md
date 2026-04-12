# CubeColorPicker (iOS)

A SwiftUI port of [cube-color-picker](https://github.com/cwooddgr/cube-color-picker) — a 3D isometric cube color picker for iOS. Drag axis handles to resize the cube, tap or drag on any face to pick a color.

Supports RGB, HSB, and OKLCH color modes. The color math, isometric projection, and interaction model match the web version.

<img src="screenshot.png" alt="CubeColorPicker running on iPhone" width="320">

> **Building for the web?** The TypeScript version lives at [cwooddgr/cube-color-picker](https://github.com/cwooddgr/cube-color-picker).

## Requirements

- iOS 16+
- Swift 5.9+
- Xcode 15+

## Install

Add the package to your Xcode project:

1. File → Add Package Dependencies…
2. Enter the repo URL: `https://github.com/cwooddgr/cube-color-picker-swift`
3. Add the `CubeColorPicker` library to your target

Or in a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cwooddgr/cube-color-picker-swift", branch: "main"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "CubeColorPicker", package: "cube-color-picker-swift"),
    ]),
]
```

## Usage — full picker

The simplest way: drop in `CubePickerView()` with a shared `CubePickerState`.

```swift
import SwiftUI
import CubeColorPicker

struct ContentView: View {
    @StateObject private var state = CubePickerState()

    var body: some View {
        CubePickerView()
            .environmentObject(state)
            .onChange(of: state.dotValues) { _ in
                print(state.currentColor.hex)
            }
    }
}
```

## Usage — compose your own controls

Every control is a standalone SwiftUI view that reads from a shared `CubePickerState` via `@EnvironmentObject`. Include only the ones you want.

```swift
struct ContentView: View {
    @StateObject private var state = CubePickerState()

    var body: some View {
        VStack(spacing: 16) {
            CubeCanvasView()                  // always required
            HStack {
                HexFieldView()
                CopyButton()
            }
        }
        .environmentObject(state)
    }
}
```

Available views:

| View | Purpose |
|------|---------|
| `CubeCanvasView` | The 3D cube viewport (required) |
| `ColorSwatchView` | Rounded square preview of the current color |
| `HexFieldView` | Editable hex color text field |
| `CopyButton` | Copies the current hex to the clipboard |
| `ModeToggleView` | Segmented RGB / HSB / OKLCH switcher |
| `ChannelInputsView` | Three labeled numeric fields (R/G/B, H/S/B, or L/C/H) |
| `CubePickerView` | Convenience wrapper that composes all of the above |

`CubePickerView` accepts a `CubePickerConfiguration` to toggle which subviews it renders:

```swift
CubePickerView(configuration: CubePickerConfiguration(
    showSwatch: true,
    showHexField: true,
    showCopyButton: true,
    showModeToggle: false,   // hide the mode toggle
    showChannelInputs: false, // hide the channel inputs
    size: 280
))
```

## `CubePickerState`

The shared state object your views bind to.

```swift
public final class CubePickerState: ObservableObject {
    @Published public var cubeExtent: Vec3
    @Published public var dotValues: Vec3
    @Published public var mode: ColorMode
    @Published public var axisConstrainEnabled: Bool  // shift-style axis lock
    @Published public var faceLockEnabled: Bool       // option-style face lock

    public var currentColor: ColorOutput { /* rgb, hsb, oklch, hex */ }

    public func setColor(_ rgb: RGBColor)
    public func setMode(_ mode: ColorMode, animated: Bool = true)
}
```

Construct with an initial color and/or mode:

```swift
@StateObject private var state = CubePickerState(
    initialColor: RGBColor(r: 180, g: 100, b: 220),
    mode: .oklch
)
```

## Color modes

- **RGB** — Red, Green, Blue. Every point in the cube is a valid sRGB color.
- **HSB** — Hue (0–359°), Saturation, Brightness. Every point is valid.
- **OKLCH** — Lightness, Chroma, Hue. Perceptually uniform. Out-of-gamut colors are automatically clamped by reducing chroma while preserving lightness and hue (binary search).

## Interaction

- **Axis handles** (colored circles on each axis): drag to resize the cube along that axis.
- **Face tap / drag**: tap on a face to place the color dot and select a color. Drag across faces seamlessly.
- **Axis-constrain mode** (`state.axisConstrainEnabled = true`): locks the dot to one axis during drag (equivalent to Shift in the web version). Wire a toggle button to this in your UI if you want the behavior.
- **Face-lock mode** (`state.faceLockEnabled = true`): clamps the dot to the current face instead of crossing to an adjacent one (equivalent to Option in the web version).

Touch targets for axis handles are 30pt radius (60pt diameter), exceeding Apple's 44pt minimum.

## Running the demo app

The demo is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
cd Demo
xcodegen generate
open CubePickerDemo.xcodeproj
```

Then pick an iOS Simulator and hit ⌘R.

## Running tests

```bash
swift test
```

46 tests cover color math (RGB↔HSB↔OKLCH, gamut clamping, hex parsing, mode conversions) and isometric projection (projection formula, cube vertices, face hit-testing, axis handle positioning).

## Architecture

```
Sources/CubeColorPicker/
├── Models/
│   ├── ColorTypes.swift       # RGBColor, HSBColor, OKLCHColor, Vec2, Vec3, FACES, etc.
│   └── ColorMath.swift        # All color conversion + gamut clamping
├── Renderer/
│   ├── IsometricProjection.swift  # project(), cubeVertices(), faceHitTest()
│   └── CubeRenderer.swift         # SwiftUI Canvas drawing + FaceTextureCache
├── Interaction/
│   └── CubeGestureHandler.swift   # Drag state machine, cross-face transitions
├── State/
│   └── CubePickerState.swift      # ObservableObject, mode switch animation
└── Views/                         # The composable SwiftUI views listed above
```

Face gradient textures are rendered as 128×128 `CGImage`s and drawn via affine-transformed clip regions on the SwiftUI `Canvas`, with a per-face cache that invalidates when `cubeExtent` or `mode` changes.

## License

MIT
