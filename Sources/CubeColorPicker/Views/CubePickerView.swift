import SwiftUI

/// Visibility toggles and sizing for the sub-controls inside `CubePickerView`.
public struct CubePickerConfiguration {
    public var showSwatch: Bool
    public var showHexField: Bool
    public var showCopyButton: Bool
    public var showModeToggle: Bool
    public var showChannelInputs: Bool
    public var size: CGFloat

    public init(
        showSwatch: Bool = true,
        showHexField: Bool = true,
        showCopyButton: Bool = true,
        showModeToggle: Bool = true,
        showChannelInputs: Bool = true,
        size: CGFloat = 300
    ) {
        self.showSwatch = showSwatch
        self.showHexField = showHexField
        self.showCopyButton = showCopyButton
        self.showModeToggle = showModeToggle
        self.showChannelInputs = showChannelInputs
        self.size = size
    }
}

/// A self-contained 3D cube color picker with SwiftUI binding API.
///
/// ```swift
/// @State private var color = RGBColor(r: 128, g: 128, b: 128)
/// CubePickerView(color: $color)
/// ```
public struct CubePickerView: View {
    @StateObject private var state: CubePickerState

    @Binding private var color: RGBColor
    private let modeBinding: Binding<ColorMode>?
    private let config: CubePickerConfiguration

    /// Create a picker bound to an `RGBColor` value.
    ///
    /// - Parameters:
    ///   - color: A binding to the selected color. The picker will read the initial
    ///     value to seed its state, and write back on every interaction.
    ///   - mode: An optional binding to the active `ColorMode`. When `nil`, the view
    ///     owns mode internally (defaulting to `.rgb`).
    ///   - configuration: Visibility toggles and sizing for sub-controls.
    public init(
        color: Binding<RGBColor>,
        mode: Binding<ColorMode>? = nil,
        configuration: CubePickerConfiguration = CubePickerConfiguration()
    ) {
        self._color = color
        self.modeBinding = mode
        self.config = configuration
        _state = StateObject(wrappedValue: CubePickerState(
            initialColor: color.wrappedValue,
            mode: mode?.wrappedValue ?? .rgb
        ))
    }

    public var body: some View {
        VStack(spacing: 16) {
            CubeSceneRepresentable()
                .frame(width: config.size, height: config.size)

            if config.showSwatch || config.showHexField || config.showCopyButton {
                HStack(spacing: 12) {
                    if config.showSwatch {
                        ColorSwatchView()
                    }
                    if config.showHexField {
                        HexFieldView()
                    }
                    if config.showCopyButton {
                        CopyButton()
                    }
                }
            }

            if config.showModeToggle {
                ModeToggleView()
                    .frame(maxWidth: config.size)
            }

            if config.showChannelInputs {
                ChannelInputsView()
            }
        }
        .padding()
        .environmentObject(state)
        // state -> bindings: when the cube moves, publish to host bindings.
        .onChange(of: state.dotValues) { _ in
            syncStateToColorBinding()
        }
        .onChange(of: state.mode) { newMode in
            if let modeBinding, modeBinding.wrappedValue != newMode {
                modeBinding.wrappedValue = newMode
            }
        }
        // bindings -> state: when the host writes, push into state.
        .onChange(of: color) { newColor in
            if state.currentColor.rgb != newColor {
                state.setColor(newColor)
            }
        }
        .onChange(of: modeBinding?.wrappedValue) { newMode in
            if let newMode, state.mode != newMode {
                state.setMode(newMode, animated: true)
            }
        }
    }

    /// Publish the state's current RGB back to the `color` binding, if different.
    private func syncStateToColorBinding() {
        let derived = state.currentColor.rgb
        if color != derived {
            color = derived
        }
    }
}
