import SwiftUI
import CubeColorPicker

@main
struct CubePickerDemoApp: App {
    @StateObject private var pickerState = CubePickerState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pickerState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var state: CubePickerState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Cube Color Picker")
                    .font(.title2)
                    .fontWeight(.semibold)

                CubePickerView()

                // Show current color info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Color")
                        .font(.headline)
                    let color = state.currentColor
                    Text("RGB: \(color.rgb.r), \(color.rgb.g), \(color.rgb.b)")
                        .font(.system(.body, design: .monospaced))
                    Text("Hex: \(color.hex)")
                        .font(.system(.body, design: .monospaced))
                    Text("HSB: \(Int(color.hsb.h)), \(Int(color.hsb.s)), \(Int(color.hsb.b))")
                        .font(.system(.body, design: .monospaced))
                    Text("OKLCH: \(String(format: "%.3f", color.oklch.l)), \(String(format: "%.3f", color.oklch.c)), \(Int(color.oklch.h))")
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
