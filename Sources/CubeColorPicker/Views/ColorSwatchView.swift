import SwiftUI

/// A rounded rectangle swatch showing the current color.
public struct ColorSwatchView: View {
    @EnvironmentObject private var state: CubePickerState

    public init() {}

    public var body: some View {
        let rgb = state.currentColor.rgb
        let color = Color(
            red: Double(rgb.r) / 255.0,
            green: Double(rgb.g) / 255.0,
            blue: Double(rgb.b) / 255.0
        )

        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 40, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}
