import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A button that copies the current hex color to the clipboard.
public struct CopyButton: View {
    @EnvironmentObject private var state: CubePickerState
    @State private var copied: Bool = false

    public init() {}

    public var body: some View {
        Button(action: copyHex) {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 13))
                .frame(minWidth: 44)
        }
        .buttonStyle(.bordered)
    }

    private func copyHex() {
        let hex = state.currentColor.hex
        #if canImport(UIKit)
        UIPasteboard.general.string = hex
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hex, forType: .string)
        #endif
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            copied = false
        }
    }
}
