import SwiftUI

/// Three labeled numeric text fields for the current mode's channels.
struct ChannelInputsView: View {
    @EnvironmentObject private var state: CubePickerState
    @State private var channelTexts: [String] = ["", "", ""]
    @FocusState private var focusedChannel: Int?

    init() {}

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                VStack(spacing: 2) {
                    Text(state.mode.axisLabels[i])
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("", text: $channelTexts[i])
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14, design: .monospaced))
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .focused($focusedChannel, equals: i)
                        .onSubmit {
                            applyChannel(i)
                        }
                }
            }
        }
        .onAppear {
            updateChannelTexts()
        }
        .onChange(of: state.dotValues) { _ in
            if focusedChannel == nil {
                updateChannelTexts()
            }
        }
        .onChange(of: state.mode) { _ in
            updateChannelTexts()
        }
    }

    private func updateChannelTexts() {
        let channels = ColorMath.valuesToChannels(state.dotValues, mode: state.mode)
        for i in 0..<3 {
            channelTexts[i] = String(Int(channels[i]))
        }
    }

    private func applyChannel(_ index: Int) {
        let maxVals = state.mode.axisMax
        guard let val = Double(channelTexts[index]) else {
            updateChannelTexts()
            return
        }
        let clamped = max(0, min(maxVals[index], val))
        let normalized = clamped / maxVals[index]

        var newValues = state.dotValues
        newValues[index] = normalized

        // Expand cube extent if needed
        if normalized > state.cubeExtent[index] {
            var newExtent = state.cubeExtent
            newExtent[index] = normalized
            state.cubeExtent = newExtent
        }

        state.dotValues = newValues
        updateChannelTexts()
    }
}
