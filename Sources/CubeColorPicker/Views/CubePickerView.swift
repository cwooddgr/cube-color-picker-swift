import SwiftUI

/// Configuration for the convenience CubePickerView wrapper.
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

/// A convenience wrapper that composes all picker sub-views with configurable visibility.
public struct CubePickerView: View {
    @EnvironmentObject private var state: CubePickerState

    private let config: CubePickerConfiguration

    public init(configuration: CubePickerConfiguration = CubePickerConfiguration()) {
        self.config = configuration
    }

    public var body: some View {
        VStack(spacing: 16) {
            CubeCanvasView()
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
    }
}
