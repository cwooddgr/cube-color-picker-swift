import SwiftUI
import CubeColorPicker

@main
struct CubePickerDemoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        #if os(macOS)
        .defaultSize(width: 480, height: 760)
        #endif
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Picker", systemImage: "cube")
                }

            RegressionScene()
                .tabItem {
                    Label("Regression", systemImage: "ladybug")
                }
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
                .background(panelBackground)
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .background(rootBackground)
    }

    private var panelBackground: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }

    private var rootBackground: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.clear
        #endif
    }
}
