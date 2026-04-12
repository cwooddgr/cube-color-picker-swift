import SwiftUI
import CubeColorPicker

@main
struct CubePickerDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var color = RGBColor(r: 180, g: 100, b: 220)
    @State private var mode: ColorMode = .rgb

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Cube Color Picker")
                    .font(.title2)
                    .fontWeight(.semibold)

                CubePickerView(color: $color, mode: $mode)

                // Show current color info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Color")
                        .font(.headline)
                    let hsb = ColorMath.rgbToHsb(color)
                    let oklch = ColorMath.rgbToOklch(color)
                    let hex = ColorMath.rgbToHex(color)
                    Text("RGB: \(color.r), \(color.g), \(color.b)")
                        .font(.system(.body, design: .monospaced))
                    Text("Hex: \(hex)")
                        .font(.system(.body, design: .monospaced))
                    Text("HSB: \(Int(hsb.h)), \(Int(hsb.s)), \(Int(hsb.b))")
                        .font(.system(.body, design: .monospaced))
                    Text("OKLCH: \(String(format: "%.3f", oklch.l)), \(String(format: "%.3f", oklch.c)), \(Int(oklch.h))")
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .background(Color(.systemBackground))
    }
}
