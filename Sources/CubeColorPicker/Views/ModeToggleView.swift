import SwiftUI

/// A segmented control for switching between RGB, HSB, and OKLCH modes.
public struct ModeToggleView: View {
    @EnvironmentObject private var state: CubePickerState

    public init() {}

    public var body: some View {
        Picker("Mode", selection: Binding(
            get: { state.mode },
            set: { newMode in
                state.setMode(newMode, animated: true)
            }
        )) {
            Text("RGB").tag(ColorMode.rgb)
            Text("HSB").tag(ColorMode.hsb)
            Text("OKLCH").tag(ColorMode.oklch)
        }
        .pickerStyle(.segmented)
    }
}
