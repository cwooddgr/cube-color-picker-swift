import SwiftUI
import CubeColorPicker

/// Reproduces the host hierarchy that broke face rendering in 0.2.0:
/// `NavigationStack > .sheet > NavigationStack > ScrollView > Form > CubePickerView`.
/// On 0.3.0 the cube faces should render correctly here.
struct RegressionScene: View {
    @State private var color = RGBColor(r: 180, g: 100, b: 220)
    @State private var mode: ColorMode = .rgb
    @State private var showSheet = false
    @State private var showSecondSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("Reproduce reported bug") {
                    NavigationLink("Open regression case") {
                        regressionLanding
                    }
                }

                Section("Debug") {
                    Toggle("Solid faces", isOn: solidFacesBinding)
                }
            }
            .navigationTitle("Regression")
        }
    }

    private var regressionLanding: some View {
        VStack(spacing: 24) {
            Text("Tap to present the picker inside a sheet + nav stack + scroll view + form. This is the configuration that broke gradient rendering in 0.2.0.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding()

            Button("Show Sheet") { showSheet = true }
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Regression case")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                ScrollView {
                    Form {
                        Section("Cube") {
                            CubePickerView(color: $color, mode: $mode)
                        }
                        Section("Hex") {
                            Text(ColorMath.rgbToHex(color))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .frame(minHeight: 700)
                }
                .navigationTitle("Pick color")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showSheet = false }
                    }
                }
            }
        }
    }

    /// Two-way binding to the static debug flag, so SwiftUI can re-render the
    /// presented picker when toggled.
    private var solidFacesBinding: Binding<Bool> {
        Binding(
            get: { CubeColorPickerDebug.solidFaces },
            set: { CubeColorPickerDebug.solidFaces = $0 }
        )
    }
}
