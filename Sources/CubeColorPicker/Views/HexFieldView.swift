import SwiftUI

/// A text field for entering hex color values.
public struct HexFieldView: View {
    @EnvironmentObject private var state: CubePickerState
    @State private var hexText: String = ""
    @FocusState private var isFocused: Bool

    public init() {}

    public var body: some View {
        TextField("Hex", text: $hexText)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 14, design: .monospaced))
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            #endif
            .focused($isFocused)
            .frame(minWidth: 90, maxWidth: 120)
            .onAppear {
                hexText = state.currentColor.hex
            }
            .onChange(of: state.dotValues) { _ in
                if !isFocused {
                    hexText = state.currentColor.hex
                }
            }
            .onChange(of: state.mode) { _ in
                if !isFocused {
                    hexText = state.currentColor.hex
                }
            }
            .onSubmit {
                if let rgb = ColorMath.hexToRgb(hexText) {
                    state.setColor(rgb)
                }
                hexText = state.currentColor.hex
            }
    }
}
