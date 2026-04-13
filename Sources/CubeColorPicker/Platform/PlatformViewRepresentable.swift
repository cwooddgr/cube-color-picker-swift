import SwiftUI

#if canImport(UIKit)
import UIKit

typealias PlatformView = UIView
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformPanGestureRecognizer = UIPanGestureRecognizer

#elseif canImport(AppKit)
import AppKit

typealias PlatformView = NSView
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformPanGestureRecognizer = NSPanGestureRecognizer

#endif
